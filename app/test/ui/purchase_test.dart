// [P7 결정] 1회 구매: 미구매면 새 다운로드만 막고 구매 화면으로 안내 (05장 §8.2, 04장 S11).
import 'package:bangmusic/core/entitlement.dart';
import 'package:bangmusic/platform/play_store.dart';
import 'package:bangmusic/platform/store_port.dart';
import 'package:bangmusic/ui/widgets/purchase_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'fakes.dart';

class _Gate extends StatelessWidget {
  const _Gate(this.result);
  final List<bool> result;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: TextButton(onPressed: () async => result.add(await ensureCan(context, Feature.download)), child: const Text('받기'))),
      );
}

void main() {
  test('권한: 다운로드는 구매했을 때만, 상태는 기기 캐시에서 읽고 스토어 소식으로 갱신', () async {
    final store = FakeStore();
    final e = EntitlementService(store);
    await e.load();
    expect(e.can(Feature.download), isFalse);
    store.push(PurchaseState.pending);
    await Future<void>.delayed(Duration.zero);
    expect(e.state, PurchaseState.pending);
    expect(e.can(Feature.download), isFalse, reason: '보류 중 결제는 아직 아니다');
    store.push(PurchaseState.purchased);
    await Future<void>.delayed(Duration.zero);
    expect(e.can(Feature.download), isTrue);
  });

  test('Play 구매 내역 → 앱 상태: 구매·복원은 구매함, 보류만 있으면 보류, 없으면 null', () {
    expect(PlayStore.stateOf([PurchaseStatus.restored]), PurchaseState.purchased);
    expect(PlayStore.stateOf([PurchaseStatus.pending, PurchaseStatus.purchased]), PurchaseState.purchased);
    expect(PlayStore.stateOf([PurchaseStatus.pending]), PurchaseState.pending);
    expect(PlayStore.stateOf([PurchaseStatus.canceled]), isNull);
    expect(PlayStore.stateOf([]), isNull);
  });

  testWidgets('미구매: 다운로드를 누르면 안내 → 닫으면 받지 않는다', (t) async {
    final result = <bool>[];
    await pumpApp(t, _Gate(result), purchases: FakeStore());
    await t.tap(find.text('받기'));
    await t.pumpAndSettle();
    expect(find.text('구매 후 사용할 수 있습니다'), findsOneWidget);
    await t.tap(find.text('닫기'));
    await t.pumpAndSettle();
    expect(result, [false]);
  });

  testWidgets('미구매: 구매 화면에서 사면 돌아와 바로 받는다', (t) async {
    final store = FakeStore();
    final result = <bool>[];
    final (app, _, _) = await pumpApp(t, _Gate(result), purchases: store);
    await t.tap(find.text('받기'));
    await t.pumpAndSettle();
    await t.tap(find.text('구매 화면으로'));
    await t.pumpAndSettle();
    expect(find.text('₩5,900에 구매'), findsOneWidget);
    expect(find.textContaining('구매 후: 다운로드'), findsOneWidget);
    await t.tap(find.text('₩5,900에 구매'));
    await t.pumpAndSettle();
    expect(store.buys, 1);
    expect(find.text('구매가 확인되었습니다.'), findsOneWidget);
    expect(app.entitlement.state, PurchaseState.purchased);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(result, [true]);
  });

  testWidgets('구매함: 안내 없이 바로 받는다', (t) async {
    final result = <bool>[];
    await pumpApp(t, _Gate(result), purchases: FakeStore(state: PurchaseState.purchased));
    await t.tap(find.text('받기'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(result, [true]);
  });

  testWidgets('결제 취소: 상태는 그대로, 취소 문구', (t) async {
    final store = FakeStore()..next = const StoreCancelled();
    final (app, _, _) = await pumpApp(t, _Gate(const []), purchases: store);
    await t.tap(find.text('받기'));
    await t.pumpAndSettle();
    await t.tap(find.text('구매 화면으로'));
    await t.pumpAndSettle();
    await t.tap(find.text('₩5,900에 구매'));
    await t.pumpAndSettle();
    expect(find.text('결제를 취소했습니다.'), findsOneWidget);
    expect(app.entitlement.can(Feature.download), isFalse);
  });
}
