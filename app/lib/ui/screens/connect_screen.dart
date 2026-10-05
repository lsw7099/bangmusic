// S1. 서버 연결 · 로그인 (04장 S1)
// ① 주소 입력 → ② 서버 확인 카드(비밀번호 입력 전에 대상 서버를 보여 준다) → ③ 사용자 이름·비밀번호
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/app_info.dart';
import '../../core/server_address.dart';
import '../glass.dart';
import '../scope.dart';
import '../tokens.dart';
import '../widgets/common.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, this.probe = probeServer, this.signIn, this.initialAddress, this.asRoute = false});

  /// 서버 확인 (테스트에서 가짜로 바꾼다)
  final Future<ProbeResult> Function(String baseUrl) probe;

  /// 로그인 (테스트에서 가짜로 바꾼다). 없으면 AppState.signIn
  final Future<void> Function(ProbeOk server, String username, String password)? signIn;

  /// 저장된 서버에 다시 로그인할 때 미리 채울 주소
  final String? initialAddress;

  /// 설정에서 "서버 추가"로 연 화면: 로그인하면 닫는다
  final bool asRoute;
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

const _localNetworkMessage = '집 안 네트워크의 서버에 연결하려면 권한이 필요합니다.\n앱 설정 → 권한에서 "주변 기기"(로컬 네트워크)를 허용하세요.';

