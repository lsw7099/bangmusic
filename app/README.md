# app/ — Flutter 앱

아직 비어 있다. Flutter SDK를 설치한 뒤 P0에서 빈 앱을 만들어 실기기 설치를 확인한다.

```bash
flutter create --org <패키지 접두어 미정> --project-name bangmusic --platforms android,ios app
```

- 패키지 ID·제품명·`minSdk`는 **임시값**이다(README §4 미결, `docs/status/P3.md`). 스토어 등록 전에 확정한다.
- `targetSdk`/`compileSdk` = 36 (01장 §2.6).
- 구조는 01장 §3.3의 `lib/core|data|domain|platform|ui`를 따른다.
- API 클라이언트는 `../packages/bangmusic_api`(생성물)를 path 의존성으로 쓴다. 수작업 모델을 두지 않는다.
