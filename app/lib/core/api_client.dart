// API 클라이언트 (02장 §1.2, §2.2, §6). 생성된 bangmusic_api를 쓰고, 그 위에 인증·갱신만 얹는다.
// - 401 access_expired/access_invalid → 리프레시는 한 번만(단일 비행) → 원 요청 1회 재시도
// - 리프레시 401 refresh_expired → 세션 만료, session_revoked/account_disabled → 접근 취소
// - 네트워크 오류·5xx는 세션 상태를 바꾸지 않는다(오프라인으로 취급)
import 'dart:async';
import 'dart:io';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_info.dart';
import 'session.dart';

/// 서버가 돌려준 problem+json 또는 연결 문제
class ApiException implements Exception {
  ApiException({required this.kind, this.status, this.code, this.requestId, this.retryAfter});
  final ApiErrorKind kind;
  final int? status;
  final String? code;
  final String? requestId;
  final int? retryAfter;

  static ApiException from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      if (e.error is ApiException) return e.error! as ApiException;
      final r = e.response;
      if (r != null) {
        final data = r.data;
        final code = data is Map ? data['code'] as String? : null;
        final rid = data is Map ? data['request_id'] as String? : r.headers.value('x-request-id');
        return ApiException(kind: ApiErrorKind.server, status: r.statusCode, code: code, requestId: rid, retryAfter: int.tryParse(r.headers.value('retry-after') ?? ''));
      }
      if (_localNetworkDenied(e.error)) return ApiException(kind: ApiErrorKind.localNetworkDenied);
      if (e.type == DioExceptionType.badCertificate || e.error is HandshakeException || e.error is TlsException) {
        return ApiException(kind: ApiErrorKind.certificate);
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
        return ApiException(kind: ApiErrorKind.timeout);
      }
      return ApiException(kind: ApiErrorKind.unreachable);
    }
    return ApiException(kind: ApiErrorKind.unknown);
  }

  @override
  String toString() => 'ApiException($kind, $status, $code, $requestId)';
}

enum ApiErrorKind { server, unreachable, timeout, certificate, notBangmusic, serverMismatch, localNetworkDenied, unknown }

/// OS가 로컬 네트워크 접근을 막았다 (Android 17 타깃의 로컬 네트워크 권한, 01장 §2.6). 소켓이 EPERM(1)으로 거부된다.
/// [확인 필요] SM-S948N(Android 16)에서는 호환성 플래그 RESTRICT_LOCAL_NETWORK를 켜도 차단되지 않아 실제 오류 모양을 보지 못했다.
bool _localNetworkDenied(Object? e) {
  final os = e is SocketException ? e.osError : null;
  return os != null && (os.errorCode == 1 || os.message.contains('Operation not permitted'));
}

/// 서버 확인 결과 (04장 S1 ②)
sealed class ProbeResult {
  const ProbeResult();
}

class ProbeOk extends ProbeResult {
  const ProbeOk(this.info, this.baseUrl);
  final ServerInfo info;
  final String baseUrl;
}

class ProbeIncompatible extends ProbeResult {
  const ProbeIncompatible(this.reason, this.info);
  final Incompatibility reason;
  final ServerInfo info;
}

enum Incompatibility { unsupportedMajor, serverTooOld, appTooOld }

class ProbeFailed extends ProbeResult {
  const ProbeFailed(this.error);
  final ApiException error;
}

Dio _baseDio(String baseUrl) => Dio(BaseOptions(
      baseUrl: '$baseUrl/v1',
      connectTimeout: const Duration(seconds: 10), // 02장 §7
      receiveTimeout: const Duration(seconds: 20),
      headers: {'BangMusic-Client': AppInfo.clientHeader},
    ));

/// 서버 주소 확인: BangMusic 서버인지, 버전이 맞는지 (02장 §2.2)
Future<ProbeResult> probeServer(String baseUrl) async {
  final api = BangmusicApi(dio: _baseDio(baseUrl), interceptors: const []);
  try {
    final res = await api.getServerApi().getServerInfo();
    final info = res.data;
    if (info == null || info.product != ServerInfoProductEnum.bangmusicServer) return ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic));
    if (info.api.major != 1) return ProbeIncompatible(Incompatibility.unsupportedMajor, info);
    if (info.api.minor < AppInfo.apiMinorRequired) return ProbeIncompatible(Incompatibility.serverTooOld, info);
    if (info.minClientApiMinor > AppInfo.apiMinorBuilt) return ProbeIncompatible(Incompatibility.appTooOld, info);
    return ProbeOk(info, baseUrl);
  } on DioException catch (e) {
    // JSON이 아니거나 형식이 다른 응답 = BangMusic 서버가 아님
    if (e.type == DioExceptionType.unknown && e.error is FormatException) return ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic));
    if (e.response != null && e.response!.statusCode == 404) return ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic));
    return ProbeFailed(ApiException.from(e));
  } catch (_) {
    return ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic));
  }
}

