# 01. 기술 선택 · 아키텍처 · 데이터 모델

작성 기준: 2026-10-02. 제품 형태는 **구매자가 자기 음악 서버에 연결하는 앱**, 진행 방식은 **설계 문서 먼저**로 확정된 상태를 전제로 한다.

표기 규칙: **[결정]** 은 이 설계의 선택, **[대안]** 은 검토했으나 채택하지 않은 안, **[확인 필요]** 는 구현 단계에서 실기기·실서버로 검증해야 하는 가정, **[미결]** 은 제품 소유자가 정해야 하는 항목이다.

---

## 1. 제품 형태가 설계에 주는 영향

"자기 서버 연결 앱"이므로 판매 대상은 **모바일 앱**이고, 음원은 구매자가 자기 서버에 둔 자기 파일이다. 여기서 따라오는 결과:

| 항목 | 결과 |
| --- | --- |
| 서버 운영자 | 구매자 본인. BangMusic 운영자는 고객 음원·계정 데이터를 보관하지 않는다. |
| 서버 소프트웨어 | 구매자가 설치해야 하므로 **배포물**(컨테이너 이미지 + 설치 문서)이 된다. Proxmox는 1차 검증 환경이며, 서버는 일반 Linux + Docker에서 동작해야 한다. |
| 계정 | 서버마다 독립된 로컬 계정. 중앙 계정 서버 없음. 관리자(구매자)가 가족 등 소수 사용자를 만든다. |
| 권한 | 관리자/일반 사용자 2단계 + 라이브러리별 접근 허용. |
| 오프라인 정책 | 파일은 구매자 소유이므로 구독 만료 개념이 없다. 정식 DRM은 요구사항이 아니다(08장). |
| 앱의 서버 주소 | 사용자가 입력. LAN IP·사설 도메인·VPN 주소가 흔하므로 HTTPS 인증서와 Android 로컬 네트워크 권한을 설계해야 한다(§2.6). |
| 스토어 심사 | 심사자가 로그인할 **데모 서버**(재배포 가능한 음원만 담은)가 필요하다. |

---

## 2. 기술 선택

### 2.1 Proxmox: VM vs LXC

**[결정] Linux VM(QEMU) 안에서 Docker Compose로 실행한다.**

- Proxmox 문서는 애플리케이션 컨테이너(Docker)를 VM 안에서 돌리는 구성을 권장한다. Proxmox VE 9.1의 OCI 이미지→LXC 변환 기능은 기술 미리보기이며, 이미지 레이어를 평탄화하므로 새 이미지로 교체하려면 컨테이너를 다시 만들어야 하고 Compose를 지원하지 않는다. 판매용 서버의 업데이트·롤백 경로로 쓰기에 이르다.
- VM은 호스트 커널과 분리되어, FFmpeg가 신뢰할 수 없는 미디어 파일을 파싱하다 문제가 생겨도 영향 범위가 VM 안으로 제한된다.
- VM 스냅샷/백업(vzdump, PBS)을 그대로 쓸 수 있다.
- 구매자 환경(Proxmox가 아닌 NAS·미니PC)에도 같은 Compose 파일이 그대로 통한다.

**[대안]** 비특권 LXC에 바이너리 직접 설치: 메모리 오버헤드가 작고 bind mount가 간단하지만, 배포물이 Proxmox 전용 설치 절차가 되고 Docker-in-LXC는 권장 구성이 아니다. 숙련 사용자용 비공식 경로로만 문서화한다.

권장 VM 초기값(측정 전 가정, **[확인 필요]**): Debian 13, 2 vCPU, 2 GB RAM, 시스템 디스크 16 GB + 데이터 디스크(변환 캐시 크기에 따름). 처리량은 P2 단계에서 측정한 뒤 문서화한다.

### 2.2 음악 원본 마운트

원본은 **읽기 전용**으로 두 겹 보호한다: (1) VM에 읽기 전용으로 마운트, (2) 컨테이너에 `:ro` bind mount.

| 원본 위치 | VM으로 전달 | 비고 |
| --- | --- | --- |
| NAS(SMB/NFS) | VM에서 `ro` 옵션으로 직접 마운트 | 가장 흔한 구성. 마운트 끊김 처리 필수(§4.4). |
| Proxmox 호스트 디렉터리 | virtiofs 디렉터리 매핑 → VM에서 `ro` 마운트 | PVE 8.4 이상. **[확인 필요]** 실제 설치 버전에서 지원 여부. |
| 전용 디스크 | 디스크 패스스루 → VM에서 `ro` 마운트 | 다른 VM과 공유 불가. |

### 2.3 배포 방식

**[결정]** 컨테이너 2개의 Docker Compose.

```text
VM
 └─ docker compose
     ├─ proxy  (Caddy)          : 443 종단, 인증서 자동 발급/갱신, 서버로 리버스 프록시
     └─ server (bangmusic-server): API + 스캐너 + 변환 작업자, 단일 프로세스
         ├─ /music   (ro)  음악 원본
         ├─ /data    (rw)  SQLite DB, 플레이리스트 표지 업로드, 백업 스냅샷
         └─ /cache   (rw)  변환 캐시, 표지 썸네일 (삭제해도 재생성 가능)
```

