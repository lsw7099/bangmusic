// S1 서버 연결 · 로그인 화면 (04장 S1) 위젯 테스트 (L1)
import 'dart:async';

import 'package:bangmusic/core/api_client.dart';
import 'package:bangmusic/core/session.dart';
import 'package:bangmusic/platform/playback_engine.dart';
import 'package:bangmusic/platform/secure_store.dart';
import 'package:bangmusic/ui/app_state.dart';
import 'package:bangmusic/ui/scope.dart';
import 'package:bangmusic/ui/screens/connect_screen.dart';
import 'package:bangmusic/ui/tokens.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ServerInfo info({bool setupRequired = false, int minClient = 0}) => ServerInfo(
      serverId: 'srv_T', name: '우리집 음악', product: ServerInfoProductEnum.bangmusicServer, version: '0.1.0',
      api: ServerInfoApi(major: 1, minor: 0), minClientApiMinor: minClient, features: const [], limits: const {}, setupRequired: setupRequired,
    );

Future<AppState> pump(WidgetTester t, Future<ProbeResult> Function(String) probe, {Future<void> Function(ProbeOk, String, String)? signIn}) async {
  final state = AppState(player: BangPlayer.forTest(), store: MemorySecureStore());
  await t.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(theme: buildTheme(Brightness.light), home: ConnectScreen(probe: probe, signIn: signIn)),
  ));
  return state;
}