/// 로그인 (비멱등 POST: 자동 재시도하지 않는다)
Future<(TokenResponse, ServerInfo)> loginToServer(ProbeOk server, String username, String password, String installationId, String deviceName) async {
  final api = BangmusicApi(dio: _baseDio(server.baseUrl), interceptors: const []);
  try {
    final res = await api.getAuthApi().login(
          loginRequest: LoginRequest(
            username: username,
            password: password,
            device: DeviceInfo(name: deviceName, platform: DeviceInfoPlatformEnum.android, appVersion: AppInfo.appVersion, installationId: installationId),
          ),
        );
    return (res.data!, server.info);
  } catch (e) {
    throw ApiException.from(e);
  }
}

class ApiClient {
  // 이름 있는 매개변수는 _로 시작할 수 없어 초기화 형식을 쓸 수 없다
  // ignore: prefer_initializing_formals
  ApiClient({required this.profile, required TokenVault vault, required Tokens tokens, Dio? dio}) : _vault = vault, _tokens = tokens {
    _dio = dio ?? _baseDio(profile.baseUrl);
    _dio.interceptors.add(QueuedInterceptorsWrapper(onRequest: _onRequest, onResponse: _onResponse, onError: _onError));
    api = BangmusicApi(dio: _dio, interceptors: const []);
  }

  final ServerProfile profile;
  final TokenVault _vault;
  Tokens _tokens;
  late final Dio _dio;
  late final BangmusicApi api;
  Future<Tokens>? _refreshing;

  /// 세션 상태 (배너·전체 화면 안내에 쓴다)
  final status = ValueNotifier<SessionStatus>(SessionStatus.active);

  /// 서버에 닿는가. 응답을 하나라도 받으면 true, 연결 자체가 실패하면 false (오프라인 화면 전환, 03장 §5.6)
  final reachable = ValueNotifier<bool>(true);

  /// 서버가 알린 상태 (04장 §5 공통 상태 배너): 'maintenance'(503 점검) / 'client_too_old'(426 앱 업데이트 필요) / null
  final serverNotice = ValueNotifier<String?>(null);

  /// 이 주소의 서버가 로그인했던 서버(server_id)와 다르다 — 토큰을 보내지 않는다 (03장 §5.2, FN-21)
  final serverChanged = ValueNotifier<bool>(false);
  bool _identityOk = false;
  Future<void>? _checkingIdentity;

  /// 토큰을 붙이기 전에 서버 신원 확인 (첫 요청, 그리고 연결이 끊겼다 돌아온 뒤). 인증 없이 GET /server.
  Future<void> ensureServerIdentity() async {
    if (_identityOk) return;
    await (_checkingIdentity ??= _checkIdentity().whenComplete(() => _checkingIdentity = null));
  }

  Future<void> _checkIdentity() async {
    // 토큰을 붙이지 않는 별도 Dio (같은 전송 어댑터 — 테스트의 가짜 서버도 그대로 쓴다)
    final plain = Dio(BaseOptions(
      baseUrl: _dio.options.baseUrl, connectTimeout: _dio.options.connectTimeout, receiveTimeout: _dio.options.receiveTimeout,
      headers: {'BangMusic-Client': AppInfo.clientHeader},
    ))..httpClientAdapter = _dio.httpClientAdapter;
    final Response<Map<String, dynamic>> r;
    try {
      r = await plain.get<Map<String, dynamic>>('/server');
    } catch (e) {
      final ae = ApiException.from(e);
      if (ae.status == null) reachable.value = false;
      throw ae.status == null ? ae : ApiException(kind: ApiErrorKind.notBangmusic, status: ae.status);
    }
    reachable.value = true;
    if (r.data?['server_id'] != profile.serverId) {
      serverChanged.value = true;
      throw ApiException(kind: ApiErrorKind.serverMismatch);
    }
    serverChanged.value = false;
    _identityOk = true;
  }

  void _onResponse(Response<dynamic> r, ResponseInterceptorHandler h) {
    reachable.value = true;
    if (serverNotice.value == 'maintenance') serverNotice.value = null; // 점검이 끝났다
    h.next(r);
  }

  Dio get dio => _dio;
  String get baseUrl => profile.baseUrl;
  String get accessToken => _tokens.access;

