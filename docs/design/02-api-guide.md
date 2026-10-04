# 02. API 가이드 (openapi.yaml 해설)

기계 판독용 계약은 `openapi.yaml`이다. 이 문서는 그 계약의 동작 규칙과 예제를 설명한다. 둘이 다르면 `openapi.yaml`을 고치고 이 문서를 맞춘다.

---

## 1. 인증

### 1.1 토큰 종류

| 토큰 | 형태 | 기본 수명(설정 가능) | 보관 위치 | 용도 |
| --- | --- | --- | --- | --- |
| 액세스 토큰 | 불투명 무작위 문자열(`bma_…`) | 1시간 | 앱 메모리 + 보안 저장소 | `Authorization: Bearer` |
| 리프레시 토큰 | 불투명 무작위 문자열(`bmr_…`), 1회용 | 90일, 사용할 때마다 연장 | 보안 저장소(Android Keystore / iOS Keychain) | 액세스 토큰 갱신 |
| 미디어 티켓 | 서버 서명 문자열(`mt` 쿼리) | 12시간 | 저장하지 않음(메모리) | 오디오·표지 요청 전용 |

- 서버는 토큰 원문을 저장하지 않고 SHA-256 해시만 저장한다. JWT를 쓰지 않는 이유: 세션 취소를 즉시 반영해야 하고, 단일 서버라 DB 조회 비용이 문제되지 않는다.
- 비밀번호는 Argon2id로 해시한다. 로그인 실패는 사용자 이름·IP별로 속도 제한한다(`429 rate_limited`).
- 토큰·비밀번호·`mt` 값은 서버 로그, 앱 로그, 오류 보고에 남기지 않는다. 접근 로그에는 `mt=<redacted>`로 기록한다.

### 1.2 갱신 흐름

```text
앱 요청 ──401 access_expired──▶ (단일 비행) POST /auth/refresh ──200──▶ 원 요청 1회 재시도
                                              ├─401 refresh_expired / session_revoked ──▶ "세션 만료" 상태로 전환
                                              └─네트워크 오류 / 5xx ──▶ 토큰 유지, 오프라인으로 취급
```

- **단일 비행**: 동시에 여러 요청이 401을 받아도 갱신은 한 번만 한다.
- **회전과 재시도**: 리프레시 응답을 받지 못하고 연결이 끊겼을 때를 위해, 직전 리프레시 토큰은 60초 동안 같은 새 토큰 쌍을 다시 받을 수 있다. 그 이후 재사용은 탈취로 판단해 세션을 폐기한다(`session_revoked`).
- **네트워크 오류는 세션 만료가 아니다.** 서버에 닿지 못한 것만으로 토큰을 버리거나 다운로드를 지우지 않는다.
- **[P1 구현 결정]** 서버가 모르는 리프레시 토큰(형식이 틀리거나, 계정 삭제로 세션이 사라진 경우)은 `401 refresh_expired`로 답한다. `session_revoked`(접근 취소 — 03장 §5.8에서 다운로드를 잠금)보다 약한 쪽을 택해, 알 수 없는 이유로 다운로드가 잠기지 않게 한다. 재사용 감지·취소된 세션은 그대로 `session_revoked`다.

### 1.3 취소

| 동작 | API | 효과 |
| --- | --- | --- |
| 앱에서 로그아웃 | `POST /auth/logout` | 현재 세션·티켓 즉시 무효 |
| 다른 기기 끊기 | `DELETE /sessions/{id}` | 해당 기기는 다음 요청에서 `session_revoked` |
| 비밀번호 변경 | `PUT /me/password` | 현재 세션 외 전부 폐기 |
| 관리자가 사용자 차단/접근 축소 | `PATCH /admin/users/{id}` | 즉시 적용, 티켓 포함 |

### 1.4 미디어 티켓

필요한 이유: 오디오 플레이어와 OS 백그라운드 다운로더는 요청마다 `Authorization` 헤더를 붙이기 어렵거나(일부 플레이어는 로컬 평문 프록시를 써야 함), 긴 곡·긴 다운로드 도중 액세스 토큰이 만료된다.

