// 세션 만료 재로그인 시트 (04장 §5, S1 "세션 만료(재로그인)"): 사용자 이름이 채워져 있고 서버 주소는 고정 표시.
// 시트로 띄워 현재 화면을 잃지 않는다. 같은 사용자면 토큰만 바뀌고, 잠긴 다운로드가 풀린다.
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../scope.dart';
import '../tokens.dart';
import 'common.dart';

Future<bool> showReloginSheet(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ReloginSheet(),
  );
  return ok ?? false;
}

class _ReloginSheet extends StatefulWidget {
  const _ReloginSheet();
  @override
  State<_ReloginSheet> createState() => _ReloginSheetState();
}

class _ReloginSheetState extends State<_ReloginSheet> {
  late final _user = TextEditingController(text: context.readApp().profile?.username ?? '');
  final _pass = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.readApp().reauthenticate(_pass.text, username: _user.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final ae = ApiException.from(e);
      if (!mounted) return;
      setState(() => _error = switch ((ae.kind, ae.code)) {
            (ApiErrorKind.serverMismatch, _) => '이 주소의 서버가 이전과 다릅니다. 비밀번호를 보내지 않았습니다.',
            (_, 'invalid_credentials') => '사용자 이름 또는 비밀번호가 올바르지 않습니다.',
            (_, 'rate_limited') => '로그인 시도가 너무 많습니다. ${ae.retryAfter ?? 60}초 뒤에 다시 시도하세요.',
            (_, 'account_disabled') => '비활성화된 계정입니다.',
            _ => describeError(ae).$1,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.readApp().profile;
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('다시 로그인', style: context.text.titleLarge),
          const SizedBox(height: Space.sm),
          // 서버는 바꿀 수 없다 — 어느 서버에 비밀번호를 보내는지 먼저 보여 준다 (S1 서버 확인 카드와 같은 원칙)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(p?.baseUrl.startsWith('https') ?? false ? Icons.lock : Icons.lock_open, color: c.textMuted),
            title: Text(p?.serverName ?? ''),
            subtitle: Text(p?.baseUrl ?? ''),
          ),
          TextField(controller: _user, enabled: !_busy, autocorrect: false, autofillHints: const [AutofillHints.username], decoration: const InputDecoration(labelText: '사용자 이름')),
          const SizedBox(height: Space.md),
          TextField(
            controller: _pass, enabled: !_busy, obscureText: true, autofocus: true, textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(), autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: '비밀번호'),
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.sm),
            Semantics(liveRegion: true, child: Text(_error!, style: TextStyle(color: c.danger))),
          ],
          const SizedBox(height: Space.lg),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: '로그인 중')) : const Text('로그인'),
            ),
          ),
        ]),
      ),
    );
  }
}
