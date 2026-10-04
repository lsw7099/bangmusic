// S11 구매 · 복원 (04장 S11). [P7 결정] 무료 설치 + 1회 구매 — 구매하면 다운로드(오프라인 저장)가 열린다.
// 음악 서버 로그인과 분리: 서버 주소·계정을 묻지 않고, 구매 여부가 서버 로그인에 영향을 주지 않는다.
import 'package:flutter/material.dart';

import '../../platform/store_port.dart';
import '../app_state.dart';
import '../scope.dart';
import '../tokens.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late Future<StoreProduct?> _f = _load();
  String? _message;
  bool _busy = false;

  Future<StoreProduct?> _load() => context.readApp().entitlement.store.product();

  String _describe(StoreResult r) => switch (r) {
        StoreOk(state: PurchaseState.pending) => '결제가 보류 중입니다. 스토어에서 결제를 마치면 자동으로 반영됩니다.',
        StoreOk(state: PurchaseState.purchased) => '구매가 확인되었습니다.',
        StoreOk() => '구매 내역이 없습니다.',
        StoreCancelled() => '결제를 취소했습니다.',
        StoreNothingToRestore() => '이 스토어 계정에서 구매 내역을 찾지 못했습니다. 구매한 계정으로 스토어에 로그인했는지 확인하세요.',
        StoreUnavailable(:final reason) => '스토어에 연결할 수 없습니다 ($reason).',
      };

  Future<void> _run(Future<StoreResult> Function() f) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final r = await f();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = _describe(r);
      _f = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final offline = app.connection == Connection.deviceOffline;
    final c = context.colors;
    final state = app.entitlement.state;
    return Scaffold(
      appBar: AppBar(title: const Text('구매 · 복원')),
      body: FutureBuilder<StoreProduct?>(
        future: _f,
        builder: (context, s) {
          final product = s.data;
          final canBuy = !offline && !_busy && product != null && state != PurchaseState.purchased;
          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(Space.xl), children: [
                Text('BangMusic', style: context.text.headlineSmall),
                const SizedBox(height: Space.sm),
                Text(product?.description ?? '내 음악 서버의 음악을 휴대폰에서 듣고, 받아 두고, 오프라인에서도 재생합니다.', style: TextStyle(color: c.textMuted)),
                const SizedBox(height: Space.md),
                // [P7 결정] 무엇이 무료이고 무엇이 구매 후인지 (05장 §8.2)
                const Text('무료: 서버 연결, 탐색, 스트리밍 재생, 가사, 플레이리스트\n'
                    '구매 후: 다운로드(오프라인 저장)\n'
                    '이미 받아 둔 곡은 구매 상태와 관계없이 계속 재생됩니다.'),
                const SizedBox(height: Space.xl),
                // 가격은 스토어가 준 현지화 문자열만. 응답 전에는 자리표시자
                Semantics(
                  label: product == null ? '가격을 불러오지 못했습니다' : '가격 ${product.price}',
                  child: Text(product?.price ?? '— — —', style: context.text.headlineMedium),
                ),
                const SizedBox(height: Space.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(state == PurchaseState.purchased ? Icons.verified : Icons.info_outline, color: state == PurchaseState.purchased ? c.success : c.textMuted),
                  title: Text(switch (state) {
                    PurchaseState.purchased => '구매함',
                    PurchaseState.pending => '결제 보류 중',
                    PurchaseState.notPurchased => '구매하지 않음',
                  }),
                  subtitle: const Text('구매 상태는 음악 서버 로그인과 관계없습니다.'),
                ),
                if (offline) Text('오프라인에서는 구매·복원을 할 수 없습니다. 마지막으로 확인한 구매 상태가 그대로 유지됩니다.', style: TextStyle(color: c.warning)),
                if (_message != null) ...[
                  const SizedBox(height: Space.md),
                  Semantics(liveRegion: true, child: Text(_message!)),
                ],
                const SizedBox(height: Space.lg),
                Wrap(spacing: Space.md, children: [
                  TextButton(onPressed: null, child: const Text('이용약관 (출시 전 준비)')),
                  TextButton(onPressed: null, child: const Text('개인정보 처리방침 (출시 전 준비)')),
                ]),
              ]),
            ),
            // 큰 글씨에서도 구매 버튼은 하단에 고정 (04장 S11)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  FilledButton(onPressed: canBuy ? () => _run(app.entitlement.buy) : null, child: Text(product == null ? '구매 (스토어 응답 대기)' : '${product.price}에 구매')),
                  const SizedBox(height: Space.sm),
                  OutlinedButton(onPressed: offline || _busy ? null : () => _run(app.entitlement.restore), child: const Text('구매 복원')),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