- 형식: `base64url(payload) . base64url(HMAC-SHA256(server_key, payload))`. payload = `{v, sid, uid, res, exp}` (`res`는 렌디션 ID 또는 표지 ID).
- 검증: 서명 → 만료 → `res`가 요청 경로와 일치 → 세션이 폐기되지 않음 → 사용자가 여전히 해당 라이브러리 접근 권한 보유. 마지막 두 단계 때문에 **티켓이 살아 있어도 세션 취소·권한 회수가 즉시 반영**된다.
- 티켓은 한 자원에만 유효하므로 URL이 유출되어도 다른 곡이나 API에는 쓸 수 없다. 그래도 URL에 비밀이 들어가므로 HTTPS 전용이고 로그에서 가린다.
- 만료 시: 미디어 요청이 `401 ticket_expired` → 앱이 `GET /renditions/{id}`로 새 `media_url`을 받아 같은 바이트 위치에서 이어 간다(렌디션이 불변이므로 안전).
- 표지 URL은 `GET /artwork/{id}?size=…`에 헤더 인증을 기본으로 쓴다. 잠금화면 메타데이터처럼 OS가 직접 가져가야 하는 경우에는 앱이 로컬에 캐시한 파일 URI를 넘긴다(티켓 URL을 OS에 넘기지 않는다).

---

## 2. 서버 기능 확인과 버전 호환성

### 2.1 규칙

- 경로의 `/v1`은 **호환성 약속**이다. `/v1` 안에서는 필드·엔드포인트·enum 값·오류 코드의 **추가만** 한다. 의미 변경·삭제·필수 필드 추가는 `/v2`에서만 한다.
- `api.minor`는 `/v1`에 기능이 추가될 때마다 1씩 오른다. 선택 기능은 `features`에도 나타난다.
- 앱은 모든 요청에 `BangMusic-Client: <platform>/<app_version> api=1.<minor>` 헤더를 보낸다.

### 2.2 서버가 앱보다 오래된 경우 (자가호스팅에서 가장 흔함)

앱은 빌드 시 두 상수를 가진다: `API_MINOR_BUILT`(앱이 아는 최신), `API_MINOR_REQUIRED`(이보다 낮은 서버와는 동작 불가).

| 조건 | 앱 동작 |
| --- | --- |
| `server.api.major != 1` | 연결 거부. "이 서버는 지원되지 않는 버전입니다." |
| `server.api.minor < API_MINOR_REQUIRED` | 로그인 차단. "서버를 x.y 이상으로 업데이트하세요." 기존 다운로드본은 오프라인 재생 가능. |
| `API_MINOR_REQUIRED ≤ server.api.minor < API_MINOR_BUILT` | 정상 동작. 서버에 없는 기능은 **UI에서 숨기거나 비활성화**(예: `features`에 `transcode` 없음 → 음질 선택 숨김, 재생 불가 형식은 "서버가 변환을 지원하지 않음" 표시). 설정 화면에 "서버 업데이트 가능" 안내. |
| `server.min_client_api_minor > API_MINOR_BUILT` | 서버가 `426 client_too_old`. "앱을 업데이트하세요." |

앱은 기능 사용 여부를 **서버 버전 문자열 비교가 아니라 `api.minor`와 `features`로만** 판단한다. 기능별 요구 minor 표는 앱 코드 한 곳(`core/capabilities.dart`)에 둔다.

### 2.3 서버 측 약속

- 최소 **최근 2개 메이저 앱 릴리스**가 쓰는 API minor를 지원하고, **어느 앱 버전이든 출시 후 최소 12개월**은 지원을 끊지 않는다(둘 중 긴 쪽). **[P7 결정 2026-10-04, 사용자]**
- `min_client_api_minor`를 올리는 릴리스는 릴리스 노트에 명시한다.

---

## 3. 목록·검색·페이지네이션

- **커서 방식**. `next_cursor`가 `null`이면 끝. 커서는 불투명하며(내부적으로 정렬 키 + ID), 다른 `sort`/필터와 섞어 쓰면 `400 validation_failed`.
- 커서는 keyset 기반이라 목록 도중 항목이 추가·삭제되어도 중복·누락이 최소화된다. 전체 일관성이 필요한 동기화는 `GET /changes`를 쓴다.
- `limit` 최대 200(`limits.max_page_size`).
- 검색: `q`는 서버가 정규화(NFKC, 소문자, 가타카나→히라가나, 전/반각 통일)한다. `ｶﾞｰﾙｽﾞ`, `ガールズ`, `がーるず`는 같은 결과를 낸다. 응답의 `query_normalized`로 확인할 수 있다.
- 앱의 검색 입력은 300ms 디바운스, 이전 요청은 취소한다.

예제:

```http
GET /v1/search?q=%E3%82%88%E3%81%82%E3%81%91&types=track&limit=2 HTTP/1.1
Authorization: Bearer bma_…
BangMusic-Client: android/1.0.0 api=1.0
```

