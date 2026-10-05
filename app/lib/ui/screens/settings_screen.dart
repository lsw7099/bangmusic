// S10 설정 (04장 S10): 서버 · 재생 · 다운로드 · 가사 · 화면 · 개인정보 · 앱.
// 오프라인이면 서버가 필요한 항목(세션, 비밀번호, 기록·계정 삭제, 내보내기)은 비활성 + "온라인에서 사용할 수 있습니다".
// 세션 만료면 서버 구획 맨 위에 "다시 로그인". 큰 글씨에서 항목 값은 제목 아래 줄(ListTile 기본).
import 'dart:convert';
import 'dart:io';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../core/app_info.dart';
import '../../core/session.dart';
import '../app_prefs.dart';
import '../app_state.dart';
import '../glass.dart';
import '../scope.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';
import '../widgets/relogin_sheet.dart';
import 'connect_screen.dart';
import 'download_screens.dart';
import 'purchase_screen.dart';
import '../../platform/store_port.dart';

const _onlineOnly = '온라인에서 사용할 수 있습니다';
const _platform = MethodChannel('bangmusic/storage');

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final p = app.profile;
    final s = app.downloadSettings;
    final prefs = app.prefs;
    // 서버가 필요한 항목은 서버에 닿을 때만 (로컬 DB 유무와 무관)
    final online = app.connection == Connection.online && !app.serverChanged;
    final others = [for (final x in app.profiles) if (x.serverId != p?.serverId) x];
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('설정')),
      body: ListView(children: glassGroups([
        // ── 서버
        const _Title('서버'),
        if (app.session == SessionStatus.expired)
          ListTile(
            leading: Icon(Icons.lock_clock, color: context.colors.warning),
            title: const Text('다시 로그인'),
            subtitle: const Text('세션이 만료되었습니다. 받은 음악은 계속 들을 수 있습니다'),
            onTap: () => showReloginSheet(context),
          ),
        if (p != null) _ServerTile(profile: p),
        if (p != null) ListTile(leading: const Icon(Icons.person), title: Text(p.displayName ?? p.username), subtitle: Text(p.username)),
        for (final o in others)
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(o.serverName),
            subtitle: Text('${o.username} · ${o.baseUrl}'),
            onTap: () async {
              final ok = await app.switchTo(o);
              if (!context.mounted) return;
              if (ok) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              } else {
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ConnectScreen(initialAddress: o.baseUrl, asRoute: true)));
              }
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '${o.serverName} 서버 삭제',
              onPressed: () async {
                if (await _confirm(context, '${o.serverName} 서버를 삭제할까요?', '이 기기에 저장된 그 서버의 로그인 정보와 받은 음악을 지웁니다. 서버의 데이터는 그대로입니다.', '삭제')) {
                  await app.removeProfile(o);
                }
              },
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('서버 추가'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ConnectScreen(asRoute: true))),
        ),
        ListTile(
          leading: const Icon(Icons.devices),
          title: const Text('내 기기 세션'),
          subtitle: Text(online ? '로그인한 기기 목록과 끊기' : _onlineOnly),
          enabled: online,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SessionsScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('비밀번호 변경'),
          subtitle: Text(online ? '바꾸면 이 기기 외의 세션은 모두 끊깁니다' : _onlineOnly),
          enabled: online,
          onTap: () => _changePassword(context),
        ),
        ListTile(
          leading: Icon(Icons.logout, color: context.colors.danger),
          title: const Text('로그아웃'),
          subtitle: const Text('이 기기의 세션을 끝냅니다'),
          onTap: () => _logout(context),
        ),

        // ── 재생
        const _Title('재생'),
        _Choice(
          icon: Icons.wifi, title: 'Wi-Fi 스트리밍 음질', value: prefs.streamQualityWifi,
          options: const ['original', 'aac_256', 'aac_128'], label: qualityLabel,
          onChanged: (v) => prefs.update(streamQualityWifi: v),
        ),
        _Choice(
          icon: Icons.signal_cellular_alt, title: '셀룰러 스트리밍 음질', value: prefs.streamQualityCellular,
          options: const ['original', 'aac_256', 'aac_128'], label: qualityLabel,
          onChanged: (v) => prefs.update(streamQualityCellular: v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.network_cell),
          title: const Text('셀룰러에서 스트리밍 허용'),
          subtitle: const Text('끄면 모바일 데이터에서는 받은 곡만 재생합니다'),
          value: prefs.allowCellularStreaming,
          onChanged: (v) => prefs.update(allowCellularStreaming: v),
        ),
        const _BackgroundDiagnostics(),

        // ── 다운로드
        if (app.downloads != null) ...[
          const _Title('다운로드'),
          _Choice(
            icon: Icons.high_quality, title: '다운로드 음질', value: s.quality, options: const ['original', 'aac_256', 'aac_128'], label: qualityLabel,
            onChanged: (v) => app.setDownloadSettings(quality: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Wi-Fi에서만 받기'),
            subtitle: const Text('모바일 데이터로는 받지 않습니다'),
            value: s.wifiOnly,
            onChanged: (v) => app.setDownloadSettings(wifiOnly: v),
          ),
          _Choice(
            icon: Icons.stacked_line_chart, title: '동시 다운로드 수', value: '${s.concurrency}', options: const ['1', '2', '3', '4'], label: (v) => '$v개',
            onChanged: (v) => app.setDownloadSettings(concurrency: int.parse(v)),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('다운로드 저장 한도'),
            subtitle: Text(s.limitBytes == null ? '제한 없음' : formatBytes(s.limitBytes)),
            onTap: () async {
              final mb = await showDialog<int>(
                context: context,
                builder: (d) => SimpleDialog(title: const Text('저장 한도'), children: [
                  for (final (label, v) in [('제한 없음', -1), if (kDebugMode) ('10 MB (시험용, 디버그 빌드만)', 10), ('2 GB', 2048), ('5 GB', 5120), ('10 GB', 10240), ('20 GB', 20480), ('50 GB', 51200)])
                    SimpleDialogOption(onPressed: () => Navigator.pop(d, v), child: Text(label)),
                ]),
              );
              if (mb == null) return;
              await app.setDownloadSettings(limitMb: mb < 0 ? null : mb, clearLimit: mb < 0);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('다운로드 자동 업데이트'),
            subtitle: const Text('서버의 곡 파일이 바뀌면 새 버전을 받고 옛 파일을 지웁니다'),
            value: s.autoUpdate,
            onChanged: (v) => app.setDownloadSettings(autoUpdate: v),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.lg),
            child: Text('한도를 넘으면 새 다운로드만 기다립니다. 받아 둔 음악을 자동으로 지우지 않습니다.'),
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: context.colors.danger),
            title: const Text('모든 다운로드 삭제'),
            onTap: () async {
              final n = app.downloads!.rows.value.length;
              if (n == 0) return;
              if (await _confirm(context, '이 기기의 다운로드 $n곡을 모두 삭제할까요?', '서버의 음악은 그대로입니다. 다시 받으려면 앨범·플레이리스트에서 다운로드 버튼을 누르세요.', '모두 삭제')) {
                await app.downloads!.deleteAll();
              }
            },
          ),
        ],

        // ── 가사
        const _Title('가사'),
        SwitchListTile(
          secondary: const Icon(Icons.translate),
          title: const Text('한글 발음 줄 기본 표시'),
          value: prefs.lyricsPronunciation,
          onChanged: (v) => prefs.update(lyricsPronunciation: v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.g_translate),
          title: const Text('번역 줄 기본 표시'),
          value: prefs.lyricsTranslation,
          onChanged: (v) => prefs.update(lyricsTranslation: v),
        ),
        ListTile(
          leading: const Icon(Icons.format_size),
          title: const Text('가사 글자 크기'),
          subtitle: Slider(
            value: prefs.lyricsScale, min: 0.8, max: 1.6, divisions: 8,
            label: '${(prefs.lyricsScale * 100).round()}%',
            semanticFormatterCallback: (v) => '${(v * 100).round()}퍼센트',
            onChanged: (v) => prefs.update(lyricsScale: v),
          ),
        ),

        // ── 화면
        const _Title('화면'),
        _Choice(
          icon: Icons.brightness_6, title: '테마', value: prefs.themeMode.name, options: const ['system', 'light', 'dark'],
          label: (v) => switch (v) { 'light' => '라이트', 'dark' => '다크', _ => '시스템 설정 따름' },
          onChanged: (v) => prefs.update(themeMode: ThemeMode.values.byName(v)),
        ),
        // 04장 §3.4: 유리 대신 불투명 면, 흐림 없음 (읽기 쉬움·저사양 기기)
        SwitchListTile(
          secondary: const Icon(Icons.blur_off),
          title: const Text('투명도 줄이기'),
          subtitle: const Text('유리 효과 대신 불투명한 면을 씁니다'),
          value: prefs.reduceTransparency,
          onChanged: (v) => prefs.update(reduceTransparency: v),
        ),

        // ── 개인정보
        const _Title('개인정보'),
        ListTile(
          leading: const Icon(Icons.history_toggle_off),
          title: const Text('재생 기록 삭제 (서버)'),
          subtitle: Text(online ? '최근·많이 들은 곡 기록이 지워집니다' : _onlineOnly),
          enabled: online,
          onTap: () async {
            if (!await _confirm(context, '재생 기록을 삭제할까요?', '서버에 저장된 이 계정의 재생 기록이 모두 지워집니다. 되돌릴 수 없습니다.', '삭제') || !context.mounted) return;
            await _guard(context, () => app.api!.call((x) => x.getHistoryApi().deleteHistory()), done: '재생 기록을 삭제했습니다');
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('내 데이터 내보내기'),
          subtitle: Text(online ? '플레이리스트와 재생 기록 (JSON)' : _onlineOnly),
          enabled: online,
          onTap: () => _export(context),
        ),
        ListTile(
          leading: Icon(Icons.person_remove, color: context.colors.danger),
          title: const Text('서버 계정 삭제'),
          subtitle: Text(online ? '이 서버의 내 계정과 플레이리스트·기록을 지웁니다' : _onlineOnly),
          enabled: online,
          onTap: () => _deleteAccount(context),
        ),
        const ListTile(leading: Icon(Icons.policy_outlined), title: Text('개인정보 처리방침'), subtitle: Text('출시 전 준비 (P7). 앱은 내 서버와 스토어 외에는 통신하지 않습니다')),

        // ── 앱
        const _Title('앱'),
        ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: const Text('구매 상태 · 구매 복원'),
          subtitle: Text(switch (app.entitlement.state) {
            PurchaseState.purchased => '구매함',
            PurchaseState.pending => '결제 보류 중',
            PurchaseState.notPurchased => '구매하지 않음 · 다운로드는 구매 후',
          }),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PurchaseScreen())),
        ),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('버전'), subtitle: Text('${AppInfo.productName} ${AppInfo.appVersion} (API 1.${AppInfo.apiMinorBuilt})')),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('오픈소스 고지'),
          onTap: () => showLicensePage(context: context, applicationName: AppInfo.productName, applicationVersion: AppInfo.appVersion),
        ),
        ListTile(
          leading: const Icon(Icons.copy_all),
          title: const Text('진단 정보 복사'),
          subtitle: const Text('문의할 때 붙여 넣으세요. 토큰·서버 주소는 넣지 않습니다'),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: await _diagnostics(app)));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('진단 정보를 복사했습니다')));
          },
        ),
        const SizedBox(height: Space.xxl),
      ], (w) => w is _Title)),
    );
  }

  /// 03장 §5.8 · 04장 S10: 기본은 이 기기의 다운로드 삭제, "보관"은 잠가서 남긴다(같은 사용자로 로그인하면 해제)
  Future<void> _logout(BuildContext context) async {
    final app = context.readApp();
    final rows = app.downloads?.rows.value ?? const [];
    final size = rows.fold<int>(0, (s, d) => s + (d.bytesTotal ?? 0));
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        content: rows.isEmpty
            ? null
            : Text('이 기기의 다운로드 ${rows.length}곡(${formatBytes(size)})을 삭제합니다.\n보관하면 다시 로그인할 때까지 재생할 수 없고, 같은 계정으로 로그인하면 풀립니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('취소')),
          if (rows.isNotEmpty) TextButton(onPressed: () => Navigator.pop(d, 'keep'), child: const Text('다운로드 보관')),
          FilledButton(onPressed: () => Navigator.pop(d, 'delete'), child: Text(rows.isNotEmpty ? '다운로드 삭제 후 로그아웃' : '로그아웃')),
        ],
      ),
    );
    if (choice == null) return;
    await app.signOut(keepDownloads: choice == 'keep');
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _changePassword(BuildContext context) async {
    final app = context.readApp();
    final done = await showFormDialog(context, title: '비밀번호 변경', submitLabel: '변경', fields: const [
      DialogField('현재 비밀번호', obscure: true),
      DialogField('새 비밀번호 (10자 이상)', obscure: true),
      DialogField('새 비밀번호 확인', obscure: true),
    ], onSubmit: (v) async {
      if (v[1].length < 10) return '새 비밀번호는 10자 이상이어야 합니다';
      if (v[1] != v[2]) return '새 비밀번호가 서로 다릅니다';
      try {
        await app.api!.call((x) => x.getMeApi().changePassword(changePasswordRequest: ChangePasswordRequest(currentPassword: v[0], newPassword: v[1])));
        return null;
      } catch (e) {
        final ae = ApiException.from(e);
        return ae.status == 400 ? '현재 비밀번호가 맞지 않습니다' : describeError(ae).$1;
      }
    });
    if (done != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호를 바꿨습니다. 다른 기기는 다시 로그인해야 합니다')));
    }
  }

  Future<void> _export(BuildContext context) async {
    final app = context.readApp();
    await _guard(context, () async {
      final r = await app.api!.dio.get<Map<String, dynamic>>('/me/export');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/bangmusic-export-${DateTime.now().toIso8601String().substring(0, 10)}.json');
      await f.writeAsString(const JsonEncoder.withIndent('  ').convert(r.data));
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/json')], subject: 'BangMusic 내 데이터'));
    });
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final app = context.readApp();
    final v = await showFormDialog(context,
        title: '서버 계정을 삭제할까요?',
        submitLabel: '계정 삭제',
        destructive: true,
        message: const Text('이 서버의 내 계정, 플레이리스트, 재생 기록이 지워집니다. 서버의 음악 파일은 그대로입니다. 되돌릴 수 없습니다.'),
        fields: const [DialogField('비밀번호 확인', obscure: true)]);
    if (v == null || !context.mounted) return;
    final password = v[0];
    try {
      await app.api!.call((x) => x.getMeApi().deleteMe(deleteMeRequest: DeleteMeRequest(password: password)));
      await app.signOut(); // 세션이 모두 끝났다 — 이 기기의 사본도 지운다
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      final ae = ApiException.from(e);
      if (!context.mounted) return;
      final msg = switch (ae.code) {
        'invalid_credentials' => '비밀번호가 맞지 않습니다',
        'last_admin' => '서버의 마지막 관리자 계정은 삭제할 수 없습니다',
        _ => describeError(ae).$1,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// 토큰·서버 주소·사용자 이름 없이 (04장 S10)
  static Future<String> _diagnostics(AppState app) async {
    final rows = app.downloads?.rows.value ?? const [];
    final byState = <String, int>{};
    for (final d in rows) {
      byState[d.state.wire] = (byState[d.state.wire] ?? 0) + 1;
    }
    return [
      '${AppInfo.productName} ${AppInfo.appVersion} (API 1.${AppInfo.apiMinorBuilt})',
      'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      '서버 프로필 ${app.profiles.length}개, 세션 ${app.session.name}, 연결 ${app.connection.name}${app.serverChanged ? ', 서버 변경 감지' : ''}',
      '다운로드 ${rows.length}곡 $byState',
      '설정: Wi-Fi만=${app.downloadSettings.wifiOnly}, 동시=${app.downloadSettings.concurrency}, 한도=${app.downloadSettings.limitBytes == null ? '없음' : formatBytes(app.downloadSettings.limitBytes)}, 자동 업데이트=${app.downloadSettings.autoUpdate}',
    ].join('\n');
  }
}

Future<bool> _confirm(BuildContext context, String title, String body, String action) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(action))],
      ),
    ) ??
    false;