- 서버 컨테이너: 비루트 UID, 읽기 전용 루트 파일시스템, `cap_drop: ALL`, `no-new-privileges`.
- 이미지 태그는 버전 고정(`1.4.2`), `latest` 사용을 문서에서 권하지 않는다. 롤백 = 이전 태그 + 마이그레이션 직전 자동 백업 복원(§5.3).
- 과도한 분리 금지: 메시지 큐, 별도 변환 서비스, 별도 검색 서버, Redis를 두지 않는다. 작업 큐는 SQLite 테이블 + 프로세스 내 작업자다.

### 2.4 백엔드 프레임워크와 DB

**[결정] TypeScript(Node.js LTS) + Fastify + SQLite(WAL) + FFmpeg/ffprobe CLI.**

근거:

- 기존 BangMusic이 JavaScript이며 `lyrics-core.js`의 LRC 처리, 셔플/반복·플레이리스트·재생 기록 테스트를 **동작 기준으로 재사용**하기 쉽다(IPC·mpv 제어 코드는 가져오지 않는다).
- Fastify는 JSON Schema 기반 검증을 하므로 OpenAPI 계약과 구현의 스키마를 한 곳에서 관리할 수 있다.
- 가정용 규모(사용자 수 명, 곡 수만~수십만)는 SQLite 단일 파일로 충분하고, 구매자가 DB 서버를 운영할 필요가 없다. 백업이 파일 하나다.
- Range 응답은 파일 스트림을 그대로 흘려보내는 I/O 작업이라 Node에 적합하다. CPU 작업(변환)은 FFmpeg 자식 프로세스가 한다.

| 대안 | 장점 | 채택하지 않은 이유 |
| --- | --- | --- |
| Go 단일 바이너리 | 배포 간단, 메모리 작음 | 기존 JS 로직·테스트 재사용 불가. 팀 숙련도 미확인. 성능이 병목이 되면 재검토. |
| Kotlin/Ktor | 모바일(KMP)과 모델 공유 | 앱이 Flutter이면 공유 이점 없음. |
| PostgreSQL | 동시 쓰기, 확장성 | 구매자 운영 부담. 저장소 계층을 인터페이스로 분리해 두어 향후 "운영자 제공 서비스"로 전환 시 교체 가능하게 한다. |
| 기존 프로토콜(OpenSubsonic) 서버 채택 | 기존 서버(Navidrome 등) 생태계 호환 | 한글 발음/번역 가사, 미디어 버전 기반 오프라인, 표지 있는 플레이리스트 계약을 표현하기 어렵다. **[미결]** 앱이 OpenSubsonic 서버에도 연결하도록 할지는 시장 범위에 영향이 크므로 별도 결정(README §4 참조). |

SQLite 운용 규칙: WAL 모드, `foreign_keys=ON`, `busy_timeout` 설정, 쓰기는 단일 커넥션 직렬화, DB 파일은 **로컬 디스크**(네트워크 파일시스템 금지).

**[P1 구현 결정]** 네이티브 애드온을 쓰지 않는다. SQLite는 Node 24 내장 `node:sqlite`(SQLite 3.53, FTS5 trigram 포함), Argon2id는 내장 `node:crypto`의 `argon2Sync`를 쓴다. 이유: 설치 스크립트·플랫폼별 바이너리가 없어 컨테이너 이미지와 개발 PC 설치가 단순해지고, `npm` 설치 스크립트 차단 환경에서도 동작한다. 서버는 TypeScript를 Node의 타입 제거(type stripping)로 빌드 없이 실행한다(`tsc`는 검사만). 둘 다 Node 24 기준 실험 단계 표시가 남아 있을 수 있으므로 Node 버전을 이미지에서 고정한다 **[확인 필요: 릴리스 전 Node LTS의 안정화 상태]**.

### 2.5 모바일 앱 스택

**[결정] Flutter(Dart) 단일 코드베이스 + 플랫폼 경계 3개를 인터페이스로 격리.**

| 계층 | 구현 | iOS 추가 시 |
| --- | --- | --- |
| UI, 상태, API 클라이언트, 로컬 DB(SQLite), 가사 파서, 대기열/셔플/반복 로직 | 순수 Dart | 그대로 |
| `PlaybackEngine` (재생·미디어 세션) | `just_audio` + `audio_service` (Android: ExoPlayer, iOS: AVPlayer) | 동일 패키지, 설정·검증 별도 |
| `DownloadEngine` (백그라운드 전송) | `background_downloader` (Android: WorkManager/UIDT, iOS: URLSession) | 동일 패키지, 제약 다름(03장 §5.10) |
| `SecureStore` (토큰) | `flutter_secure_storage` (Android Keystore / iOS Keychain) | 동일 |

근거와 주의:

