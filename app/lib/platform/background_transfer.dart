// Android 백그라운드 전송 (03장 §5.10): background_downloader (WorkManager, Android 14+ UIDT).
// 앱이 백그라운드로 가거나 OS가 앱을 내려도 전송이 이어진다. 검증·이동·DB는 엔진이 한다.
// - TransferHint.userInitiated: UIDT + 일시중지/이어받기 허용(9분 실행 한도를 넘어 이어받음). UIDT는 알림이 필요하다.
// - 패키지는 받는 동안 자기 임시 파일에 쓰고, 끝나면 우리 tmp/<id>.part 로 옮긴다. 이어받기 정보(임시 파일·ETag)는 패키지가 보관한다.
// - 확인함(9.6.3): Android 쪽은 URL(미디어 티켓 포함)을 로그에 쓰지 않는다. 작업 기록(앱 전용 저장소)에는 남는다(티켓 수명 12시간).
import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import 'transfer_port.dart';

class BackgroundTransfer implements TransferPort {
  BackgroundTransfer._();

  static const _group = 'bangmusic.downloads';
  static BackgroundTransfer? _instance;

  final _updates = StreamController<TransferUpdate>.broadcast();
  final _sizes = <String, int>{};

  /// 엔진이 멈추라고 한 작업. 이 밖의 취소는 OS가 작업을 멈춘 것이다
  final _cancelling = <String>{};
  bool _askedPermission = false;

  /// 앱 시작 시 한 번. 백그라운드에서 끝난 작업의 소식도 이때 받는다.
  static Future<BackgroundTransfer> create() async {
    final t = _instance ??= BackgroundTransfer._();
    FileDownloader().configureNotification(
      running: const TaskNotification('음악 받는 중', '{displayName}'),
      error: const TaskNotification('받기 실패', '{displayName}'),
      paused: const TaskNotification('받기 일시중지', '{displayName}'),
      progressBar: true,
      groupNotificationId: _group, // 묶음 알림 1개 (03장 §5.10)
    );
    FileDownloader().updates.listen(t._onUpdate);
    await FileDownloader().start(doRescheduleKilledTasks: true);
    return t;
  }

  @override
  Stream<TransferUpdate> get updates => _updates.stream;

  @override
  Future<Set<String>> running() async {
    final tasks = await FileDownloader().allTasks(group: _group);
    return {for (final t in tasks) t.taskId};
  }

  @override
  Future<void> cancel(String downloadId) async {
    _cancelling.add(downloadId);
    await FileDownloader().cancelTaskWithId(downloadId);
  }

  @override
  Future<void> start({required String downloadId, required Uri url, required File part, required int fromByte, String? etag, required bool wifiOnly, String? title}) async {
    if (!_askedPermission) {
      // Android 13+ 알림 권한: 첫 다운로드 때 묻고, 거부해도 다운로드는 동작한다 (03장 §5.10)
      _askedPermission = true;
      try {
        if (await FileDownloader().permissions.status(PermissionType.notifications) != PermissionStatus.granted) {
          await FileDownloader().permissions.request(PermissionType.notifications);
        }
      } catch (_) {}
    }
    _cancelling.remove(downloadId);
    final (base, dir, name) = await Task.split(file: part);
    final task = DownloadTask(
      taskId: downloadId,
      url: url.toString(),
      filename: name,
      directory: dir,
      baseDirectory: base,
      group: _group,
      updates: Updates.statusAndProgress,
      requiresWiFi: wifiOnly,
      retries: 3, // 앱이 내려가 있는 동안의 짧은 끊김은 패키지가 이어받는다. 그 뒤는 엔진의 백오프
      transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
      displayName: title ?? '',
    );
    // 이어받기 정보가 있으면 새 URL(새 티켓)로 같은 위치부터 (03장 §5.4)
    if (fromByte > 0 && await FileDownloader().taskCanResume(task) && await FileDownloader().resume(task)) return;
    if (fromByte > 0) _updates.add(TransferRestarted(downloadId)); // 이어받을 수 없음: 처음부터
    if (!await FileDownloader().enqueue(task)) _updates.add(TransferFailed(downloadId, 'network'));
  }

  void _onUpdate(TaskUpdate u) {
    if (u.task.group != _group) return;
    final id = u.task.taskId;
    switch (u) {
      case TaskProgressUpdate(:final progress, :final expectedFileSize):
        if (progress < 0) return; // 상태를 뜻하는 음수 값
        if (expectedFileSize > 0) _sizes[id] = expectedFileSize;
        final size = _sizes[id];
        if (size != null) _updates.add(TransferProgress(id, (progress * size).round()));
      case TaskStatusUpdate(:final status, :final responseStatusCode, :final exception):
        switch (status) {
          case TaskStatus.complete:
            _sizes.remove(id);
            _updates.add(TransferComplete(id));
          case TaskStatus.notFound:
            _updates.add(TransferFailed(id, 'not_found'));
          case TaskStatus.failed:
            final code = exception is TaskHttpException ? exception.httpResponseCode : responseStatusCode;
            final fs = exception is TaskFileSystemException;
            _updates.add(TransferFailed(id, fs ? 'disk_full' : failureCode(code != null && code > 0 ? code : null)));
          case TaskStatus.canceled:
            // 엔진이 시키지 않은 취소(OS가 작업을 멈춤)는 엔진의 재시도에 맡긴다. 무시하면 "받는 중"에 멈춘다
            if (!_cancelling.remove(id)) _updates.add(TransferFailed(id, 'network'));
          case TaskStatus.enqueued:
          case TaskStatus.running:
          case TaskStatus.waitingToRetry:
          case TaskStatus.paused:
            break; // 진행 중
        }
    }
  }
}
