// 재생 상태 모델 (03장 §6.1). 일시정지 사유를 저장한다 — 자동 재개 여부가 사유에 달려 있다(§6.5).

enum PlaybackStatus { idle, loading, playing, buffering, paused, ended, error }

enum PauseReason { user, focusLoss, focusTransient, noisy, error }

/// 오디오 포커스 사건 후 자동 재개할지 (03장 §6.5)
bool shouldAutoResume(PauseReason? reason, {required bool focusRegained}) =>
    focusRegained && reason == PauseReason.focusTransient;

/// 재생 불가 연속 건너뛰기 한도 (03장 §6.4): 연속 5곡 또는 대기열 한 바퀴
class SkipGuard {
  SkipGuard(this.queueLength);
  int queueLength;
  int _consecutive = 0;

  /// 재생 불가 곡을 하나 건너뛴 뒤 호출. 더 건너뛰면 안 되면 true(정지하고 사유를 한 번 알린다).
  bool skippedShouldStop() {
    _consecutive++;
    return _consecutive >= 5 || (queueLength > 0 && _consecutive >= queueLength);
  }

  void played() => _consecutive = 0;
}