- 한 사람(또는 소수)이 Android와 향후 iOS를 유지하려면 UI·상태·오프라인 로직을 한 번만 쓰는 편이 현실적이다.
- 세 패키지 모두 2026년 6~9월에 릴리스가 있고 라이선스는 MIT/Apache-2.0/BSD-3-Clause 계열이다. **[확인 필요]** 채택 시점에 버전·라이선스·열린 이슈를 다시 확인하고 `pubspec.lock`으로 고정한다.
- `audio_service`는 Media3 `MediaSessionService`가 아니라 레거시 `MediaBrowserServiceCompat` 기반이다. 동작에는 문제가 없으나 Android 정책이 바뀌면 교체가 필요할 수 있다. 그래서 앱 코드는 패키지를 직접 부르지 않고 `PlaybackEngine` 인터페이스만 사용한다. 교체 후보는 Media3 `MediaSessionService`/AVQueuePlayer를 감싼 자체 플러그인이다.
- `just_audio`의 HTTP 헤더 기능은 로컬 HTTP 프록시(평문 localhost)로 구현되어 있다. 이를 피하려고 **미디어 요청은 헤더 대신 단기 미디어 티켓을 URL에 넣는 방식**을 계약에 포함했다(02장 §1.4).
- 개발 PC가 Windows이므로 Android 빌드는 가능, iOS 빌드·서명·실기기 검증은 macOS/Xcode가 별도로 필요하다.

| 대안 | 채택하지 않은 이유 |
| --- | --- |
| Android 네이티브(Kotlin + Compose + Media3) → 이후 Swift로 iOS 재작성 | 재생·다운로드 품질은 가장 좋으나 iOS에서 UI·오프라인 로직을 전부 다시 써야 한다. |
| Kotlin Multiplatform + Compose Multiplatform | 로직 공유 가능하고 Android에서 Media3를 직접 쓴다. iOS 오디오/다운로드는 Swift 구현이 따로 필요. Flutter 패키지가 요구를 못 채울 때의 2순위. |
| React Native | JS 재사용 가능하나 백그라운드 오디오/다운로드 라이브러리의 유지 상태가 불확실. |

### 2.6 Android 플랫폼 조건 (2026-10 기준)

- Google Play 신규 앱/업데이트는 **API 36(Android 16) 이상 타깃** 필요(2026-08-31부터). `targetSdk=36`, `compileSdk=36`으로 시작한다.
- **Android 17(API 37)을 타깃하면 로컬 네트워크 접근이 기본 차단**되고 `ACCESS_LOCAL_NETWORK` 런타임 권한(또는 시스템 선택기)이 필요하다. 이 앱은 LAN IP의 서버에 접속하는 것이 핵심 사용례이므로, targetSdk를 37로 올리는 시점에 반드시 대응해야 한다. API 36 타깃 동안에는 `adb shell am compat enable RESTRICT_LOCAL_NETWORK <패키지>`로 미리 시험한다. UI에 권한 안내 상태를 포함했다(04장 S1). **[P5 시험 2026-10-04]** SM-S948N(Android 16, 빌드 S948NKSU4AZHJ)에서 이 플래그를 켜고 앱을 다시 시작해도 LAN 서버(192.168.1.173) 요청이 그대로 성공했다(서버 기록으로 확인) — 이 기기에서는 차단이 적용되지 않아 실제 오류 모양을 관찰하지 못했다. 개발 PC는 하이퍼바이저가 꺼져 있어 API 37 에뮬레이터도 쓸 수 없었다. 앱은 소켓이 EPERM으로 거부되면 `localNetworkDenied`로 분류해 S1에 "집 안 네트워크의 서버에 연결하려면 권한이 필요합니다" + 앱 설정 열기를 보인다(단위·위젯 시험). **[확인 필요]** Android 17 기기 또는 에뮬레이터에서 실제 오류 모양과 필요한 권한(`ACCESS_LOCAL_NETWORK` 등)·런타임 요청 흐름 — targetSdk 37로 올리기 전에.
- 포그라운드 서비스: 재생은 `mediaPlayback` 유형. 다운로드는 WorkManager/사용자 시작 데이터 전송(UIDT, Android 14+)을 쓴다.
- `minSdk`: **API 26(Android 8.0)** — 사용자 위임으로 설계 제안값을 확정(2026-10-03).
- 네이티브 라이브러리 16KB 페이지 크기 대응 여부를 릴리스 전 점검한다 **[확인 필요]**.

### 2.7 플랫폼별 오디오 형식

원칙: **서버가 원본 형식과 제공 형식을 구분하고, 앱이 "재생 가능한 형식 목록"을 보내면 서버가 원본 제공/변환을 결정한다.** 앱이 형식 호환성을 추측하지 않는다.

| 원본 | Android(ExoPlayer, 플랫폼 디코더) | iOS(AVPlayer) | 1차 정책 |
| --- | --- | --- | --- |
| MP3, AAC(M4A) | 재생 | 재생 | 원본 제공 |
| FLAC | 재생(API 27+ 플랫폼 디코더) | 재생 **[확인 필요]** | 원본 제공 |
| Ogg Vorbis / Opus | 재생 | 미지원으로 가정 **[확인 필요]** | Android 원본, iOS 변환 |
| ALAC(M4A) | 플랫폼 디코더 없음으로 가정 **[확인 필요]** | 재생 | Android 변환, iOS 원본 |
| WAV/AIFF, DSD, APE, WMA 등 | 일부만 | 일부만 | 앱이 지원 목록에 넣지 않은 것은 변환 |

