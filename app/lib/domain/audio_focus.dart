// 오디오 포커스·통화·헤드셋 규칙 (03장 §6.5). 순수 Dart — 재생 엔진은 사건을 넘기고 결과만 실행한다.
// 통화 상태 권한(READ_PHONE_STATE)은 쓰지 않는다. 오디오 포커스와 오디오 모드(벨소리·통화)만 본다.
import 'playback_state.dart';

enum FocusEvent {
  /// 일시 상실 (전화 벨, 음성 비서, 알람)
  lossTransient,

  /// 덕킹 가능한 일시 상실 (내비 안내, 알림음). 단, 통화 중이면 일시 상실로 본다.
  lossDuck,

  /// 영구 상실 (다른 음악 앱)
  lossPermanent,

  /// 일시 상실이 끝남 (포커스 복귀)
  regained,

  /// 덕킹이 끝남
  duckEnded,

  /// 이어폰 분리·블루투스 끊김
  noisy,
}

sealed class FocusAction {
  const FocusAction();
}

class DoNothing extends FocusAction {
  const DoNothing();
}

class PauseFor extends FocusAction {
  const PauseFor(this.reason);
  final PauseReason reason;
}

class Duck extends FocusAction {
  const Duck();
}

class Unduck extends FocusAction {
  const Unduck();
}

/// 재개. [afterCall]이면 통화(벨소리 포함)가 끝날 때까지 기다린 뒤 재개한다.
class Resume extends FocusAction {
  const Resume({this.afterCall = false});
  final bool afterCall;
}

/// [inCall]: 기기 오디오 모드가 벨소리·통화·VoIP 통화 중
FocusAction decideFocus(FocusEvent e, {required bool playing, required PauseReason? reason, required bool ducked, required bool inCall}) {
  switch (e) {
    case FocusEvent.lossTransient:
      return playing ? const PauseFor(PauseReason.focusTransient) : const DoNothing();
    case FocusEvent.lossDuck:
      // 일부 기기(삼성)는 통화를 덕킹 신호로 보낸다. 통화 중 음악은 소리가 막힌 채 흘러가 버리므로 일시정지한다.
      if (inCall) return playing ? const PauseFor(PauseReason.focusTransient) : const DoNothing();
      return playing ? const Duck() : const DoNothing();
    case FocusEvent.lossPermanent:
      return playing ? const PauseFor(PauseReason.focusLoss) : const DoNothing();
    case FocusEvent.regained:
    case FocusEvent.duckEnded:
      if (ducked) return const Unduck();
      // 일시 상실로 멈춘 경우만 재개. 그 사이 사용자가 직접 멈췄으면(reason=user) 재개하지 않는다.
      if (shouldAutoResume(reason, focusRegained: true)) return Resume(afterCall: inCall);
      return const DoNothing();
    case FocusEvent.noisy:
      // 다시 연결돼도 자동 재개하지 않는다
      return playing ? const PauseFor(PauseReason.noisy) : const DoNothing();
  }
}