/// 서버 호출: 실패하면 항목 단위 오류 문구 (04장 S10 오류)
Future<void> _guard(BuildContext context, Future<void> Function() f, {String? done}) async {
  try {
    await f();
    if (done != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(ApiException.from(e)).$1)));
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.xs),
          child: Text(text, style: context.text.titleSmall?.copyWith(color: context.colors.accent)),
        ),
      );
}

/// 값 고르기 항목: 현재 값은 제목 아래, 누르면 선택 대화상자
class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.value, required this.options, required this.label, required this.onChanged});
  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final String Function(String) label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(label(value)),
        onTap: () async {
          final v = await showDialog<String>(
            context: context,
            builder: (d) => SimpleDialog(title: Text(title), children: [
              for (final o in options)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(d, o),
                  child: Row(children: [
                    Icon(o == value ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20),
                    const SizedBox(width: Space.md),
                    Expanded(child: Text(label(o))),
                  ]),
                ),
            ]),
          );
          if (v != null && v != value) onChanged(v);
        },
      );
}

/// 현재 서버: 이름, 주소, 서버 버전, 연결 상태 (04장 S10)
class _ServerTile extends StatefulWidget {
  const _ServerTile({required this.profile});
  final ServerProfile profile;
  @override
  State<_ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<_ServerTile> {
  late final Future<ServerInfo?> _info = context.readApp().api!.call((x) => x.getServerApi().getServerInfo()).then<ServerInfo?>((v) => v).catchError((Object _) => null);

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final state = switch (app.connection) {
      Connection.online when app.serverChanged => '서버가 이전과 다름',
      Connection.online => app.session == SessionStatus.expired ? '로그인 필요' : '연결됨',
      Connection.deviceOffline => '오프라인',
      Connection.serverUnreachable => '서버에 연결할 수 없음',
    };
    return FutureBuilder<ServerInfo?>(
      future: _info,
      builder: (_, s) => ListTile(
        leading: const Icon(Icons.dns),
        title: Text(widget.profile.serverName),
        subtitle: Text([widget.profile.baseUrl, if (s.data != null) '서버 ${s.data!.version}', state].join('\n')),
        isThreeLine: true,
      ),
    );
  }
}

