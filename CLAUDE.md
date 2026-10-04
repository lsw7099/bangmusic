# BangMusic 서버 · 모바일 — Claude Code 작업 지침

이 저장소에는 자가호스팅 음악 서버와 Android(향후 iOS) 앱의 **구현 전 설계**가 `docs/design/`에 있다. 동작하는 서버·앱 코드는 아직 없다.

## 먼저 읽을 것

1. `docs/design/README.md` — 문서 구성, 확정 전제, 미결 항목(§4), 확인하지 못한 점(§5)
2. `docs/design/01-architecture.md` — 기술 선택, 데이터 모델
3. `docs/design/openapi.yaml` + `02-api-guide.md` — API 계약(계약이 다르면 yaml이 기준)
4. `docs/design/03-streaming-offline-playback.md` — 스트리밍, 다운로드 상태 기계, 재생 상태
5. `docs/design/04-mobile-ui-spec.md` — 화면·상태·토큰
6. `docs/design/05-commercial-deploy-plan.md` — 테스트 목록(SEC-*, FN-*), 단계(P0~P8)와 수용 기준

## 작업 규칙

- 구현 순서는 05장 §10.3의 P0부터. 앞 단계의 수용 기준을 통과하기 전에 다음 단계로 넘어가지 않는다.
- 완료 보고에는 통과한 수용 기준 번호와 **검증 수준(L0~L4, 05장 §9.4)** 을 적는다. 로컬 테스트 성공을 실서버·실기기 성공으로 표시하지 않는다.
- README §4의 미결 항목은 임의로 확정하지 않는다. 해당 단계에 도달하면 사용자에게 묻는다. P3 시작 전에 필요한 것: 제품명·패키지 ID, minSdk, OpenSubsonic 호환 여부.
- 문서의 `[확인 필요]` 항목은 가정이다. 확인한 결과로 문서를 갱신한다.
- 설계에서 벗어나야 하면 코드보다 먼저 설계 문서를 고치고 이유를 남긴다.
- HTTP 응답·로그에 서버 파일 경로, 토큰, 비밀번호, 미디어 티켓 값을 넣지 않는다.
- 음악 원본 경로에는 쓰지 않는다. 테스트에는 `tools/make-fixtures`로 만든 합성 음원만 쓴다(실제 음원을 저장소에 넣지 않는다).
- 기존 Windows BangMusic의 IPC·mpv 제어 코드와 경로 해시 ID는 가져오지 않는다. `lyrics-core.js`와 셔플/반복·재생 기록 테스트는 동작 기준으로 이식하며, 설계의 제안 규칙과 다르면 기존 테스트가 우선한다(03장 §6.3).
- 앱은 구매자의 서버와 스토어 외에는 통신하지 않는다. 분석·오류 보고 SDK를 임의로 추가하지 않는다.

## 첫 작업 (P0)

저장소 골격(`server/`, `app/`, `tools/`, `docs/design/`), OpenAPI 린트 CI, OpenAPI에서 클라이언트·서버 스키마 생성, 합성 음원 생성기, 개발 환경 점검(Node LTS, FFmpeg, Docker, Flutter). 설계 단계에서는 표준 OpenAPI 린터를 실행하지 못했으므로 P0에서 반드시 돌리고 결과를 반영한다.