변환 대상 프로파일은 양 플랫폼 공통으로 재생되는 **AAC-LC in M4A**로 통일한다(03장 §4.5). 표의 [확인 필요] 항목은 P3에서 합성 음원으로 실기기 확인 후 앱의 지원 목록에 반영한다.

---

## 3. 아키텍처

### 3.1 역할 분담

```text
┌──────────────── 앱 (Android / 향후 iOS) ────────────────┐
│ UI ─ 상태(대기열·재생·다운로드) ─ 로컬 DB ─ 파일 캐시       │
│  │            │                    │                    │
│ ApiClient  PlaybackEngine      DownloadEngine           │
└────┬───────────┬────────────────────┬───────────────────┘
     │ JSON      │ Range 스트림         │ Range 다운로드
     ▼           ▼                    ▼
┌──────────────── bangmusic-server (단일 프로세스) ─────────┐
│ HTTP API ─ 인증/권한 ─ 카탈로그 ─ 플레이리스트 ─ 가사/기록    │
│ 스캐너(파일→곡 매핑) ─ 변환 작업자(FFmpeg) ─ 미디어 제공     │
│        │               │                  │             │
│     /music (ro)     /cache (rw)        /data (rw, SQLite)│
└─────────────────────────────────────────────────────────┘
```

| 서버가 한다 | 앱이 한다 |
| --- | --- |
| 계정·세션·권한 판정 | 실제 소리 재생, 볼륨, 오디오 포커스 |
| 파일 스캔, 영속 ID 부여, 메타데이터·표지·가사 제공 | 대기열, 셔플/반복, 현재 위치 (기기 로컬 상태) |
| 원본/변환본을 Range로 제공 | 다운로드·무결성 검증·오프라인 라이브러리 |
| 플레이리스트·재생 기록의 원본 보관 | 오프라인 중 변경·기록을 쌓아 두었다가 동기화 |

서버는 **재생 리모컨이 아니다.** 서버에는 "현재 재생 중" 상태나 전역 대기열이 없다. 대기열은 기기별 로컬 상태다.

### 3.2 서버 내부 모듈

| 모듈 | 책임 | 의존 |
| --- | --- | --- |
| `http` | 라우팅, 스키마 검증, 오류 변환(problem+json), 요청 ID, 속도 제한 | 전부 |
| `auth` | 로그인, 토큰 발급/회전/폐기, 미디어 티켓 서명/검증, 권한 판정 | `store` |
| `catalog` | 곡/앨범/아티스트 조회, 검색, 변경 피드 | `store` |
| `scanner` | 라이브러리 순회, 태그 추출(ffprobe), 영속 ID 매핑, 누락 표시 | `store`, 파일시스템(ro) |
| `media` | 렌디션 결정, Range 응답, 표지 썸네일 | `store`, `transcode`, 파일시스템 |
| `transcode` | 작업 큐, FFmpeg 실행, 캐시 수명 관리 | `store`, `/cache` |
| `playlists`, `lyrics`, `history` | 각 도메인 CRUD | `store` |
| `store` | SQLite 접근, 마이그레이션, 백업 | — |

파일 경로를 다루는 코드는 `scanner`와 `media`의 **경로 해석기 하나**로 제한한다. 경로 해석기 규칙:

1. 입력은 `(library_id, relative_path)`뿐이다. HTTP 요청에서 온 문자열은 절대 입력이 될 수 없고, 항상 DB에서 읽은 값만 쓴다.
2. `realpath`로 해석한 결과가 해당 라이브러리 루트의 `realpath` 하위가 아니면 거부한다(심볼릭 링크 탈출 차단).
3. 일반 파일이 아니면 거부한다(디렉터리, 장치, FIFO).
4. 열기에 성공한 파일 디스크립터로 `fstat` 하여 크기/mtime이 DB의 미디어 버전과 다르면 "원본 변경"으로 처리한다(§4.3).

### 3.3 앱 내부 구조

```text
lib/
  core/        api_client, models(OpenAPI에서 생성), error, connectivity
  data/        local_db(drift/SQLite), repositories(서버+로컬 병합), sync
  domain/      queue(셔플/반복), lyrics(LRC 파서), download_state_machine, playback_state
  platform/    playback_engine(+ just_audio 구현), download_engine(+ 구현), secure_store
  ui/          tokens, components, screens
```

- `domain/`은 Flutter·플랫폼 패키지에 의존하지 않는 순수 Dart다. 기존 테스트의 규칙을 이식한 단위 테스트가 여기에 붙는다.
- API 모델·클라이언트는 `openapi.yaml`에서 생성한다. 수작업 모델을 두지 않는다.

---

## 4. 데이터 모델 (서버)

### 4.1 ID 규칙

