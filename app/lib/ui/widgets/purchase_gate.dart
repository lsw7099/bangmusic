// 구매 후 기능의 문 (05장 §8.2, 04장 S11). [P7 결정] 미구매면 새 다운로드만 막고 구매 화면으로 안내한다.
import 'package:flutter/material.dart';

import '../../core/entitlement.dart';
import '../scope.dart';
import '../screens/purchase_screen.dart';

/// 쓸 수 있으면 true. 아니면 안내 창 → (원하면) 구매 화면, 돌아온 뒤 다시 판단한다.
Future<bool> ensureCan(BuildContext context, Feature f) async {
  final ent = context.readApp().entitlement;
  if (ent.can(f)) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('구매 후 사용할 수 있습니다'),
      content: const Text('다운로드(오프라인 저장)는 구매 후 사용할 수 있습니다. 스트리밍 재생은 지금처럼 무료입니다.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('닫기')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('구매 화면으로')),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PurchaseScreen()));
  return ent.can(f);
}