```json
{
  "query_normalized": "よあけ",
  "tracks": {
    "items": [
      { "id": "trk_01JB2P3C5E7G9J1L3N5Q7S9U1W", "title": "夜明けのうた", "title_sort": "よあけのうた",
        "artists": [{ "id": "art_01JB2P1A3C5E7G9J1L3N5Q7S9U", "name": "テスト楽団" }],
        "album": { "id": "alb_01JB2P2B4D6F8H0K2M4P6R8T0V", "title": "合成アルバム" },
        "duration_ms": 215340, "artwork_id": "img_01JB2P0Z2B4D6F8H0K2M4P6R8T",
        "media_version": "k7q2m9x4b1c8d5f0", "state": "available",
        "has_lyrics": ["original"], "updated_at": "2026-09-28T11:02:13Z" }
    ],
    "next_cursor": "eyJrIjoi44KI44GC44GR44Gu44GG44GfIiwiaSI6InRya18wMUpCMlAzQyJ9"
  }
}
```

---

## 4. 플레이리스트 동시 수정

- 모든 수정 요청은 `If-Match: "<version>"` 필수. 없으면 `428`, 다르면 `412 version_conflict` + 현재 `ETag`.
- 앱의 충돌 처리: (1) 최신 항목을 받아 온다 → (2) 사용자의 연산이 여전히 유효하면(대상 `item_id`가 존재) 자동 재적용 → (3) 유효하지 않으면 "다른 기기에서 변경됨" 알림과 함께 최신 상태를 보여 준다. 조용히 덮어쓰지 않는다.
- 생성과 편집은 `Idempotency-Key`로 재전송 중복을 막는다(응답을 못 받고 재시도해도 플레이리스트가 두 개 생기지 않는다).
- 오프라인 중 편집은 앱 로컬 대기열에 연산 단위로 쌓고, 온라인 복귀 시 위 규칙으로 순서대로 보낸다.

---

## 5. 스트림·다운로드 요청 순서

```text
1. POST /v1/tracks/{id}/renditions  { purpose, quality, accept[] }
      200 ready      → 3으로
      202 preparing  → 2로
2. GET  /v1/renditions/{rid}        (Retry-After 간격으로 폴링, 상한 60초 후 "준비 지연" 표시)
      ready → 3,  failed → 오류 표시
3. GET  /v1/media/{rid}?mt=…        Range: bytes=…   (스트림은 플레이어가, 다운로드는 다운로더가)
      206/200 → 정상
      401 ticket_expired → GET /renditions/{rid} 로 새 URL, 같은 위치에서 재개
      410 rendition_superseded → 1부터 다시 (다운로드 중이었다면 부분 파일 폐기)
```

`curl`로 계약을 확인하는 예:

```bash
# 길이·형식 확인
curl -sI "https://music.example.net/v1/media/rnd_01JB2R7G…?mt=$MT"
# HTTP/2 200
# accept-ranges: bytes
# content-length: 24561892
# content-type: audio/flac
# etag: "k7q2m9x4b1c8d5f0-original"
# x-content-duration-ms: 215340

# 중간부터 받기
curl -s -H "Range: bytes=1048576-2097151" -o part.bin -D - \
  "https://music.example.net/v1/media/rnd_01JB2R7G…?mt=$MT"
# HTTP/2 206
# content-range: bytes 1048576-2097151/24561892
# content-length: 1048576
```

---

## 6. 오류 코드

모든 오류 본문은 `application/problem+json`이며 `code`, `request_id`를 포함한다. `detail`은 사람이 읽는 문장이고 서버 경로·SQL·스택을 넣지 않는다.