Future<void> submitAddress(WidgetTester t, String address) async {
  await t.enterText(find.byType(TextField), address);
  await t.tap(find.text('서버 확인'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('빈 주소는 요청하지 않고 안내', (t) async {
    var called = false;
    await pump(t, (_) async {
      called = true;
      return ProbeOk(info(), 'x');
    });
    await t.tap(find.text('서버 확인'));
    await t.pumpAndSettle();
    expect(find.text('서버 주소를 입력하세요.'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('서버 확인 카드가 비밀번호 칸보다 먼저: 카드 전에는 비밀번호 칸이 없다', (t) async {
    String? asked;
    await pump(t, (u) async {
      asked = u;
      return ProbeOk(info(), u);
    });
    expect(find.text('비밀번호'), findsNothing);
    await submitAddress(t, 'music.example.net');
    expect(asked, 'https://music.example.net', reason: '스킴이 없으면 https');
    expect(find.text('우리집 음악'), findsOneWidget);
    expect(find.textContaining('https://music.example.net'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('"변경"을 누르면 주소 입력으로 돌아간다', (t) async {
    await pump(t, (u) async => ProbeOk(info(), u));
    await submitAddress(t, 'music.example.net');
    await t.tap(find.text('변경'));
    await t.pumpAndSettle();
    expect(find.text('비밀번호'), findsNothing);
    expect(find.text('서버 확인'), findsOneWidget);
  });

  testWidgets('오류 종류별 문구 (연결 불가·인증서·BangMusic 아님·앱 업데이트)', (t) async {
    final cases = <ProbeResult, String>{
      ProbeFailed(ApiException(kind: ApiErrorKind.unreachable)): '서버를 찾을 수 없습니다',
      ProbeFailed(ApiException(kind: ApiErrorKind.certificate)): '보안 인증서를 확인할 수 없습니다',
      ProbeFailed(ApiException(kind: ApiErrorKind.notBangmusic)): 'BangMusic 서버가 아닙니다',
      ProbeIncompatible(Incompatibility.appTooOld, info(minClient: 9)): '앱을 업데이트하세요',
      ProbeIncompatible(Incompatibility.serverTooOld, info()): '서버 업데이트가 필요합니다',
    };
    for (final MapEntry(key: result, value: text) in cases.entries) {
      await pump(t, (_) async => result);
      await submitAddress(t, 'music.example.net');
      expect(find.textContaining(text), findsOneWidget, reason: '$result');
      expect(find.text('비밀번호'), findsNothing, reason: '실패하면 비밀번호 칸을 보이지 않는다');
    }
  });

  testWidgets('초기 설정이 안 된 서버는 로그인 전에 막는다', (t) async {
    await pump(t, (u) async => ProbeOk(info(setupRequired: true), u));
    await submitAddress(t, 'music.example.net');
    await t.tap(find.text('로그인'));
    await t.pumpAndSettle();
    expect(find.textContaining('서버 설정이 끝나지 않았습니다'), findsOneWidget);
  });

  testWidgets('큰 글씨(배율 2.0)에서도 넘침 없이 그린다', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(t, (u) async => ProbeOk(info(), u));
    await submitAddress(t, 'music.example.net');
    expect(t.takeException(), isNull);
    // 버튼이 화면 밖으로 밀려나도 세로 스크롤로 닿을 수 있어야 한다 (04장 §5)
    await t.scrollUntilVisible(find.text('로그인'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('로그인'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('로컬 네트워크 권한이 없으면(Android 17 타깃) 권한 안내 + 앱 설정 열기 (04장 S1)', (t) async {
    await pump(t, (_) async => ProbeFailed(ApiException(kind: ApiErrorKind.localNetworkDenied)));
    await submitAddress(t, 'http://192.168.0.10:8080');
    expect(find.textContaining('집 안 네트워크의 서버에 연결하려면 권한이 필요합니다'), findsOneWidget);
    expect(find.text('앱 설정 열기'), findsOneWidget);
  });

  testWidgets('로그인 실패 문구: 비밀번호 틀림, 5회 실패 후 대기 시간(Retry-After) (04장 S1)', (t) async {
    ApiException next = ApiException(kind: ApiErrorKind.server, status: 401, code: 'invalid_credentials');
    await pump(t, (_) async => ProbeOk(info(), 'https://music.example.net'), signIn: (_, _, _) async => throw next);
    await submitAddress(t, 'music.example.net');
    await t.enterText(find.byType(TextField).at(0), 'siwon');
    await t.enterText(find.byType(TextField).at(1), 'x');
    await t.tap(find.text('로그인'));
    await t.pumpAndSettle();
    expect(find.text('사용자 이름 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    next = ApiException(kind: ApiErrorKind.server, status: 429, code: 'rate_limited', retryAfter: 300);
    await t.tap(find.text('로그인'));
    await t.pumpAndSettle();
    expect(find.text('로그인 시도가 너무 많습니다. 300초 뒤에 다시 시도하세요.'), findsOneWidget);
  });

  testWidgets('오프라인이면 안내하고, 저장된 서버는 오프라인으로 계속할 수 있다 (04장 S1)', (t) async {
    final state = AppState(player: BangPlayer.forTest(), store: MemorySecureStore())
      ..profiles = [const ServerProfile(serverId: 'srv_B', baseUrl: 'http://192.168.0.10:8080', serverName: '집 서버', userId: 'u', username: 'siwon', installationId: 'i')]
      ..deviceOnline = false;
    await t.pumpWidget(AppScope(state: state, child: MaterialApp(theme: buildTheme(Brightness.light), home: ConnectScreen(probe: (_) async => throw StateError('호출되면 안 됨')))));
    expect(find.text('인터넷에 연결되어 있지 않습니다'), findsOneWidget);
    expect(find.textContaining('오프라인으로 계속'), findsOneWidget);
  });

  testWidgets('10초 넘으면 "응답이 느립니다" + 취소, 취소하면 늦은 응답은 버린다 (04장 S1)', (t) async {
    final c = Completer<ProbeResult>();
    await pump(t, (_) => c.future);
    await t.enterText(find.byType(TextField), 'music.example.net');
    await t.tap(find.text('서버 확인'));
    await t.pump(const Duration(seconds: 11));
    expect(find.text('응답이 느립니다.'), findsOneWidget);
    await t.tap(find.text('취소'));
    await t.pump();
    expect(find.text('서버 확인'), findsOneWidget, reason: '입력으로 돌아온다');
    c.complete(ProbeOk(info(), 'https://music.example.net'));
    await t.pumpAndSettle();
    expect(find.text('우리집 음악'), findsNothing, reason: '취소한 뒤 온 응답으로 카드를 띄우지 않는다');
  });
}