  Future<void> _onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    // 신원을 확인하기 전에는 토큰을 붙인 요청을 내보내지 않는다 (03장 §5.2)
    try {
      await ensureServerIdentity();
    } on ApiException catch (e) {
      h.reject(DioException(requestOptions: o, error: e, type: DioExceptionType.unknown));
      return;
    }
    if (!o.headers.containsKey('Authorization')) o.headers['Authorization'] = 'Bearer ${_tokens.access}';
    o.extra['bm_sent_access'] = _tokens.access; // 어느 토큰으로 보냈는지 (갱신 중복 방지)
    h.next(o);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final r = e.response;
    final code = r?.data is Map ? (r!.data as Map)['code'] : null;
    if (r != null) {
      reachable.value = true;
      if (r.statusCode == 503 && code == 'maintenance') serverNotice.value = 'maintenance';
      if (r.statusCode == 426) serverNotice.value = 'client_too_old';
    } else if (e.type != DioExceptionType.cancel && e.error is! ApiException) {
      reachable.value = false;
      _identityOk = false; // 연결이 돌아오면 그 주소의 서버가 같은지 다시 확인한다
    }
    final retried = e.requestOptions.extra['bm_retried'] == true;
    if (r?.statusCode == 401 && (code == 'access_expired' || code == 'access_invalid') && !retried) {
      try {
        // 이 요청을 보낸 뒤 이미 다른 요청이 갱신했다면 다시 갱신하지 않고 새 토큰으로 재시도한다.
        // (대기 중이던 401들이 차례로 처리될 때 갱신이 여러 번 일어나는 것을 막는다 — 02장 §1.2 단일 비행)
        final sent = e.requestOptions.extra['bm_sent_access'];
        final t = sent != null && sent != _tokens.access ? _tokens : await refresh();
        final o = e.requestOptions..extra['bm_retried'] = true;
        o.headers['Authorization'] = 'Bearer ${t.access}';
        h.resolve(await _dio.fetch<dynamic>(o));
        return;
      } on ApiException catch (ae) {
        h.reject(DioException(requestOptions: e.requestOptions, error: ae, response: r));
        return;
      }
    }
    if (r?.statusCode == 401 && (code == 'session_revoked' || code == 'account_disabled')) status.value = SessionStatus.revoked;
    h.next(e);
  }

  /// 단일 비행: 동시에 여러 요청이 401을 받아도 갱신은 한 번 (02장 §1.2)
  Future<Tokens> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<Tokens> _doRefresh() async {
    await ensureServerIdentity(); // 리프레시 토큰도 다른 서버에 보내지 않는다
    final plain = BangmusicApi(dio: _baseDio(profile.baseUrl)..httpClientAdapter = _dio.httpClientAdapter, interceptors: const []);
    try {
      final res = await plain.getAuthApi().refreshToken(refreshTokenRequest: RefreshTokenRequest(refreshToken: _tokens.refresh));
      final d = res.data!;
      _tokens = Tokens(d.accessToken, d.accessExpiresAt, d.refreshToken);
      await _vault.save(profile.serverId, _tokens);
      status.value = SessionStatus.active;
      return _tokens;
    } catch (e) {
      final ae = ApiException.from(e);
      if (ae.status == 401) {
        status.value = ae.code == 'refresh_expired' ? SessionStatus.expired : SessionStatus.revoked;
      }
      // 네트워크 오류·5xx: 토큰을 버리지 않는다
      throw ae;
    }
  }

  /// 같은 서버·같은 사용자로 다시 로그인했을 때 토큰만 바꿔 끼운다(앱 상태·화면 유지, 04장 §5 세션 만료)
  Future<void> replaceTokens(Tokens t) async {
    _tokens = t;
    await _vault.save(profile.serverId, t);
    status.value = SessionStatus.active;
  }

  /// 응답 본문 없이 성공/실패만 필요한 호출의 오류를 ApiException으로
  Future<T> call<T>(Future<Response<T>> Function(BangmusicApi api) f) async {
    try {
      final r = await f(api);
      return r.data as T;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 플레이리스트 편집. 생성된 PlaylistEditOpsInner(oneOf)는 모든 필드를 필수로 만들어
  /// add에 after_item_id: null(=맨 앞)을 함께 보내므로 쓰지 않고 JSON을 직접 보낸다 (P3 발견, P0 보고의 표지 업로드 결함과 같은 종류).
  Future<Playlist> editPlaylist(String playlistId, int version, List<Map<String, Object?>> ops, {String? idempotencyKey}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/playlists/$playlistId/edits',
          data: {'ops': ops}, options: Options(headers: {'If-Match': '"$version"', 'Idempotency-Key': ?idempotencyKey}));
      return Playlist.fromJson(r.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// 플레이리스트 표지 업로드. 생성된 putPlaylistCover는 이진 본문을 JSON으로 인코딩하는 결함이 있어(P0 보고 1번) Dio로 직접 보낸다
  Future<Playlist> putPlaylistCover(String playlistId, int version, List<int> bytes, String contentType) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>('/playlists/$playlistId/cover',
          data: Stream.fromIterable([bytes]),
          options: Options(headers: {'If-Match': '"$version"', Headers.contentTypeHeader: contentType, Headers.contentLengthHeader: bytes.length}));
      return Playlist.fromJson(r.data!);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> logout() async {
    try {
      await api.getAuthApi().logout();
    } catch (_) {
      // 서버에 닿지 못해도 기기에서는 로그아웃한다
    }
    await _vault.clear(profile.serverId);
    status.value = SessionStatus.none;
  }
}