| HTTP | code | 의미 | 앱 동작 | 자동 재시도 |
| --- | --- | --- | --- | --- |
| 400 | `validation_failed` | 요청 형식 오류 | 개발 버그로 기록. 사용자에겐 일반 오류. | 안 함 |
| 401 | `invalid_credentials` | 로그인 실패 | 입력란 오류 표시 | 안 함 |
| 401 | `access_expired` | 액세스 토큰 만료 | 갱신 후 원 요청 1회 재시도 | 갱신 후 1회 |
| 401 | `access_invalid` | 토큰 형식/서명 불량 | 갱신 시도, 실패 시 세션 만료 상태 | 갱신 후 1회 |
| 401 | `refresh_expired` | 리프레시 만료 | **세션 만료** 상태(다운로드 유지, 재로그인 유도) | 안 함 |
| 401 | `session_revoked` | 사용자·관리자가 세션 취소 | **접근 취소** 상태(03장 §5.8) | 안 함 |
| 401 | `account_disabled` | 계정 비활성화 | 접근 취소와 동일 | 안 함 |
| 401 | `ticket_expired` / `ticket_invalid` | 미디어 티켓 문제 | 렌디션 재조회로 새 URL | 1회 |
| 403 | `forbidden` | 관리자 역할 필요 | 메뉴 숨김(정상적으로는 도달하지 않음) | 안 함 |
| 404 | `not_found` | 없거나 권한 없음 | 목록에서 제거/"찾을 수 없음" | 안 함 |
| 404 | `media_missing` | 곡은 있으나 원본 파일 없음 | 곡에 "서버에 파일 없음" 표시, 다음 곡으로 | 안 함 |
| 409 | `rendition_not_ready` | 변환 중 | 폴링 | `Retry-After` |
| 409 | `username_taken`, `last_admin` | 상태 충돌 | 메시지 표시 | 안 함 |
| 410 | `rendition_superseded` | 원본이 바뀜 | 렌디션 재결정, 부분 다운로드 폐기 | 즉시 1회 |
| 410 | `sync_token_expired` | 변경 피드 토큰 만료 | 전체 재동기화 | 즉시 |
| 412 | `version_conflict` | 플레이리스트 동시 수정 | §4 | 병합 후 1회 |
| 413 | `payload_too_large` | 표지 크기 초과 | 메시지 표시 | 안 함 |
| 415 | `unsupported_media_type` | 표지 형식 | 메시지 표시 | 안 함 |
| 416 | `range_not_satisfiable` | 범위 오류 | 부분 파일 폐기 후 처음부터 | 1회 |
| 422 | `no_playable_format` | 재생 가능한 형식 없음, 변환 꺼짐 | "이 기기에서 재생할 수 없는 형식" | 안 함 |
| 426 | `client_too_old` | 앱 업데이트 필요 | 업데이트 안내 화면 | 안 함 |
| 428 | `precondition_required` | `If-Match` 누락 | 개발 버그 | 안 함 |
| 429 | `rate_limited` | 요청 과다 | 대기 | `Retry-After` |
| 429 | `transcode_queue_full` | 변환 대기열 가득 | "서버가 바쁨", 대기 | `Retry-After` |
| 500 | `internal_error` | 서버 버그 | 일반 오류 + `request_id` 표시 | GET만 백오프 |
| 503 | `storage_unavailable` | 음악 저장소 장애 | "서버의 음악 저장소에 연결할 수 없음". 다운로드본으로 계속 재생 가능 | 백오프 |
| 503 | `maintenance` | 마이그레이션·복원 중 | "서버 점검 중" | 백오프 |
| 503 | `setup_required` | 초기 설정 미완료 | 설치 안내 링크 | 안 함 |
| (rendition) | `transcode_failed`, `unsupported_source` | 변환 실패 | 곡에 오류 표시, 다음 곡으로 | 안 함 |

`권한 없음`, `세션 만료`, `파일 없음`, `저장소 일시 장애`, `변환 실패`가 각각 다른 코드를 가진다는 점이 수용 기준이다(05장 P2).

P1 구현에서 정한 세부 동작:

- 형식이 맞지 않는 ID(`trk_../..`, NUL 포함 등)는 DB를 조회하지 않고 `404 not_found`(SEC-01).
- 스캔 후 원본 위치가 라이브러리 밖을 가리키게 바뀌면(링크 바꿔치기) `404 media_missing`으로 답하고 경로는 서버 로그에만 남긴다. 재스캔을 예약한다(SEC-03).
- 미디어 응답 직전 `fstat` 크기·mtime이 DB와 다르면 `410 rendition_superseded`이고 재스캔을 예약한다(03장 §4.2).
- `416`·오류 응답에는 미디어용 불변 캐시 헤더(`Cache-Control: immutable`, `ETag`)를 붙이지 않는다.
- 초기 설정 전(활성 관리자 없음)에는 `GET /server`만 응답하고 나머지는 `503 setup_required`.
- 변환이 꺼진 서버(`TRANSCODE_ENABLED=false`)는 `features`에 `transcode`가 없고 `transcode_profiles`가 비어 있다. 이때 `quality`가 `original`이 아니면 `400`, 원본을 기기가 재생할 수 없으면 `422 no_playable_format`.

가사 해석 (P3, 기존 BangMusic `lyrics-core.js`와 테스트 이식 — 설계와 다르면 기존 동작):