/// 백그라운드 재생 진단 (04장 S10): 배터리 최적화 때문에 OS가 재생 서비스를 멈추는지
class _BackgroundDiagnostics extends StatefulWidget {
  const _BackgroundDiagnostics();
  @override
  State<_BackgroundDiagnostics> createState() => _BackgroundDiagnosticsState();
}

class _BackgroundDiagnosticsState extends State<_BackgroundDiagnostics> with WidgetsBindingObserver {
  bool? _ignored;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check(); // 설정에서 돌아오면 다시 확인
  }

  Future<void> _check() async {
    if (!Platform.isAndroid) return;
    try {
      final v = await _platform.invokeMethod<bool>('batteryOptimizationIgnored');
      if (mounted) setState(() => _ignored = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ok = _ignored == true;
    return ListTile(
      leading: Icon(ok ? Icons.battery_full : Icons.battery_alert, color: ok ? context.colors.success : context.colors.warning),
      title: const Text('백그라운드 재생 진단'),
      subtitle: Text(switch (_ignored) {
        null => '확인할 수 없습니다',
        true => '배터리 최적화 예외 — 화면을 꺼도 재생이 끊기지 않습니다',
        false => '배터리 최적화 대상입니다. 화면을 끈 뒤 재생이 멈추면 앱 설정 → 배터리에서 "제한 없음"을 고르세요',
      }),
      onTap: ok || !Platform.isAndroid ? null : () => _platform.invokeMethod<void>('openAppSettings'),
    );
  }
}

/// 내 기기 세션 (04장 S10): 목록과 다른 기기 끊기
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late Future<List<Session>> _f = _load();

  // FutureBuilder가 듣기 전에 실패해도 '처리 안 된 오류'로 올라가지 않게 ignore()
  Future<List<Session>> _load() => (() async => (await context.readApp().api!.call((x) => x.getAuthApi().listSessions())).items)()..ignore();

  @override
  Widget build(BuildContext context) {
    final api = context.readApp().api!;
    return GlassScaffold(
      appBar: GlassAppBar(title: const Text('내 기기 세션')),
      body: FutureBuilder<List<Session>>(
        future: _f,
        builder: (context, s) {
          if (s.hasError) return ErrorState(error: s.error!, onRetry: () => setState(() { _f = _load(); }));
          if (!s.hasData) return const SkeletonList();
          final items = s.data!..sort((a, b) => (b.current ? 1 : 0).compareTo(a.current ? 1 : 0));
          return ListView(children: [
            for (final x in items)
              ListTile(
                leading: Icon(x.platform == 'android' ? Icons.phone_android : Icons.devices_other),
                title: Text(x.current ? '${x.deviceName} (이 기기)' : x.deviceName),
                subtitle: Text('마지막 사용 ${x.lastSeenAt.toLocal().toString().substring(0, 16)}${x.appVersion == null ? '' : ' · 앱 ${x.appVersion}'}'),
                trailing: x.current
                    ? null
                    : TextButton(
                        onPressed: () async {
                          if (!await _confirm(context, '${x.deviceName} 세션을 끊을까요?', '그 기기는 다시 로그인해야 하며, 받아 둔 음악은 그 기기에서 잠깁니다.', '끊기')) return;
                          if (!context.mounted) return;
                          await _guard(context, () => api.call((a) => a.getAuthApi().revokeSession(sessionId: x.id)), done: '세션을 끊었습니다');
                          setState(() { _f = _load(); });
                        },
                        child: const Text('끊기'),
                      ),
              ),
            if (items.length <= 1) const Padding(padding: EdgeInsets.all(Space.lg), child: Text('다른 기기 없음')),
          ]);
        },
      ),
    );
  }
}