- 모든 공개 ID는 **유형 접두어 + ULID** 문자열(예: `trk_01JB2M4X7Q9ZK3V5T8N6R1WY0E`). 앱은 불투명 문자열로만 취급한다.
- ID는 **파일 경로와 무관**하게 최초 발견 시 생성되어 DB에 저장된다. 경로 해시를 ID로 쓰는 기존 Windows 방식은 사용하지 않는다(대소문자·이동·OS 차이로 깨진다).
- 접두어: `srv_` 서버, `usr_` 사용자, `ses_` 세션, `lib_` 라이브러리, `trk_` 곡, `alb_` 앨범, `art_` 아티스트, `pl_` 플레이리스트, `pli_` 플레이리스트 항목, `rnd_` 렌디션, `img_` 표지, `job_` 작업, `evt_` 기록 이벤트(클라이언트 생성 UUID).

### 4.2 테이블

타입은 SQLite 기준. 시간은 UTC epoch 밀리초(`INTEGER`). `*_id`는 위 규칙의 `TEXT`.

**서버·계정**

| 테이블 | 주요 컬럼 | 설명 |
| --- | --- | --- |
| `server_meta` | `server_id`, `name`, `created_at`, `signing_key_id` | 단일 행. `server_id`는 최초 기동 시 생성, 백업 복원 후에도 유지 → 앱의 캐시 분리 키. |
| `users` | `id`, `username`(UNIQUE, NFKC+소문자), `display_name`, `password_hash`(Argon2id), `role`(`admin`/`member`), `status`(`active`/`disabled`), `created_at`, `deleted_at` | |
| `sessions` | `id`, `user_id`, `device_name`, `platform`, `app_version`, `refresh_hash`, `refresh_family`, `prev_refresh_hash`, `access_hash`, `access_expires_at`, `refresh_expires_at`, `created_at`, `last_seen_at`, `revoked_at`, `revoke_reason` | 토큰은 해시만 저장. 기기 1대 = 세션 1개. |
| `libraries` | `id`, `name`, `root_path`(서버 내부 전용, API 비공개), `status`(`online`/`unavailable`), `last_scan_at`, `revision` | |
| `user_library_access` | `user_id`, `library_id` | 관리자는 전체 접근. |

**카탈로그**

| 테이블 | 주요 컬럼 | 설명 |
| --- | --- | --- |
| `tracks` | `id`, `library_id`, `album_id`, `title`, `title_sort`, `title_norm`, `artist_display`, `disc_no`, `track_no`, `duration_ms`, `year`, `genre`, `artwork_id`, `media_version`, `state`(`available`/`missing`), `missing_since`, `added_at`, `updated_at`, `change_seq` | 사용자에게 보이는 곡. |
| `media_files` | `id`, `track_id`(UNIQUE), `library_id`, `rel_path`, `size_bytes`, `mtime_ns`, `content_hash`(SHA-256), `audio_fingerprint`, `container`, `codec`, `bitrate`, `sample_rate`, `channels`, `bit_depth`, `scanned_at` | **원본 파일 매핑.** `(library_id, rel_path)` UNIQUE. API로 노출되지 않는다. |
| `albums` | `id`, `title`, `title_sort`, `title_norm`, `album_artist_id`, `year`, `artwork_id`, `change_seq` | |
| `artists` | `id`, `name`, `name_sort`, `name_norm`, `change_seq` | |
| `track_artists` | `track_id`, `artist_id`, `role`, `position` | |
| `artworks` | `id`, `source`(`embedded`/`folder`/`upload`), `content_hash`, `mime`, `width`, `height`, `storage_ref` | 내용 해시로 중복 제거. |
| `search_fts` | FTS5(trigram) 가상 테이블: `entity_type`, `entity_id`, `text_norm` | §4.6 |
| `tombstones` | `entity_type`, `entity_id`, `change_seq`, `deleted_at` | 변경 피드의 삭제 통지용. |

**플레이리스트·가사·기록**

| 테이블 | 주요 컬럼 | 설명 |
| --- | --- | --- |
| `playlists` | `id`, `owner_id`, `name`, `description`, `artwork_id`, `version`(정수, 변경마다 +1), `created_at`, `updated_at`, `deleted_at` | 1차는 소유자 전용. |
| `playlist_items` | `id`, `playlist_id`, `track_id`, `position_key`(분수 인덱스 문자열), `added_at` | 같은 곡 중복 허용이므로 항목 ID가 따로 있다. |
| `lyrics` | `track_id`, `kind`(`original`/`pronunciation_ko`/`translation_ko`), `format`(`lrc`/`plain`), `language`, `body`, `source_type`(`sidecar`/`embedded`/`user`/`provider`), `source_name`, `license_note`, `version`, `updated_at` | PK `(track_id, kind)`. 출처·이용 조건을 반드시 기록. |
| `lyrics_prefs` | `user_id`, `track_id`, `offset_ms` | 사용자별 동기화 보정. |
| `play_events` | `event_id`(PK, 클라이언트 생성 UUID), `user_id`, `session_id`, `track_id`, `started_at`, `played_ms`, `completed`, `source`(`stream`/`offline`), `context_type`, `context_id`, `received_at` | PK 충돌 = 중복 재전송 → 무시. |
| `track_stats` | `user_id`, `track_id`, `play_count`, `last_played_at` | `play_events`에서 유도. 홈의 최근/많이 들은 곡. |

**변환·작업**

