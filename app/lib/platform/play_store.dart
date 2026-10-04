// Google Play 1회 구매 (05장 §8.1·8.2, 04장 S11). 구매 확인 서버 없이 기기에서 스토어 구매 내역으로 판단한다.
// - 이 파일은 스토어와만 통신한다. 서버 주소·계정·토큰·곡 정보에 닿는 코드 경로가 없다(05장 §8.2 규칙 1·2).
// - 마지막으로 확인한 상태를 기기에 저장하고, 스토어에 닿지 못해도 그 상태를 그대로 인정한다(규칙 3, 03장 §5.8).
// - 구매는 3일 안에 확인(acknowledge)하지 않으면 Play가 환불한다 → completePurchase를 반드시 부른다.
import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_info.dart';
import 'store_port.dart';

class PlayStore implements StorePort {
  PlayStore({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance {
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object _) {});
  }

  static const _key = 'purchase_state';
  final InAppPurchase _iap;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _changes = StreamController<PurchaseState>.broadcast();
  Completer<StoreResult>? _buying;
  ProductDetails? _product;

  @override
  Stream<PurchaseState> get changes => _changes.stream;

  @override
  Future<PurchaseState> cachedState() async {
    final p = await SharedPreferences.getInstance();
    return PurchaseState.values.asNameMap()[p.getString(_key)] ?? PurchaseState.notPurchased;
  }

  Future<void> _save(PurchaseState s) async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_key) == s.name) return;
    await p.setString(_key, s.name);
    _changes.add(s);
  }

  @override
  Future<StoreProduct?> product() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final r = await _iap.queryProductDetails({AppInfo.unlockProductId});
      if (r.productDetails.isEmpty) return null;
      final d = _product = r.productDetails.first;
      return StoreProduct(id: d.id, title: d.title, description: d.description, price: d.price);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StoreResult> buy() async {
    if (!await _iap.isAvailable()) return const StoreUnavailable('스토어 앱에 연결하지 못했습니다');
    if (_product == null) await product();
    final d = _product;
    if (d == null) return const StoreUnavailable('상품 정보를 받지 못했습니다');
    final done = _buying = Completer<StoreResult>();
    try {
      if (!await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d))) {
        _buying = null;
        return const StoreUnavailable('결제를 시작하지 못했습니다');
      }
    } catch (_) {
      _buying = null;
      return const StoreUnavailable('결제를 시작하지 못했습니다');
    }
    return done.future;
  }

  @override
  Future<StoreResult> restore() async {
    if (!await _iap.isAvailable()) return const StoreUnavailable('스토어 앱에 연결하지 못했습니다');
    // Android는 내역 조회가 바로 결과를 준다(restorePurchases는 내역이 없으면 아무 소식도 없다)
    final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final r = await addition.queryPastPurchases();
    if (r.error != null) return const StoreUnavailable('구매 내역을 조회하지 못했습니다');
    final mine = r.pastPurchases.where((p) => p.productID == AppInfo.unlockProductId).toList();
    for (final p in mine) {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    final state = stateOf(mine.map((p) => p.status));
    if (state == null) {
      // 스토어가 "내역 없음"이라고 확인해 준 경우에만 내린다(환불된 구매)
      await _save(PurchaseState.notPurchased);
      return const StoreNothingToRestore();
    }
    await _save(state);
    return StoreOk(state);
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list.where((p) => p.productID == AppInfo.unlockProductId)) {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      final StoreResult result;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _save(PurchaseState.purchased);
          result = const StoreOk(PurchaseState.purchased);
        case PurchaseStatus.pending:
          if (await cachedState() != PurchaseState.purchased) await _save(PurchaseState.pending);
          result = const StoreOk(PurchaseState.pending);
        case PurchaseStatus.canceled:
          result = const StoreCancelled();
        case PurchaseStatus.error:
          result = const StoreUnavailable('결제에 실패했습니다');
      }
      final b = _buying;
      if (b != null && !b.isCompleted) {
        _buying = null;
        b.complete(result);
      }
    }
  }

  /// 구매 내역들의 상태 → 앱 구매 상태. 내역이 없으면 null
  static PurchaseState? stateOf(Iterable<PurchaseStatus> statuses) {
    if (statuses.any((s) => s == PurchaseStatus.purchased || s == PurchaseStatus.restored)) return PurchaseState.purchased;
    if (statuses.any((s) => s == PurchaseStatus.pending)) return PurchaseState.pending;
    return null;
  }

  Future<void> dispose() async {
    await _sub.cancel();
    await _changes.close();
  }
}
