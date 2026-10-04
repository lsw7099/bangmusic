// 기기 조건 (03장 §5.7, §5.10): 연결·Wi-Fi(connectivity_plus), 여유 공간(Android StatFs, MainActivity 채널).
// "연결됨"은 망에 붙어 있다는 뜻일 뿐 서버에 닿는다는 뜻이 아니다 — 서버 도달 여부는 ApiClient.reachable.
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../data/download_engine.dart';

class PlatformConditions implements DeviceConditions {
  PlatformConditions() {
    _sub = Connectivity().onConnectivityChanged.listen((_) => _changes.add(null));
  }

  static const _storage = MethodChannel('bangmusic/storage');
  final _changes = StreamController<void>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  /// 저장 공간이 바뀌었을 수 있을 때(다운로드 삭제 등) 엔진에 알린다
  void poke() => _changes.add(null);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<({bool online, bool wifi})> network() async {
    final r = await Connectivity().checkConnectivity();
    final wifi = r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);
    final online = wifi || r.contains(ConnectivityResult.mobile) || r.contains(ConnectivityResult.vpn) || r.contains(ConnectivityResult.other);
    return (online: online, wifi: wifi);
  }

  @override
  Future<int?> freeBytes(Directory dir) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _storage.invokeMethod<int>('freeBytes', {'path': dir.path});
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() => _sub.cancel();
}
