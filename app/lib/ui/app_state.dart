// 앱 전역 상태: 서버 프로필(여러 개, FN-21), 세션, 로컬 라이브러리·다운로드 엔진(프로필·사용자별, 03장 §5.2), 오프라인 동기화.
// 프로필은 server_id로 구별한다(01장 §6). 토큰은 server_id별 보안 저장소, 로컬 DB·파일은 profiles/<server_id>/<user_id>/.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/entitlement.dart';
import '../core/session.dart';
import '../data/download_engine.dart';
import '../data/library_store.dart';
import '../data/offline_sync.dart';
import '../platform/background_transfer.dart';
import '../platform/device_conditions.dart';
import '../platform/play_store.dart';
import '../platform/player_port.dart';
import '../platform/playback_engine.dart' show androidAccept;
import '../platform/secure_store.dart';
import '../platform/store_port.dart';
import '../platform/transfer_port.dart';
import 'app_prefs.dart';

/// 기기 쪽 구성요소 (위젯 테스트에서는 없음 → 다운로드·오프라인 기능 없이 동작)
class AppServices {
  AppServices({required this.transfer, required this.conditions, required this.openStore, this.store = const UndecidedStore()});
  final Future<TransferPort> Function() transfer;
  final DeviceConditions conditions;
  final Future<LibraryStore> Function(String serverId, String userId) openStore;

  /// 앱 구매 (05장 §8.1). 서버 쪽 구성요소와 데이터를 나누지 않는다
  final StorePort store;

  static AppServices platform() => AppServices(
        transfer: () async => Platform.isAndroid ? await BackgroundTransfer.create() : HttpTransfer(),
        conditions: PlatformConditions(),
        openStore: LibraryStore.open,
        store: Platform.isAndroid ? PlayStore() : const UndecidedStore(),
      );
}

/// 상단 표시용 연결 상태 (03장 §6.8: 기기 오프라인과 서버 무응답을 구분)
enum Connection { online, deviceOffline, serverUnreachable }

class AppState extends ChangeNotifier {
  AppState({required this.player, SecureStore? store, this.services, StorePort? purchases})
      : vault = TokenVault(store ?? const PlatformSecureStore()),
        entitlement = EntitlementService(purchases ?? services?.store ?? const UndecidedStore());

  final PlayerPort player;
  final TokenVault vault;
  final AppServices? services;

  /// 앱 구매 권한 (05장 §8.2). [P7 결정] 미구매면 새 다운로드만 막는다
  final EntitlementService entitlement;

  /// 등록한 서버들 (로그아웃하며 다운로드를 보관한 프로필도 남는다)
  List<ServerProfile> profiles = [];
  ServerProfile? profile;
  ApiClient? api;
  LibraryStore? library;
  DownloadEngine? downloads;
  OfflineSync? _sync;
  TransferPort? _transfer;
  bool ready = false;
  bool deviceOnline = true;
  StreamSubscription<void>? _condSub;

  final downloadSettings = DownloadSettings();

  /// 재생·가사·화면 설정 (기기 로컬)
  final prefs = AppPrefs();

  static const _profilesKey = 'profiles';
  static const _activeKey = 'profile.active';
  static const _installKey = 'installation_id';

  SessionStatus get session => api?.status.value ?? SessionStatus.none;

  Connection get connection => !deviceOnline
      ? Connection.deviceOffline
      : (api != null && !api!.reachable.value)
          ? Connection.serverUnreachable
          : Connection.online;

  /// 서버 대신 로컬 사본으로 화면을 그려야 하는가 (03장 §5.6, §6.8).
  /// 세션 만료도 포함한다 — 스트리밍·동기화는 안 되지만 받은 음악은 들을 수 있어야 한다(03장 §5.8, 실기기에서 화면이 오류만 보이던 것)
  bool get offline => library != null && (connection != Connection.online || session == SessionStatus.expired || serverChanged);

  /// 이 주소의 서버가 로그인했던 서버와 다르다 (03장 §5.2) — 토큰을 보내지 않고 받은 음악만
  bool get serverChanged => api?.serverChanged.value ?? false;

  Future<void> load() async {
    this.prefs.addListener(notifyListeners);
    await this.prefs.load();
    entitlement.addListener(notifyListeners);
    await entitlement.load();
    final prefs = await SharedPreferences.getInstance();
    await _loadSettings(prefs);
    profiles = _readProfiles(prefs);
    // P3 형식을 옮겼으면 바로 저장한다 — 저장하지 않아 다음 실행에서 로그인이 풀리던 결함(실기기에서 발견)
    if (_migrated) await _saveProfiles(activeId: prefs.getString(_activeKey));
    final activeId = prefs.getString(_activeKey);
    final active = profiles.where((p) => p.serverId == activeId).firstOrNull;
    if (services != null) {
      _condSub = services!.conditions.changes.listen((_) => unawaited(_onConditions()));
      deviceOnline = (await services!.conditions.network()).online;
    }
    if (active != null) {
      final t = await vault.load(active.serverId);
      // 서버에 닿지 못해도 저장된 토큰과 로컬 DB로 바로 시작한다 (03장 §6.8)
      if (t != null) await _activate(active, t);
    }
    ready = true;
    notifyListeners();
  }