class _ConnectScreenState extends State<ConnectScreen> {
  final _address = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  ProbeOk? _server;
  String? _error;
  bool _busy = false;
  bool _slow = false;
  Timer? _slowTimer;
  int _attempt = 0; // "취소"하면 늦게 온 응답은 버린다

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) _address.text = widget.initialAddress!;
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    for (final c in [_address, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setBusy(bool b) {
    _slowTimer?.cancel();
    setState(() {
      _busy = b;
      _slow = false;
    });
    // 10초 넘으면 "응답이 느립니다"
    if (b) _slowTimer = Timer(const Duration(seconds: 10), () => mounted ? setState(() => _slow = true) : null);
  }

  Future<void> _check() async {
    final n = normalizeServerAddress(_address.text, allowCleartext: AppInfo.allowCleartext);
    if (n is AddressError) {
      setState(() => _error = n.message);
      return;
    }
    _setBusy(true);
    setState(() => _error = null);
    final attempt = ++_attempt;
    final r = await widget.probe((n as AddressOk).baseUrl);
    if (!mounted || attempt != _attempt) return;
    _setBusy(false);
    setState(() {
      switch (r) {
        case ProbeOk():
          _server = r;
        case ProbeIncompatible(:final reason, :final info):
          _error = switch (reason) {
            Incompatibility.unsupportedMajor => '이 서버는 지원되지 않는 버전입니다.',
            Incompatibility.serverTooOld => '서버 업데이트가 필요합니다 (현재 ${info.version}).',
            Incompatibility.appTooOld => '이 서버에 연결하려면 앱을 업데이트하세요.',
          };
        case ProbeFailed(:final error):
          _error = switch (error.kind) {
            ApiErrorKind.unreachable || ApiErrorKind.timeout => '서버를 찾을 수 없습니다.\n주소, 같은 네트워크(또는 VPN) 연결, 포트를 확인하세요.',
            ApiErrorKind.certificate => '서버의 보안 인증서를 확인할 수 없습니다.',
            ApiErrorKind.localNetworkDenied => _localNetworkMessage,
            ApiErrorKind.notBangmusic => '이 주소는 BangMusic 서버가 아닙니다.',
            _ => describeError(error).$1,
          };
      }
    });
  }

  Future<void> _login() async {
    final server = _server!;
    if (server.info.setupRequired) {
      setState(() => _error = '서버 설정이 끝나지 않았습니다. 서버에서 관리자 계정을 먼저 만드세요.');
      return;
    }
    _setBusy(true);
    setState(() => _error = null);
    final attempt = ++_attempt;
    try {
      await (widget.signIn ?? context.readApp().signIn)(server, _user.text.trim(), _pass.text);
      if (mounted && widget.asRoute) Navigator.of(context).pop();
    } catch (e) {
      final ae = ApiException.from(e);
      if (!mounted || attempt != _attempt) return;
      setState(() => _error = switch (ae.code) {
            'invalid_credentials' => '사용자 이름 또는 비밀번호가 올바르지 않습니다.',
            'account_disabled' => '비활성화된 계정입니다.',
            'rate_limited' => '로그인 시도가 너무 많습니다. ${ae.retryAfter ?? 60}초 뒤에 다시 시도하세요.',
            'setup_required' => '서버 설정이 끝나지 않았습니다.',
            'client_too_old' => '앱을 업데이트해야 합니다.',
            _ => describeError(ae).$1,
          });
    } finally {
      if (mounted && attempt == _attempt) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final server = _server;
    final app = context.watchApp();
    // 같은 주소인데 server_id가 다르다 (03장 §5.2): 이전 토큰은 보내지 않고 새 서버로 등록한다
    final replaced = server == null ? null : app.differentServerAt(server);
    final saved = [for (final p in app.profiles) if (p.serverId != app.profile?.serverId) p];
    return GlassScaffold(
      appBar: widget.asRoute ? GlassAppBar(title: const Text('서버 추가')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.xl),
          children: [
            const SizedBox(height: Space.xxl),
            Text(AppInfo.productName, style: context.text.displaySmall),
            const SizedBox(height: Space.sm),
            Text('내 음악 서버에 연결', style: context.text.titleLarge?.copyWith(color: c.textMuted)),
            const SizedBox(height: Space.xl),
            // 오프라인 (04장 S1): 저장된 서버가 있으면 받은 음악으로 계속할 수 있다
            if (!app.deviceOnline)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.lg),
                child: Row(children: [
                  Icon(Icons.cloud_off, color: c.textMuted),
                  const SizedBox(width: Space.sm),
                  const Expanded(child: Text('인터넷에 연결되어 있지 않습니다')),
                ]),
              ),
            if (server == null && saved.isNotEmpty && !widget.asRoute) ...[
              Text('저장된 서버', style: context.text.titleMedium),
              for (final p in saved)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dns),
                  title: Text(p.serverName),
                  subtitle: Text('${p.username} · ${p.baseUrl}${app.deviceOnline ? '' : '\n오프라인으로 계속 (받은 음악만)'}'),
                  onTap: _busy
                      ? null
                      : () async {
                          if (!await app.switchTo(p)) {
                            setState(() {
                              _address.text = p.baseUrl;
                              _user.text = p.username;
                            });
                          }
                        },
                ),
              const SizedBox(height: Space.lg),
            ],
            if (server == null) ...[
              TextField(
                controller: _address,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _check(),
                decoration: const InputDecoration(labelText: '서버 주소', hintText: 'https://music.example.net'),
              ),
            ] else ...[
              // ② 서버 확인 카드: 비밀번호 입력 전에 어느 서버인지 보여 준다
              // 큰 글씨에서는 "변경"을 아래 줄로 — 오른쪽에 두면 주소가 글자 단위로 쪼개졌다(상태 갤러리에서 발견)
              Card(
                child: Builder(builder: (context) {
                  final secure = server.baseUrl.startsWith('https');
                  final change = TextButton(onPressed: _busy ? null : () => setState(() => _server = null), child: const Text('변경'));
                  final big = context.textScale >= 1.5;
                  final tile = ListTile(
                    leading: Icon(secure ? Icons.lock : Icons.lock_open, color: secure ? c.success : c.warning),
                    title: Text(server.info.name),
                    subtitle: Text('${server.baseUrl}\n서버 ${server.info.version}${secure ? '' : ' · 보안 연결 아님(개발용)'}'),
                    isThreeLine: true,
                    trailing: big ? null : change,
                  );
                  return big ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [tile, change]) : tile;
                }),
              ),
              if (replaced != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.warning_amber, color: c.warning),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text('이 주소의 서버가 이전과 다릅니다(이전: ${replaced.serverName}). 서버를 다시 설치했거나 다른 서버일 수 있습니다. '
                        '새 서버로 등록하며, 이전 서버의 로그인 정보는 보내지 않고 다운로드는 그대로 둡니다.')),
                  ]),
                ),
              const SizedBox(height: Space.lg),
              TextField(controller: _user, enabled: !_busy, autocorrect: false, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username], decoration: const InputDecoration(labelText: '사용자 이름')),
              const SizedBox(height: Space.md),
              TextField(controller: _pass, enabled: !_busy, obscureText: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(), autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: '비밀번호')),
            ],
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              Semantics(liveRegion: true, child: Text(_error!, style: TextStyle(color: c.danger))),
              // 로컬 네트워크 권한 없음 (04장 S1, Android 17 타깃): 앱 설정 열기
              if (_error == _localNetworkMessage)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => const MethodChannel('bangmusic/storage').invokeMethod<void>('openAppSettings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('앱 설정 열기'),
                  ),
                ),
            ],
            const SizedBox(height: Space.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : (server == null ? _check : _login),
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: '확인 중'))
                    : Text(server == null ? '서버 확인' : '로그인'),
              ),
            ),
            if (_slow) ...[
              const SizedBox(height: Space.sm),
              Text('응답이 느립니다.', textAlign: TextAlign.center, style: TextStyle(color: c.textMuted)),
              // 취소 (04장 S1 로딩): 기다리던 응답은 늦게 와도 버린다.
              // 로그인 요청은 이미 서버에 갔을 수 있어, 늦게 성공하면 AppState가 그 계정으로 전환한다(사용자 본인의 입력이라 막지 않음)
              Center(
                child: TextButton(
                  onPressed: () {
                    _attempt++;
                    _setBusy(false);
                  },
                  child: const Text('취소'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
