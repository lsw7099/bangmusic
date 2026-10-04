// 바이트 전송 경계 (03장 §5.10: "검증·이동·DB 기록은 패키지가 아니라 앱의 상태 기계가 한다 — 패키지 교체 가능성 유지").
// 전송 구현은 받은 바이트를 tmp/<download_id>.part 로 완성해 두는 것까지만 한다.
// - BackgroundTransfer: background_downloader (Android WorkManager/UIDT). 기기용.
// - HttpTransfer: dart:io HttpClient, .part에 Range로 이어 쓴다. 호스트 테스트(FN-03 L1)와 대체용.
import 'dart:async';
import 'dart:io';

sealed class TransferUpdate {
  const TransferUpdate(this.downloadId);
  final String downloadId;
}

class TransferProgress extends TransferUpdate {
  const TransferProgress(super.downloadId, this.bytesDone);
  final int bytesDone;
}

/// .part가 완성됐다
class TransferComplete extends TransferUpdate {
  const TransferComplete(super.downloadId);
}

/// 서버가 Range를 무시하고 전체를 보냈다(이미 처음부터 다시 쓰는 중)
class TransferRestarted extends TransferUpdate {
  const TransferRestarted(super.downloadId);
}

/// 실패. code: offline / network / disk_full / ticket_expired / rendition_superseded / `http_<status>`
class TransferFailed extends TransferUpdate {
  const TransferFailed(super.downloadId, this.code, {this.retryAfter});
  final String code;
  final Duration? retryAfter;
}

abstract interface class TransferPort {
  Stream<TransferUpdate> get updates;

  /// part 파일을 이어 완성한다. fromByte는 상태 기계가 아는 위치(참고값)이고, 구현은 실제로 받아 둔 양
  /// (.part 크기 또는 패키지의 이어받기 정보)에서 이어간다. etag는 If-Range에 쓴다.
  Future<void> start({required String downloadId, required Uri url, required File part, required int fromByte, String? etag, required bool wifiOnly, String? title});

  Future<void> cancel(String downloadId);

  /// 지금 전송 중인 다운로드 ID (재시작 대조 §5.9)
  Future<Set<String>> running();
}

/// HTTP 상태 → 실패 코드 (02장 오류 코드)
String failureCode(int? status, {String? problemCode}) {
  if (problemCode != null && problemCode.isNotEmpty) return problemCode;
  return switch (status) {
    null => 'network',
    401 => 'ticket_expired',
    410 => 'rendition_superseded',
    404 => 'not_found',
    403 => 'forbidden',
    429 => 'transcode_queue_full',
    _ => status >= 500 ? 'server_error' : 'http_$status',
  };
}

/// dart:io 구현. 앱 프로세스 안에서만 돈다(앱이 죽으면 다음 실행의 대조가 .part 크기에서 이어받는다).
class HttpTransfer implements TransferPort {
  HttpTransfer({HttpClient? client, this.idleTimeout = const Duration(seconds: 30)}) : _client = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 10));

  final HttpClient _client;

  /// 이 시간 동안 바이트가 하나도 오지 않으면 끊고 network 실패로 본다.
  /// (연결이 조용히 죽으면 끝없이 기다리던 결함 — 테스트에서 발견)
  final Duration idleTimeout;
  final _updates = StreamController<TransferUpdate>.broadcast();
  final _jobs = <String, _Job>{};

  @override
  Stream<TransferUpdate> get updates => _updates.stream;

  @override
  Future<Set<String>> running() async => _jobs.keys.toSet();

  @override
  Future<void> cancel(String downloadId) async {
    _jobs.remove(downloadId)?.cancel();
  }

  @override
  Future<void> start({required String downloadId, required Uri url, required File part, required int fromByte, String? etag, required bool wifiOnly, String? title}) async {
    await cancel(downloadId);
    final job = _Job();
    _jobs[downloadId] = job;
    unawaited(_run(downloadId, url, part, fromByte, etag, job).whenComplete(() {
      if (_jobs[downloadId] == job) _jobs.remove(downloadId);
    }));
  }

  Future<void> _run(String id, Uri url, File part, int from, String? etag, _Job job) async {
    IOSink? sink;
    var done = 0;
    TransferUpdate? result;
    try {
      await part.parent.create(recursive: true);
      // .part 실제 크기에서 이어받는다. DB의 bytes_done은 진행률을 띄엄띄엄 저장해 뒤처지거나 앞설 수 있다.
      // 처음부터 다시 받아야 할 때는 상태 기계가 먼저 .part를 지운다(DeletePart → StartTransfer(0)).
      final offset = await part.exists() ? await part.length() : 0;
      final req = await _client.getUrl(url);
      job.request = req;
      if (offset > 0) {
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
        if (etag != null) req.headers.set(HttpHeaders.ifRangeHeader, etag);
      }
      final res = await req.close().timeout(idleTimeout);
      if (job.cancelled) return;
      if (res.statusCode != 200 && res.statusCode != 206) {
        await res.drain<void>();
        final ra = int.tryParse(res.headers.value(HttpHeaders.retryAfterHeader) ?? '');
        result = TransferFailed(id, failureCode(res.statusCode), retryAfter: ra == null ? null : Duration(seconds: ra));
        return;
      }
      done = offset;
      if (res.statusCode == 200) {
        if (offset > 0) _emit(job, TransferRestarted(id)); // §5.4: 부분 파일을 버리고 처음부터
        done = 0;
        sink = part.openWrite(mode: FileMode.write);
      } else {
        // 206: 이어 쓰기 전에 .part를 정확히 offset까지 자른다
        final raf = await part.open(mode: FileMode.append);
        await raf.truncate(offset);
        await raf.close();
        sink = part.openWrite(mode: FileMode.append);
      }
      var lastEmit = DateTime.now();
      await for (final chunk in res.timeout(idleTimeout)) {
        if (job.cancelled) break;
        sink.add(chunk);
        done += chunk.length;
        if (DateTime.now().difference(lastEmit) > const Duration(milliseconds: 300)) {
          lastEmit = DateTime.now();
          _emit(job, TransferProgress(id, done));
        }
      }
      if (!job.cancelled) result = TransferComplete(id);
    } on FileSystemException catch (e) {
      // ENOSPC(28)·디스크 가득(112) — 공간 부족은 .part를 남기고 기다린다 (§5.7)
      result = TransferFailed(id, e.osError?.errorCode == 28 || e.osError?.errorCode == 112 ? 'disk_full' : 'io_error');
    } catch (_) {
      result = TransferFailed(id, 'network');
    } finally {
      // 결과를 알리기 전에 파일을 닫는다 — 재시도가 아직 쓰는 중인 .part를 자르거나 이어 쓰지 않게
      try {
        await sink?.close();
      } catch (_) {}
      if (result != null) {
        // 실제로 디스크에 남은 양 (재시도 때 이어받는 위치)
        _emit(job, TransferProgress(id, await part.exists() ? await part.length() : 0));
        _emit(job, result);
      }
    }
  }

  void _emit(_Job job, TransferUpdate u) {
    if (!job.cancelled) _updates.add(u);
  }
}

class _Job {
  bool cancelled = false;
  HttpClientRequest? request;
  void cancel() {
    cancelled = true;
    request?.abort();
  }
}