  bool _migrated = false;

  List<ServerProfile> _readProfiles(SharedPreferences prefs) {
    final out = <ServerProfile>[];
    for (final s in prefs.getStringList(_profilesKey) ?? const <String>[]) {
      try {
        out.add(ServerProfile.fromJson((jsonDecode(s) as Map).cast()));
      } catch (_) {}
    }
    // P3 형식: profile.active에 프로필 JSON 하나
    final legacy = prefs.getString(_activeKey);
    if (legacy != null && legacy.startsWith('{')) {
      try {
        final p = ServerProfile.fromJson((jsonDecode(legacy) as Map).cast());
        if (!out.any((x) => x.serverId == p.serverId)) out.add(p);
        _migrated = true;
      } catch (_) {}
    }
    return out;
  }

  Future<void> _saveProfiles({String? activeId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_profilesKey, [for (final p in profiles) jsonEncode(p.toJson())]);
    final active = profile?.serverId ?? (activeId != null && activeId.startsWith('{') ? profiles.lastOrNull?.serverId : activeId);
    if (active != null) {
      await prefs.setString(_activeKey, active);
    } else {
      await prefs.remove(_activeKey);
    }
  }

  Future<void> _loadSettings(SharedPreferences prefs) async {
    downloadSettings.wifiOnly = prefs.getBool('dl.wifi_only') ?? true;
    final mb = prefs.getInt('dl.limit_mb');
    downloadSettings.limitBytes = mb == null ? null : mb * 1024 * 1024;
    downloadSettings.quality = prefs.getString('dl.quality') ?? 'original';
    downloadSettings.concurrency = prefs.getInt('dl.concurrency') ?? 2;
    downloadSettings.autoUpdate = prefs.getBool('dl.auto_update') ?? true;
  }

  /// 다운로드 설정 (S10). 바뀌면 대기 중 항목을 다시 판단한다
  Future<void> setDownloadSettings({bool? wifiOnly, int? limitMb, bool clearLimit = false, String? quality, bool? autoUpdate, int? concurrency}) async {
    final prefs = await SharedPreferences.getInstance();
    if (autoUpdate != null) {
      downloadSettings.autoUpdate = autoUpdate;
      await prefs.setBool('dl.auto_update', autoUpdate);
    }
    if (concurrency != null) {
      downloadSettings.concurrency = concurrency.clamp(1, 4);
      await prefs.setInt('dl.concurrency', downloadSettings.concurrency);
    }
    if (wifiOnly != null) {
      downloadSettings.wifiOnly = wifiOnly;
      await prefs.setBool('dl.wifi_only', wifiOnly);
    }
    if (clearLimit) {
      downloadSettings.limitBytes = null;
      await prefs.remove('dl.limit_mb');
    } else if (limitMb != null) {
      downloadSettings.limitBytes = limitMb * 1024 * 1024;
      await prefs.setInt('dl.limit_mb', limitMb);
    }
    if (quality != null) {
      downloadSettings.quality = quality;
      await prefs.setString('dl.quality', quality);
    }
    if (services?.conditions case final PlatformConditions c) c.poke();
    notifyListeners();
  }