| 테이블 | 주요 컬럼 | 설명 |
| --- | --- | --- |
| `renditions` | `id`, `track_id`, `media_version`, `profile`, `state`(`ready`/`preparing`/`failed`), `mime`, `size_bytes`, `duration_ms`, `sha256`, `cache_ref`, `created_at`, `last_access_at`, `error_code` | `(track_id, media_version, profile)` UNIQUE. `profile=original`은 캐시 파일 없이 원본을 가리킨다. |
| `jobs` | `id`, `type`(`transcode`/`scan`/`hash`/`backup`), `ref_id`, `state`(`queued`/`running`/`succeeded`/`failed`/`canceled`), `attempts`, `not_before`, `started_at`, `finished_at`, `error_code`, `error_detail` | 프로세스 재시작 시 `running`은 `queued`로 되돌린다. |
| `schema_migrations` | `version`, `applied_at`, `checksum` | |

### 4.3 영속 곡 ID와 원본 파일 매핑

스캔 시 파일 하나에 대해 다음 순서로 곡을 찾는다.

1. `(library_id, rel_path)` 일치 → 같은 곡. `size_bytes`/`mtime_ns`가 바뀌었으면 재분석하고 **미디어 버전을 갱신**한다.
2. 경로가 없으면 `content_hash`가 같은 `missing` 상태의 매핑을 찾는다 → **이동/이름 변경**으로 보고 `rel_path`만 갱신. 곡 ID·플레이리스트·기록 유지.
3. 그래도 없으면 `audio_fingerprint`(태그를 제외한 오디오 페이로드의 해시)가 같은 `missing` 매핑을 찾는다 → **태그만 수정된 뒤 이동**한 경우. 후보가 정확히 1개일 때만 연결한다.
4. 모두 실패하면 새 `trk_` ID를 만든다.

**미디어 버전**: `media_version = base32(sha256(content_hash))[0:16]`. 원본 바이트가 바뀌면 값이 바뀐다. 태그만 고쳐도 바이트가 바뀌므로 버전이 바뀐다(다운로드본이 낡았음을 정확히 알릴 수 있다). `content_hash` 계산은 비용이 크므로 스캔 시 `size+mtime`이 그대로면 재계산하지 않는다.

**삭제 처리**: 스캔에서 파일이 안 보이면 `tracks.state='missing'`, `missing_since=now`로만 표시한다. 플레이리스트 항목·기록은 유지한다. 영구 삭제(tombstone 발행)는 관리자가 명시적으로 "누락 곡 정리"를 실행했을 때만 한다.

### 4.4 저장소 일시 장애

- 스캔 시작 전 라이브러리 루트에 `.bangmusic-library` 표식 파일이 있는지 확인한다(라이브러리 등록 시 관리자가 만들거나, 읽기 전용이면 "루트가 비어 있지 않음"으로 대체). 확인 실패 시 **스캔을 중단**하고 `libraries.status='unavailable'`로 둔다. 어떤 곡도 `missing`으로 바꾸지 않는다.
- 한 번의 스캔에서 기존 곡의 일정 비율 이상(기본 20%, 설정값)이 사라진 것으로 나오면 결과를 적용하지 않고 관리자 확인 대기 상태로 둔다.
- 재생 요청 중 파일 열기가 I/O 오류/마운트 없음으로 실패하면 `503 storage_unavailable`(재시도 가능), 파일만 없으면 `404 media_missing`으로 **구분**한다.
- **자동 복구 [P6 추가]**: `unavailable`인 라이브러리에 재생·렌디션 요청이 오면 루트를 다시 확인한다(실제 경로가 등록 때와 같고 비어 있지 않음). 정상이면 `online`으로 되돌리고 스캔을 예약한 뒤 요청을 그대로 처리한다. 이유: P6 실서버 FN-07에서 재마운트 뒤에도 수동 스캔 전까지 503이 계속됐다. NAS가 잠깐 끊겼다 돌아오는 흔한 경우에 사용자가 할 일이 없어야 한다. 마운트가 빠져 빈 폴더만 남은 경우도 "마운트 없음"으로 보아 첫 요청부터 503이다.

### 4.5 접근 권한

| 자원 | 규칙 |
| --- | --- |
| 곡/앨범/아티스트/표지/가사/렌디션 | 사용자가 해당 `library_id`에 접근 권한이 있어야 한다. 없으면 `404 not_found`(존재 노출 방지). 앨범·아티스트는 접근 가능한 곡이 1개 이상일 때만 보인다. |
| 플레이리스트 | 소유자만 조회/수정. 타인 것은 `404`. 관리자도 타인의 플레이리스트 내용을 API로 볼 수 없다. |
| 재생 기록·가사 보정 | 본인 것만. |
| 관리 API(`/v1/admin/*`) | `role=admin`. 아니면 `403 forbidden`. |
| 미디어 티켓 | 발급 시점의 사용자·세션·렌디션에 묶인다. 세션이 폐기되면 티켓도 즉시 무효. |

플레이리스트에 접근 권한이 사라진 라이브러리의 곡이 있으면 항목은 남기되 응답에서 `"available": false`인 자리표시자로 내려 준다(순서 보존).

