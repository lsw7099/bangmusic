# 인수인계 (2026-10-04) — 다음 에이전트용

이 문서만 읽고 이어서 일할 수 있게 쓴다. **사용자에게는 항상 한국어로 답한다**(영어로 답하면 여러 번 "한글로" 요청함).

## Task

BangMusic 서버·앱 구현을 이어서 한다. 지금은 **P6(Proxmox 배포 검증) 진행 중**이다. 서버 쪽 L2 시험과 설치 문서는 끝났고, 남은 것은 사용자와 함께하는 실기기(L3) 시험과 사용자 결정이 필요한 항목이다. P6 수용 기준을 모두 통과하기 전에는 P7로 넘어가지 않는다.

## 먼저 읽을 것

1. `CLAUDE.md` — 작업 규칙(단계 순서, 검증 수준 L0~L4 표기, 미결 항목 임의 확정 금지, 로그·응답에 경로·토큰 금지, 음악 원본에 쓰기 금지 등)
2. `docs/status/P6.md` — P6 구성·결과·남은 것
3. `docs/status/P5.md`, `docs/status/P5-matrix.md` — P5 조건부 마감 내용
4. `docs/install/proxmox-lxc.md` + `deploy/lxc/` — 설치·업데이트 절차(실서버도 이 절차로 운영)
5. `docs/design/05-commercial-deploy-plan.md` P6 항목의 "[P6 결정]"

## 현재 상태

- **P0~P4**: 수용 완료.
- **P5**: 조건부 마감(사용자 결정). 이월: ① Android 17 로컬 네트워크 실제 차단 확인([확인 필요], 출시 전 API 37 기기/에뮬레이터로), ② 가로 화면 LP 수정본의 실기기 회전 재확인.
- **P6**: L2 통과 — FN-01, 06, 07(서버 결함 2건 수정), 09, 10, SEC-15, 설치 문서만으로 재설치(임시 CT 108, 삭제함). 실서버는 문서 7단계로 업데이트됨.
- 앱 테스트 195개, 서버 테스트 149개 통과. 갤러리 88장(`flutter test --tags screenshots test/screenshots/gallery_test.dart`).
- 최신 릴리스 APK 빌드됨(2026-10-04 18:14, `app/build/app/outputs/flutter-apk/app-release.apk`). 휴대폰이 adb offline(시리얼 없음)이라 **설치 못 함**.

## 실서버 (L2)

**저장소는 공개용이라 아래 주소·도메인·키 이름은 예시값이다(192.168.1.x, example.com). 실제 값은 `.local/infra.md`(git 제외)에 있다.**

