// 앱 구매 경계 (04장 S11, 05장 §8.1·8.2). [P7 결정] 무료 설치 + 1회 구매(비소모성), 구매 확인 서버 없음.
// 화면·EntitlementService는 이 인터페이스만 안다. 기기 구현은 play_store.dart. 구매 상태는 서버 로그인과 무관하다(03장 §5.8).
import 'dart:async';

class StoreProduct {
  const StoreProduct({required this.id, required this.title, required this.description, required this.price});
  final String id;
  final String title;
  final String description;

  /// 스토어가 준 현지화 가격 문자열 (예: "₩5,900")
  final String price;
}

enum PurchaseState { notPurchased, purchased, pending }

sealed class StoreResult {
  const StoreResult();
}

class StoreOk extends StoreResult {
  const StoreOk(this.state);
  final PurchaseState state;
}

/// 사용자가 결제를 취소
class StoreCancelled extends StoreResult {
  const StoreCancelled();
}

/// 스토어에 연결하지 못함 (오프라인, 스토어 앱 없음, 판매 방식 미정)
class StoreUnavailable extends StoreResult {
  const StoreUnavailable(this.reason);
  final String reason;
}

/// 복원했는데 구매 내역이 없음
class StoreNothingToRestore extends StoreResult {
  const StoreNothingToRestore();
}

abstract interface class StorePort {
  /// 마지막으로 확인한 구매 상태 (오프라인에서도 그대로 인정, 03장 §5.8)
  Future<PurchaseState> cachedState();
  Future<StoreProduct?> product();
  Future<StoreResult> buy();
  Future<StoreResult> restore();

  /// 화면 밖에서 바뀐 구매 상태 (보류 중 결제 완료, 다른 기기에서 구매 후 복원 등)
  Stream<PurchaseState> get changes;
}

/// 스토어가 없는 환경(데스크톱 시험, Play 스토어가 없는 기기): 연결하지 않는다
class UndecidedStore implements StorePort {
  const UndecidedStore();
  static const _reason = '이 기기에서는 스토어를 사용할 수 없습니다';
  @override
  Stream<PurchaseState> get changes => const Stream.empty();
  @override
  Future<PurchaseState> cachedState() async => PurchaseState.notPurchased;
  @override
  Future<StoreProduct?> product() async => null;
  @override
  Future<StoreResult> buy() async => const StoreUnavailable(_reason);
  @override
  Future<StoreResult> restore() async => const StoreUnavailable(_reason);
}