### 4.6 검색과 일본어 표기

- 정규화 함수 `norm()`: NFKC → 소문자 → 가타카나를 히라가나로 → 전각/반각 통일 → 공백 축약. `*_norm` 컬럼과 FTS 색인, 그리고 질의어에 동일하게 적용한다.
- FTS5 **trigram** 토크나이저로 부분 문자열 검색(3자 이상). 1~2자 질의는 `*_norm LIKE` 접두 검색으로 대체한다.
- 정렬은 태그의 정렬용 필드(`TITLESORT`, `ARTISTSORT`, `ALBUMSORT`)가 있으면 사용, 없으면 `norm(title)`. 한자 읽기를 서버가 추측하지 않는다.
- 색인 대상: 곡 제목, 아티스트명, 앨범명, 그리고 태그에 있는 경우 로마자/읽기 별칭.

### 4.7 변경 감지

- 카탈로그 행은 수정될 때마다 전역 단조 증가 `change_seq`를 받는다. 삭제는 `tombstones`에 기록한다.
- 앱은 `GET /v1/changes?since=<seq>`로 증분 동기화한다. tombstone 보존 기간(기본 90일)보다 오래된 `since`는 `410 sync_token_expired` → 앱은 전체 재동기화한다.
- 플레이리스트는 `version` 정수 + HTTP `ETag`로 동시 수정 충돌을 감지한다(02장).

### 4.8 P1 구현에서 추가·변경한 것 (2026-10-02)

실제 스키마는 `server/src/db/migrations/0001_init.sql`이 기준이다. §4.2 표에서 달라진 점과 이유:

| 위치 | 변경 | 이유 |
| --- | --- | --- |
| `server_meta` | `change_seq`, `tombstone_horizon_seq` 추가 | 전역 단조 증가 값을 DB 한 곳에서 발급(§4.7). 보존 기간보다 오래된 `since`를 410으로 판정하는 기준. |
| `sessions` | `installation_id`, `rotated_at`, `rotation_blob` 추가 | 같은 설치로 재로그인 시 이전 세션 대체(계약 `DeviceInfo`). 리프레시 60초 재시도 유예 동안 **같은 새 토큰 쌍**을 돌려주려면 원문이 필요해, 서명 키에서 유도한 키로 AES-GCM 암호화해 유예 시간 동안만 둔다. |
| `libraries` | `root_real`, `pending_review` 추가 | 등록 시 realpath 고정(SEC-04), 대량 누락 보류 상태(§4.4, `AdminLibrary.pending_review`). |
| `albums` | `library_id`, `group_key`, `sort_key`, `added_at` 추가 | 앨범은 라이브러리 안에서 (앨범 아티스트, 제목)으로 묶는다. 라이브러리가 다르면 다른 앨범이므로 접근 권한 판정이 앨범 단위로 단순해진다. 정렬·keyset 페이지에 쓰는 키를 미리 계산해 둔다. |
| `tracks`, `artists` | `sort_key` 추가 | 정렬 태그가 있으면 `norm(정렬 태그)`, 없으면 `norm(제목)` (§4.6). |
| `media_files` | `mime` 추가, `mtime_ns`는 문자열 | 나노초 정밀도 보존. |
| `tombstones` | `library_id` 추가 | 삭제 통지도 접근 권한으로 거른다. |
| `artworks` | `storage_ref`는 긴 변 1024px 이하로 다시 인코딩한 JPEG 마스터 | 표지 응답이 음악 원본을 다시 읽지 않게 하고(원본 경로 접근을 경로 해석기로 한정), 6000px 같은 큰 원본을 그대로 들고 다니지 않는다. 메타데이터(EXIF)도 이때 제거된다. 작은 크기는 요청 시 `/cache/artwork`에 만든다. |
| `jobs` | `created_at`, `progress` 추가 | 대기열 순서와 `Job.progress`. |
| 스캔 | 모든 파일에 `audio_fingerprint`(FFmpeg `-c copy -f hash`)를 저장 | §4.3 3단계는 기존 행에 지문이 있어야 동작한다. 처음에는 새 파일에만 계산해 매칭이 되지 않는 결함이 테스트로 드러나 고쳤다. |

P2(`0002_p2.sql`)에서 추가:

| 위치 | 변경 | 이유 |
| --- | --- | --- |
| `playlists` | `name_norm` | 플레이리스트 이름 검색(`types=playlist`). |
| `lyrics` | `content_hash` | 사이드카가 바뀌었는지 판단(바뀐 것만 반영하고 버전을 올린다). |
| `lyrics_versions` (신규) | 곡별 가사 묶음 버전 | `Lyrics.version`과 ETag. 종류별 행이 따로라 곡 단위 버전이 필요하다. |
| `play_events` | `counted` | 03장 §6.9 기준(30초 또는 50%)을 넘었는지. 최근·많이 들은 곡은 센 것만 쓴다. |
| `idempotency_keys` (신규) | (사용자, 키, 동작) → 처음 응답 | `Idempotency-Key` 재요청에 처음 결과를 그대로 돌려준다(24시간). |
| `jobs` | `priority` | stream 변환이 download보다 먼저 (03장 §4.6). |
| `scan_failures` (신규) | 분석 실패 파일의 크기·mtime | 크기·mtime이 그대로면 다시 분석하지 않는다(P1 알려진 제한 2 해소). |

