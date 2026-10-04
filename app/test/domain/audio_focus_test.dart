// 03장 §6.5 오디오 포커스·통화·헤드셋 규칙 (L0)
import 'package:bangmusic/domain/audio_focus.dart';
import 'package:bangmusic/domain/playback_state.dart';
import 'package:flutter_test/flutter_test.dart';

FocusAction d(FocusEvent e, {bool playing = true, PauseReason? reason, bool ducked = false, bool inCall = false}) =>
    decideFocus(e, playing: playing, reason: reason, ducked: ducked, inCall: inCall);

void main() {
  test('전화 벨(일시 상실) → focus_transient로 일시정지', () {
    expect((d(FocusEvent.lossTransient) as PauseFor).reason, PauseReason.focusTransient);
  });

  test('통화를 덕킹 신호로 보내는 기기: 통화 중이면 덕킹 대신 일시정지 (실기기 SM-S948N에서 발견)', () {
    expect((d(FocusEvent.lossDuck, inCall: true) as PauseFor).reason, PauseReason.focusTransient);
    expect(d(FocusEvent.lossDuck), isA<Duck>(), reason: '통화가 아니면 내비 안내처럼 볼륨만 낮춘다');
  });

  test('포커스가 돌아와도 아직 통화 중이면 통화가 끝난 뒤 재개', () {
    final r = d(FocusEvent.regained, playing: false, reason: PauseReason.focusTransient, inCall: true) as Resume;
    expect(r.afterCall, isTrue);
    expect((d(FocusEvent.regained, playing: false, reason: PauseReason.focusTransient) as Resume).afterCall, isFalse);
  });

  test('통화 중 덕킹으로 멈춘 경우 덕킹이 끝나면 재개', () {
    expect(d(FocusEvent.duckEnded, playing: false, reason: PauseReason.focusTransient), isA<Resume>());
  });

  test('그 사이 사용자가 직접 멈췄으면 재개하지 않는다', () {
    expect(d(FocusEvent.regained, playing: false, reason: PauseReason.user), isA<DoNothing>());
  });

  test('다른 음악 앱(영구 상실) → focus_loss, 돌아와도 재개 안 함', () {
    expect((d(FocusEvent.lossPermanent) as PauseFor).reason, PauseReason.focusLoss);
    expect(d(FocusEvent.regained, playing: false, reason: PauseReason.focusLoss), isA<DoNothing>());
  });

  test('이어폰 분리 → noisy, 재개 안 함', () {
    expect((d(FocusEvent.noisy) as PauseFor).reason, PauseReason.noisy);
    expect(d(FocusEvent.regained, playing: false, reason: PauseReason.noisy), isA<DoNothing>());
  });

  test('덕킹 해제는 볼륨 복구', () {
    expect(d(FocusEvent.duckEnded, ducked: true), isA<Unduck>());
  });

  test('멈춰 있을 때 상실 사건은 무시 (사유를 덮어쓰지 않는다)', () {
    for (final e in [FocusEvent.lossTransient, FocusEvent.lossDuck, FocusEvent.lossPermanent, FocusEvent.noisy]) {
      expect(d(e, playing: false, reason: PauseReason.user), isA<DoNothing>(), reason: '$e');
    }
  });
}