- `[offset:N]`은 각 시각에 N ms를 **더한다**(LRC 관례와 반대지만 기존 앱 동작). 사용자별 보정값 `offset_ms`(양수 = 가사를 늦춤)와는 별개다.
- 같은 시각의 줄은 하나로 합친다(문장이 다르면 줄바꿈으로 잇는다). 시간 표시는 줄 어디에 있어도 인식하고 단어 시간 `<mm:ss.xx>`는 지운다. 시간 없는 가사는 빈 줄·메타데이터 줄을 버린다. UTF-16(BOM) 파일을 읽는다.
- 앱의 3단 맞추기: 시간 있는 발음·번역은 원문과 시각 차 0.35초 미만, 시간 없는 것은 줄 수가 같을 때만 순서대로.
- **한글 발음 자동 생성**(05장 §8.4): `pronunciation_ko`가 없고 원문에 일본어(가나·한자)가 있으면 서버가 원문과 **같은 시각·같은 줄 수**로 발음을 만들어 `source.type: generated`로 돌려준다. 일본어가 없는 줄은 빈 문자열. 저장하지 않으며 `has_lyrics`에도 포함된다. 사이드카·직접 입력이 생기면 그쪽이 우선. 가사 ETag는 `"v<버전>-o<보정값>-g<생성 규칙 버전>"`이고 `If-Match`는 `-o`·`-g` 부분 없이 `"v<버전>"`만 비교한다.

P2 구현에서 정한 세부 동작:

- **계약 보강(추가 변경)**: 입력 검증이 실패할 수 있는데 `400`이 없던 15개 동작(`refreshToken`, `deleteMe`, `getHome`, `listAlbums`, `listArtists`, `getChanges`, `getArtwork`, `putLyricsOffset`, `listPlaylists`, `updatePlaylist`, `listPlaylistItems`, `putPlaylistCover`, `getRecentTracks`, `getTopTracks`, `adminUpdateUser`)에 `400`을 넣었다. 또 `426 client_too_old`·`503`(`setup_required`/`maintenance`)은 서버가 모든 요청에 적용하므로 **모든 동작**에 선언했다(계약 테스트가 선언되지 않은 상태 코드를 실패로 처리하면서 드러남).
- `GET /server`는 `426`을 내지 않는다. 오래된 앱도 `min_client_api_minor`를 읽어 "앱을 업데이트하세요" 화면을 띄울 수 있어야 한다.
- `DELETE /me`의 비밀번호가 틀리면 `401 invalid_credentials`(계약에 `400`이 없던 시점의 결정. 형식 오류는 이제 `400`).
- 표지 업로드에서 `If-Match`가 없으면 `400`(이 동작의 계약에는 `428`이 없다). 다른 플레이리스트 수정은 `428`.
- 플레이리스트 편집의 `Idempotency-Key` 재요청은 **버전 검사보다 먼저** 처리한다. 응답을 못 받은 편집을 같은 `If-Match`로 다시 보내도 `412`가 아니라 처음 결과(`Idempotent-Replay: true` 헤더)를 받는다.
- 접근할 수 없는 곡을 플레이리스트에 넣으려 하면 존재를 드러내지 않도록 `400`(404 아님).
- 표지 업로드는 디코딩 전에 헤더로 픽셀 수를 확인해 5천만 픽셀을 넘으면 `400`(압축 폭탄, SEC-13).
- 점검 모드: `DATA_DIR/MAINTENANCE` 파일이 있으면 `GET /server` 외 `503 maintenance`(`bangmusic-server maintenance on|off`).

## 7. 재시도 정책 (앱 공통)

- **멱등 요청**(GET, HEAD, PUT, DELETE, `Idempotency-Key`가 있는 POST, `event_id`가 있는 기록 전송): 네트워크 오류·502/503/504에서 지수 백오프(1s, 2s, 4s, 8s, 최대 60s, ±20% 지터), 사용자 화면 요청은 최대 3회, 백그라운드 동기화는 연결 복귀 이벤트까지 대기.
- **`Retry-After`가 있으면 그것을 우선**한다.
- **비멱등 POST**(`/auth/login`): 자동 재시도하지 않는다.
- 4xx(위 표에서 재시도 표시가 없는 것)는 재시도하지 않는다.
- 타임아웃: 연결 10초, JSON 응답 20초, 미디어는 읽기 정체 30초(플레이어·다운로더 설정).

## 8. 개인정보 관련 계약

- 앱이 서버로 보내는 식별자는 `installation_id`(무작위 UUID), 사용자가 정한 기기 이름, 플랫폼, 앱 버전뿐이다. 광고 ID·하드웨어 ID를 보내지 않는다.
- 이 API의 상대는 **구매자의 서버뿐**이다. 앱은 음악 목록·플레이리스트·재생 기록·서버 주소·토큰을 개발자 측 서버로 보내지 않는다(05장 §8).
- `DELETE /me`, `GET /me/export`, `DELETE /history`로 사용자가 자기 데이터를 지우고 내보낼 수 있다.