백업(§5.2) 구현: 스냅샷은 `/data/backups/<UTC>-<이유>/{db.sqlite, secrets/signing.key}`, 표지 마스터는 `/data/backups/artwork/`에 증분 복사. 마이그레이션 전 스냅샷도 같은 형식이다. 복원(§5.3)은 서버 pid 파일로 실행 중이면 거부하고, **교체 전 DB에 있던 세션을 옮겨 온다** — 스냅샷 이후에 리프레시 토큰이 회전했어도 앱이 재로그인 없이 복귀하게 하기 위해서다. **[알려진 제한]** DB 파일 자체를 잃은 경우(교체 전 DB 없음)에는 스냅샷 이후 회전한 리프레시 토큰을 알 수 없으므로, 그 사이 토큰을 갱신한 기기는 다시 로그인해야 한다.

---

## 5. 마이그레이션 · 백업 · 복구

### 5.1 마이그레이션

- 번호가 붙은 SQL 파일(`0001_init.sql` …), **전진 전용**. 적용 기록과 체크섬을 `schema_migrations`에 남긴다. 이미 적용된 파일의 체크섬이 다르면 기동을 거부한다.
- 서버 기동 시: (1) DB 무결성 검사(`PRAGMA quick_check`) → (2) 적용할 마이그레이션이 있으면 **먼저 스냅샷 백업** → (3) 한 트랜잭션으로 적용 → (4) 실패 시 롤백하고 기동 중단(부분 적용 상태로 서비스하지 않는다).
- DB 스키마 버전이 실행 파일이 아는 버전보다 **높으면** 기동을 거부한다(이미지를 내렸을 때 데이터 손상 방지). 내리려면 직전 스냅샷을 복원한다.
- 호환성 규칙: 한 릴리스에서 컬럼을 추가하고, 다음 릴리스에서 사용 전환, 그 다음에 옛 컬럼 삭제.

### 5.2 백업

| 대상 | 방법 | 주기(기본값) |
| --- | --- | --- |
| SQLite DB | `VACUUM INTO '/data/backups/db-<UTC>.sqlite'` (온라인, 일관된 스냅샷) | 매일 1회 + 마이그레이션 직전. 최근 N개 보존(기본 14). |
| 업로드 표지(`/data/uploads`) | 파일 복사(내용 해시 이름이라 증분) | DB와 함께 |
| 서명 키·설정 | `/data/secrets`를 백업 묶음에 포함(권한 600) | DB와 함께 |
| 변환 캐시(`/cache`) | 백업하지 않음(재생성 가능) | — |
| 음악 원본 | 이 서버의 책임 범위 밖. 구매자 문서에 명시. | — |

`/data/backups`는 같은 디스크이므로 디스크 고장에 대비하지 못한다. 설치 문서에서 VM 백업(Proxmox vzdump/PBS) 또는 외부 복사를 권장한다.

### 5.3 복구

`bangmusic-server restore <스냅샷>` 명령:

1. 서버 정지 상태 확인 → 스냅샷 무결성 검사.
2. 현재 DB를 `db-pre-restore-<UTC>.sqlite`로 보관 후 교체.
3. 기동 시 필요한 마이그레이션 적용.
4. `renditions` 중 캐시 파일이 없는 행은 삭제(다음 요청 때 재생성).
5. 모든 세션의 **액세스 토큰**만 무효화(리프레시는 유지) → 앱은 자동 갱신으로 복귀.

복원 후 `server_id`는 그대로이므로 앱의 다운로드본은 유지된다. 복원으로 곡 ID가 사라진 다운로드본은 다음 동기화 때 "서버에 없음"으로 표시된다(03장 §5.4).

**수용 기준**: 스냅샷 생성 → DB 파일 삭제 → 복원 → 로그인·목록·플레이리스트·재생 기록이 스냅샷 시점과 같음을 자동 테스트로 확인(05장 P2).

---

## 6. 앱 쪽 모델 요약 (상세는 03장 §5.2)

- **서버 프로필**: 앱은 여러 서버를 등록할 수 있고, 프로필의 키는 서버가 주는 `server_id`다. 곡 ID·캐시·다운로드·플레이리스트 사본·대기열은 모두 `(server_id, user_id)` 범위 안에서만 유효하며 프로필 사이에 공유하지 않는다.
- **앱 구매 권한과 서버 인증의 분리**: 구매 상태는 `EntitlementService`가 스토어에서만 얻고, 서버 프로필·토큰·라이브러리와 데이터 경로를 공유하지 않는다(05장 §8.2).
- **중앙 서버 없음**: 앱은 구매자의 서버와 스토어 외에는 통신하지 않는다. 음악 목록·재생 기록·서버 접속 비밀값을 판매자 측으로 보내는 경로가 없다.
- **서버가 앱보다 오래된 경우**: `api.minor`와 `features`로 기능을 판단해 낮은 서버에서는 해당 기능을 숨긴다(02장 §2.2).
