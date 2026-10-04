// 앱 구매 권한 (05장 §8.2). [P7 결정] 미구매 상태에서는 새 다운로드 시작만 막는다.
// 규칙: 이 클래스는 서버 프로필·토큰·라이브러리에 닿지 않는다. 음악 서버는 앱 구매 여부를 모른다.
// 제한 지점은 can() 한 곳 — 이미 받은 곡 재생·로그아웃·다운로드 삭제·계정 삭제·내보내기는 묻지 않는다(규칙 4).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/store_port.dart';

enum Feature {
  /// 새 다운로드 시작 (앨범·플레이리스트·곡)
  download,
}

class EntitlementService extends ChangeNotifier {
  EntitlementService(this.store) {
    _sub = store.changes.listen(_set);
  }

  final StorePort store;
  late final StreamSubscription<PurchaseState> _sub;
  PurchaseState _state = PurchaseState.notPurchased;

  PurchaseState get state => _state;

  bool can(Feature f) => switch (f) {
        Feature.download => _state == PurchaseState.purchased,
      };

  /// 앱 시작: 기기에 저장된 마지막 상태 (스토어에 닿지 않아도 그대로 인정, 03장 §5.8)
  Future<void> load() async => _set(await store.cachedState());

  Future<StoreResult> buy() => _then(store.buy());
  Future<StoreResult> restore() => _then(store.restore());

  Future<StoreResult> _then(Future<StoreResult> f) async {
    final r = await f;
    _set(await store.cachedState());
    return r;
  }

  void _set(PurchaseState s) {
    if (s == _state) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
