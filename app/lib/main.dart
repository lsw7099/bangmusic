// BangMusic 앱 진입점.
// 구조 (01장 §3.3): core/ API·세션, domain/ 순수 로직, platform/ 재생·보안 저장소, ui/ 화면.
import 'package:flutter/material.dart';

import 'core/app_info.dart';
import 'core/session.dart';
import 'platform/playback_engine.dart';
import 'ui/app_state.dart';
import 'ui/scope.dart';
import 'ui/screens/connect_screen.dart';
import 'ui/shell.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final player = await BangPlayer.create();
  final state = AppState(player: player, services: AppServices.platform());
  runApp(AppScope(state: state, child: const BangMusicApp()));
  await state.load();
}

class BangMusicApp extends StatelessWidget {
  const BangMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    final Widget home;
    if (!app.ready) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (app.api == null) {
      home = const ConnectScreen();
    } else if (app.session == SessionStatus.revoked) {
      home = const _AccessRevoked();
    } else {
      // 서버(프로필)가 바뀌면 탭 화면 전체를 새로 만든다 — 이전 서버에서 받은 화면 내용이 남아 섞이지 않게 (FN-21, 실기기에서 발견)
      home = Shell(key: ValueKey('${app.profile?.serverId}/${app.profile?.userId}'));
    }
    return MaterialApp(
      title: AppInfo.productName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: app.prefs.themeMode, // 시스템/라이트/다크 (04장 S10)
      home: home,
    );
  }
}

/// 접근 취소 (04장 §5): session_revoked / account_disabled
class _AccessRevoked extends StatelessWidget {
  const _AccessRevoked();
  @override
  Widget build(BuildContext context) {
    final app = context.watchApp();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.no_accounts, size: 64, color: context.colors.danger),
            const SizedBox(height: Space.lg),
            Text('이 기기의 접근이 취소되었습니다', style: context.text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text('서버 관리자가 세션을 취소했거나 계정이 비활성화되었습니다.\n이 기기의 다운로드는 잠겼습니다. 같은 계정으로 다시 로그인하면 풀립니다.',
                textAlign: TextAlign.center, style: TextStyle(color: context.colors.textMuted)),
            const SizedBox(height: Space.xl),
            // 03장 §5.8: 접근 취소는 삭제가 아니라 잠금 — 다시 로그인하면 전부 다시 받지 않아도 된다
            FilledButton(onPressed: () => app.signOut(keepDownloads: true), child: const Text('다시 로그인')),
            const SizedBox(height: Space.sm),
            TextButton(onPressed: () => app.signOut(), child: const Text('이 기기에서 다운로드 삭제')),
          ]),
        ),
      ),
    );
  }
}
