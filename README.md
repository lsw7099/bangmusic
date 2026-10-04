# BangMusic

자가호스팅 음악 서버와 Android(향후 iOS) 앱. 설계는 [docs/design/](docs/design/README.md), 작업 규칙은 [CLAUDE.md](CLAUDE.md).

현재 단계: **P3 (Android 앱)** 진행 중 — [docs/status/P3.md](docs/status/P3.md). 이전: [P2](docs/status/P2.md), [P1](docs/status/P1.md), [P0](docs/status/P0.md). 시험 설치: [Proxmox LXC](docs/status/deploy-proxmox-lxc-trial.md).

## 구조

| 경로 | 내용 |
| --- | --- |
| `docs/design/` | 설계 문서와 API 계약 `openapi.yaml` (계약의 기준) |
| `server/` | 서버(TypeScript + Fastify + node:sqlite). 빌드 없이 Node 24로 실행 |
| `packages/bangmusic_api/` | OpenAPI에서 생성한 Dart API 클라이언트. 앱이 path 의존성으로 쓴다 |
| `app/` | Flutter 앱 (P3 진행 중. 패키지 ID·제품명·`minSdk`는 임시값) |
| `tools/codegen/` | 코드 생성 스크립트 |
| `tools/make-fixtures/` | 합성 음원 생성기 |
| `tools/doctor.mjs` | 개발 환경 점검 |

## 명령

```bash
npm ci                    # 개발 도구 설치
npm run doctor            # 개발 환경 점검
npm run lint:openapi      # OpenAPI 린트 (Redocly, redocly.yaml)
npm run gen               # 서버 타입·스키마 + Dart 클라이언트 생성
npm run fixtures -- --clean [--quick]   # 합성 음원 → fixtures/ (FFmpeg 필요)
```

`openapi.yaml`을 고치면 `npm run gen`을 실행하고 생성 결과도 함께 커밋한다. CI가 불일치를 막는다.

## 서버 실행 (개발)

```bash
export BANGMUSIC_DATA_DIR=./.tmp-dev/data BANGMUSIC_CACHE_DIR=./.tmp-dev/cache BANGMUSIC_PORT=8080
node server/src/main.ts admin create <사용자이름>       # 비밀번호는 대화형 입력
node server/src/main.ts library add "내 음악" <음악 폴더>
node server/src/main.ts scan
node server/src/main.ts serve
```

테스트: `npm run fixtures -- --clean --quick` 후 `npm test --workspace server`. FFmpeg가 PATH에 없으면 `FFMPEG`, `FFPROBE` 환경 변수로 지정한다.
