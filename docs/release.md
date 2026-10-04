# 릴리스 규칙

05장 P7 "릴리스 노트 규칙(API minor, `min_client_api_minor`)"과 02장 §2. 서버와 앱은 따로 릴리스하고, 호환은 API 버전으로 맞춘다.

## 버전

| 대상 | 형식 | 고치는 곳 |
| --- | --- | --- |
| 서버 | SemVer `X.Y.Z` | `server/src/config.ts` `SERVER_VERSION` (`/v1/server`의 `version`). 이미지 태그도 같은 값 |
| 앱 | SemVer `X.Y.Z` + 빌드 번호 | `app/pubspec.yaml` `version: X.Y.Z+N`과 `app/lib/core/app_info.dart` `appVersion`(시험이 둘이 같은지 확인). 빌드 번호 N은 스토어에 올릴 때마다 1씩 올린다(되돌릴 수 없음) |
| API | `1.minor` | `docs/design/openapi.yaml`이 기준. 하위 호환 추가는 minor 증가, 깨지는 변경은 major(경로 `/v2`) |

- **릴리스마다 서버 버전을 올린다.** 버전이 같으면 `/v1/server`로 어느 이미지가 돌고 있는지 구별할 수 없다(P7 업그레이드 연습에서 옛·새 이미지가 모두 `0.1.0`이었다).
- 서버 패치(Z)는 DB 스키마를 바꾸지 않는다. 스키마가 바뀌면 최소 Y를 올리고, 릴리스 노트에 "되돌리려면 업데이트 전 백업으로 복원" 을 적는다.

## 구버전 앱 지원 ([P7 결정], 02장 §2.3)

- 서버는 **최근 앱 메이저 2개**가 쓰는 API minor를 지원하고, **어느 앱 버전이든 출시 후 최소 12개월**은 지원을 끊지 않는다(둘 중 긴 쪽).
- `min_client_api_minor`(서버 설정 `BANGMUSIC_MIN_CLIENT_API_MINOR`)를 올리는 릴리스는 릴리스 노트 맨 위에 "이 버전부터 앱 X.Y 이상 필요"로 적는다. 올리기 전에 위 기간이 지났는지 확인한다.

## 릴리스 노트 (서버·앱 공통 틀)

```
## 서버 X.Y.Z (YYYY-MM-DD)  — API 1.m, 필요한 앱 API minor ≥ k
### 반드시 읽기   (없으면 생략: min_client_api_minor 변경, DB 스키마 변경, 설정 이름 변경)
### 새 기능
### 고친 것
### 업데이트 방법 (Docker: docs/install/docker.md 7단계 / LXC: proxmox-lxc.md 7단계)
```

## 서버 릴리스 점검표

1. `npm run lint:openapi`, 서버 시험(`npm test --workspace server`), 앱 시험(`flutter test --exclude-tags screenshots`)
2. `SERVER_VERSION` 올리기, 릴리스 노트
3. 이미지 빌드: `docker build -f deploy/docker/Dockerfile -t bangmusic-server:X.Y.Z .` → 빌드 로그의 "허용 목록 밖" 라이선스 확인
4. 시험 환경에서 이전 버전 → 새 버전 업데이트와 되돌리기(docs/install/docker.md 7단계), FN-01 (`tools/e2e/l2-check.mjs fn01`)
5. FFmpeg 대응 소스 묶음을 릴리스 첨부로: 이미지의 `/licenses/ffmpeg/SOURCE.txt` 버전의 Debian 소스(`apt-get source ffmpeg=<버전>` 결과의 `.orig.tar.*`, `.debian.tar.*`, `.dsc`)
6. 태그 `server-vX.Y.Z`, 이미지 게시

## 앱 릴리스 점검표

1. 앱 시험, `flutter analyze`
2. `pubspec.yaml` 버전·빌드 번호, `AppInfo.appVersion`
3. 서명된 앱 번들: `app/android`에서 `.\gradlew.bat bundleRelease "-Pkotlin.incremental=false"` → `app/build/app/outputs/bundle/release/app-release.aab`.
   업로드 키는 `app/android/key.properties`(git 제외)가 가리키는 `.local/upload-keystore.jks`(별칭 `upload`, RSA 4096, 2026-10-04 생성). [P7 결정] 사본과 비밀번호는 사용자가 Vaultwarden에 보관. Play 앱 서명을 켜서 Google이 최종 서명 키를 보관한다(업로드 키를 잃으면 콘솔에서 재설정).
   key.properties가 없으면 디버그 키로 서명된다 — 스토어에 올리기 전에 `keytool -printcert -jarfile <aab>`가 `CN=BangMusic Upload`인지 확인한다.
4. 내부 테스트 트랙 → 실기기 FN 주요 항목(05장 P7 수용 기준), 구매·복원
5. 스토어 데이터 보안 양식이 개인정보 처리방침(`docs/legal/privacy-policy.md`)과 맞는지(수집 없음)
6. 태그 `app-vX.Y.Z+N`