| 항목 | 값 |
| --- | --- |
| 주소 | `https://music.example.com` (Cloudflare DNS 전용 A → NPM 192.168.1.5, Let's Encrypt DNS 인증) |
| 서버 | Proxmox(192.168.1.4) LXC 107 (192.168.1.173:8080), `/opt/bangmusic/current`, systemd `bangmusic` |
| 음악 | 호스트 `/mnt/media/library/music` → CT `/srv/music/real` `ro=1`, CT 그룹 `music`(gid 1100 = 호스트 101100). flac 176곡, 라이브러리 `lib_01M42X2MN12B13Y2WK5YJ4PVNG` |
| 접속 | `ssh -i ~/.ssh/proxmox_key root@192.168.1.4`(호스트), `root@192.168.1.173`(CT 107) |
| 배포 | `git archive --format=tar -o bangmusic-<rev>.tar HEAD` → CT로 복사 → `deploy/lxc/install.sh` (문서 7단계) |
| L2 도구 | `node tools/e2e/l2-check.mjs fn01|fn06|fn07-down|fn07-up|token-save|token-check --library <id>` (계정: `.local/p6-server.txt`, git 제외. 다른 서버는 `BM_BASE=`) |

## 남은 일

### 사용자 필요
- [x] (해결: 사용자가 적용, 확인함) **NPM 접근 로그에 미디어 티켓(`mt=`)이 남음**(29줄). NPM → Proxy Hosts → `music.example.com` → Advanced에 `access_log off;` `proxy_buffering off;`, SSL 탭 HSTS 켜기. NPM 로그인이 필요해 사용자가 해야 함.
- [x] 실기기 L3(2026-10-04, adb 조작): FN-12·16 통과, FN-15 통과(결함 2건 수정: 91b951d Wi-Fi 끊김 후 멈춤, c6a5afa 음질 변경 시 중복 다운로드), FN-10 앱 복귀 통과, P5 이월 ② 가로 화면 통과. 자세한 내용은 P6.md "L3 결과".
- [x] 실제 블루투스(버즈3) 버튼 통과. P6 수용 기준 모두 통과.
- [ ] Proxmox 호스트 백업 작업이 하나도 없음 → 데이터센터 → 백업 권장(호스트 전체 설정이라 임의로 만들지 않음).

### 사용자 결정 필요 (임의로 정하지 말 것)
- [ ] **FFmpeg 배포 방식**(README §4 미결) — 구매자용 Docker/Compose 이미지를 만들기 전에 필요. 저장소에 Dockerfile/compose 파일이 아직 없다.
- [ ] **서버 로그의 파일 경로**: 설계(05장 §9, 02장 §1)는 "경로는 서버 로그에만, HTTP 응답엔 안 됨"인데 CLAUDE.md는 "HTTP 응답·로그에 경로 금지". 어느 쪽을 따를지. (HTTP 응답에는 경로 없음 — 관리 API는 `error_code`만 내보냄.)

### P6 마감 시 정리
- [ ] 시험 계정 `p6tester` 삭제(실서버) — 자동 권한 검사가 막아 사용자 실행 대기: `node .local/del-p6tester.mjs`(다른 활성 관리자 확인 후 삭제, 끝에 `delete 204`·`login after delete 401`). 그 뒤 `.local/p6-server.txt`, `.local/p6-token.json`, `.local/del-p6tester.mjs` 삭제.
- [x] CT 107 `/root/fn10-db-before-*` 삭제됨(사용자 실행, 확인함).
- [x] P6 수용 기준 모두 통과(P6.md). 다음은 P7 — 시작 전 사용자 결정 필요: 판매 모델, 서버 라이선스, 제품명·상표, FFmpeg 배포 방식, 오류 보고 수집 여부.
- [ ] 사용자에게 상기: SSH 키 `<배포용 SSH 키>`을 호스트·CT 107 `authorized_keys`에서 제거, PC 시간 자동 동기화(약 50초 빠름).

## What was tried / 주의

- **서버 강제 종료·권한 부여 같은 작업은 자동 권한 검사가 막는다.** 막히면 다른 방법으로 우회하지 말고, 사용자에게 명령을 주고 직접 실행하게 한다(FN-09는 그렇게 했다). 서버 계정을 CT root 그룹에 넣는 방법은 막혀서 전용 `music` 그룹으로 해결.
- `pct exec`로 실행하면 PATH에 `/usr/local/bin`이 없다 → `bash -lc` 사용(설치 스크립트는 PATH를 고정함).
- 리프레시 토큰은 쓸 때마다 회전한다. 같은 값을 두 번 보내면 재사용 감지로 세션이 폐기된다(서버 정상 동작). 복원 직후 옛 액세스 토큰은 설계대로 `access_expired`.
- CT 재시작 시 `/tmp`가 비워진다(점검 스크립트 다시 복사 필요).
- 릴리스 APK: `flutter build apk --release`가 Kotlin 증분 캐시 오류(`this and base files have different roots` — 빌드 폴더 D:, pub 캐시 C:)로 실패하면 `app/android`에서 `.\gradlew.bat assembleRelease "-Pkotlin.incremental=false"`(PowerShell). 결과는 `app/build/app/outputs/flutter-apk/app-release.apk`. 환경 변수 `ORG_GRADLE_PROJECT_kotlin.incremental`로는 플러그인 하위 프로젝트에 적용되지 않았다.
- Windows에서 Python으로 파일을 쓸 때 `newline='\n'`을 쓴다(CRLF로 바뀌는 문제). bash heredoc 안의 `\n`·따옴표가 깨지기 쉬우니 긴 편집은 스크립트 파일로.

## Constraints

- 음악 원본 경로에 절대 쓰지 않는다. 시험은 `tools/make-fixtures` 합성 음원 또는 읽기 전용 실서버만.
- 비밀번호·토큰·미디어 티켓 값을 채팅·로그·커밋에 쓰지 않는다. 사용자 계정 로그인은 사용자가 직접.
- 앱은 구매자 서버와 스토어 외에는 통신하지 않는다. 분석 SDK 추가 금지.
- 커밋 메시지 끝: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