  Future<String> installationId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_installKey);
    if (id == null) {
      final r = Random.secure();
      String h(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
      id = '${h(8)}-${h(4)}-4${h(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${h(3)}-${h(12)}';
      await prefs.setString(_installKey, id);
    }
    return id;
  }

  /// 이 주소로 등록했던 서버인데 server_id가 다르다 (03장 §5.2: 재설치·주소 재사용·위장 서버)
  ServerProfile? differentServerAt(ProbeOk server) =>
      profiles.where((p) => p.baseUrl == server.baseUrl && p.serverId != server.info.serverId).firstOrNull;

  Future<void> signIn(ProbeOk server, String username, String password) async {
    final (t, info) = await loginToServer(server, username, password, await installationId(), 'Android');
    final p = ServerProfile(
      serverId: info.serverId, baseUrl: server.baseUrl, serverName: info.name,
      userId: t.user.id, username: t.user.username, displayName: t.user.displayName, installationId: await installationId(),
    );
    // 다른 서버로 바꾸는 것이면 이전 프로필은 내려놓기만 한다(토큰·다운로드 유지). 토큰은 server_id별이라 새 서버에 가지 않는다(FN-21)
    await _deactivate();
    final tokens = Tokens(t.accessToken, t.accessExpiresAt, t.refreshToken);
    await vault.save(p.serverId, tokens);
    profiles = [for (final x in profiles) if (x.serverId != p.serverId) x, p];
    await _activate(p, tokens);
    await _saveProfiles();
    // 같은 사용자로 다시 로그인: 접근 취소·로그아웃 보관으로 잠긴 다운로드를 푼다 (03장 §5.8)
    await downloads?.unlockAll();
    notifyListeners();
  }

  /// 저장된 다른 서버로 전환 (FN-21). 토큰이 없으면 false → 로그인 화면
  Future<bool> switchTo(ServerProfile p) async {
    if (p.serverId == profile?.serverId) return true;
    final t = await vault.load(p.serverId);
    if (t == null) return false;
    await _deactivate();
    await _activate(p, t);
    await _saveProfiles();
    notifyListeners();
    return true;
  }

  Future<void> _activate(ServerProfile p, Tokens t) async {
    profile = p;
    final client = ApiClient(profile: p, vault: vault, tokens: t);
    api = client;
    client.status.addListener(notifyListeners);
    client.reachable.addListener(_onReachable);
    client.serverChanged.addListener(notifyListeners);
    client.serverNotice.addListener(_onServerNotice);
    final s = services;
    if (s != null) {
      library = await s.openStore(p.serverId, p.userId);
      _transfer ??= await s.transfer();
      downloads = DownloadEngine(store: library!, transfer: _transfer!, conditions: s.conditions, accept: androidAccept, settings: downloadSettings);
      await downloads!.start(api: client);
      _sync = OfflineSync(api: client, store: library!, downloads: downloads);
      await _migrateHistory(p.serverId);
    }
    await player.attach(client, library: library, downloads: downloads, onPlayEvent: recordPlay, streamQuality: streamQuality);
    unawaited(syncNow());
  }

  Future<void> _deactivate() async {
    if (profile == null) return;
    await player.detach();
    api?.status.removeListener(notifyListeners);
    api?.reachable.removeListener(_onReachable);
    api?.serverChanged.removeListener(notifyListeners);
    api?.serverNotice.removeListener(_onServerNotice);
    _maintenanceTimer?.cancel();
    await downloads?.dispose();
    await library?.close();
    downloads = null;
    library = null;
    _sync = null;
    api = null;
    profile = null;
  }

  /// 서버 점검이면 30초마다 다시 확인한다 (04장 §5: 자동 재시도). 끝나면 동기화
  Timer? _maintenanceTimer;
  String? get serverNotice => api?.serverNotice.value;
  void _onServerNotice() {
    final n = api?.serverNotice.value;
    _maintenanceTimer?.cancel();
    if (n == 'maintenance' && services != null) { // 실제 기기 구성에서만 (위젯 시험에는 시계가 없다)
      _maintenanceTimer = Timer.periodic(const Duration(seconds: 30), (_) => unawaited(_ping()));
    } else if (n == null) {
      unawaited(syncNow());
    }
    notifyListeners();
  }

  bool _wasReachable = true;
  void _onReachable() {
    final now = api?.reachable.value ?? false;
    if (now && !_wasReachable) unawaited(syncNow()); // 연결 복귀
    _wasReachable = now;
    notifyListeners();
  }

  Future<void> _onConditions() async {
    final s = services;
    if (s == null) return;
    final was = deviceOnline;
    deviceOnline = (await s.conditions.network()).online;
    if (deviceOnline && !was) unawaited(_ping());
    notifyListeners();
  }

  /// 서버에 닿는지 확인 (응답을 받으면 reachable이 true가 되며 동기화가 돈다). 점검 여부는 인증 요청으로 알 수 있다
  Future<void> _ping() async {
    try {
      await api?.call((x) => x.getServerApi().getServerInfo());
      if (api?.serverNotice.value == 'maintenance') await api?.call((x) => x.getMeApi().getMe());
    } catch (_) {}
  }

  /// 스트리밍 음질 (04장 S10 재생): Wi-Fi/셀룰러별, 셀룰러 스트리밍을 껐으면 null(스트리밍 안 함)
  Future<String?> streamQuality() async {
    final net = await services?.conditions.network();
    if (net == null || net.wifi) return prefs.streamQualityWifi;
    return prefs.allowCellularStreaming ? prefs.streamQualityCellular : null;
  }

  /// 세션 만료 후 같은 서버에 다시 로그인 (04장 §5: 시트로 띄워 현재 화면을 잃지 않는다).
  /// 같은 사용자면 토큰만 바꾸고, 다른 사용자면 그 사용자로 전환한다.
  Future<void> reauthenticate(String password, {String? username}) async {
    final p = profile;
    if (p == null) return;
    final probe = await probeServer(p.baseUrl);
    if (probe is! ProbeOk) throw (probe is ProbeFailed ? probe.error : ApiException(kind: ApiErrorKind.unknown));
    // 다른 서버에 비밀번호를 보내지 않는다 (03장 §5.2)
    if (probe.info.serverId != p.serverId) throw ApiException(kind: ApiErrorKind.serverMismatch);
    final user = username ?? p.username;
    if (user != p.username) return signIn(probe, user, password);
    final (t, _) = await loginToServer(probe, user, password, await installationId(), 'Android');
    if (t.user.id != p.userId) return signIn(probe, user, password);
    await api!.replaceTokens(Tokens(t.accessToken, t.accessExpiresAt, t.refreshToken));
    await downloads?.unlockAll();
    unawaited(syncNow());
    notifyListeners();
  }

  /// 활성이 아닌 서버 프로필 삭제 (04장 S10 서버 삭제): 토큰·로컬 DB·다운로드 파일을 지운다
  Future<void> removeProfile(ServerProfile p) async {
    if (p.serverId == profile?.serverId) return;
    await vault.clear(p.serverId);
    if (services != null) {
      try {
        final dir = await LibraryStore.profileDir(p.serverId, p.userId);
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
    profiles = [for (final x in profiles) if (x.serverId != p.serverId) x];
    await _saveProfiles();
    notifyListeners();
  }

  /// 연결 복귀 동기화 (FN-22). 오프라인이면 아무것도 하지 않는다
  Future<SyncReport?> syncNow() async {
    final s = _sync;
    if (s == null || !deviceOnline) return null;
    try {
      return await s.run();
    } catch (e) {
      debugPrint('동기화 실패: $e');
      return null;
    }
  }

  /// 재생 기록 한 건: 로컬 DB에 쌓고(event_id로 중복 제거), 연결돼 있으면 바로 보낸다 (03장 §6.9, FN-22)
  Future<void> recordPlay(PlayEvent e) async {
    final lib = library;
    final client = api;
    if (lib == null) {
      try {
        await client?.call((x) => x.getHistoryApi().postPlayEvents(postPlayEventsRequest: PostPlayEventsRequest(events: [e])));
      } catch (_) {}
      return;
    }
    await lib.addPlayEvent(e);
    if (!offline) unawaited(_sync?.sendPlayEvents());
  }

  /// P3 버전이 SharedPreferences에 쌓아 둔 미전송 기록을 로컬 DB로 옮긴다
  Future<void> _migrateHistory(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history.pending.$serverId';
    final pending = prefs.getStringList(key);
    if (pending == null) return;
    for (final s in pending) {
      try {
        await library!.addPlayEvent(PlayEvent.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    await prefs.remove(key);
  }

  /// 위젯 테스트·상태 갤러리용: 기기 연결 상태를 바꾼다
  @visibleForTesting
  void debugSetDeviceOnline(bool online) {
    deviceOnline = online;
    notifyListeners();
  }

  /// 위젯 테스트용: 로그인한 상태로 만든다
  @visibleForTesting
  void debugActivate(ServerProfile p, ApiClient client, {LibraryStore? library, DownloadEngine? downloads}) {
    profile = p;
    api = client;
    this.library = library;
    this.downloads = downloads;
    profiles = [p];
    ready = true;
    client.status.addListener(notifyListeners);
    client.reachable.addListener(notifyListeners);
    client.serverChanged.addListener(notifyListeners);
    client.serverNotice.addListener(_onServerNotice);
    notifyListeners();
  }

  /// 로그아웃 (03장 §5.8). 기본은 이 기기의 다운로드 삭제, keepDownloads면 잠가서 보관(같은 사용자로 로그인하면 해제)
  Future<void> signOut({bool keepDownloads = false}) async {
    final p = profile;
    if (p == null) return;
    if (keepDownloads) {
      await downloads?.lockAll();
    } else {
      await downloads?.deleteAll();
    }
    final client = api;
    await _deactivate();
    await client?.logout();
    if (!keepDownloads) {
      profiles = [for (final x in profiles) if (x.serverId != p.serverId) x];
      if (services != null) {
        try {
          final dir = await LibraryStore.profileDir(p.serverId, p.userId);
          if (await dir.exists()) await dir.delete(recursive: true);
        } catch (_) {}
      }
    }
    await _saveProfiles();
    notifyListeners();
  }

  /// 현재 프로필을 내려놓는다(로컬 DB·전송 정리). 앱 종료·테스트 정리용 — 로그아웃이 아니다
  Future<void> close() async {
    await _deactivate();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_condSub?.cancel());
    super.dispose();
  }
}
