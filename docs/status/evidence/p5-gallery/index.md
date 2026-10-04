# P5 화면×상태 갤러리

생성: `flutter test --tags screenshots test/screenshots/gallery_test.dart` (가짜 서버·가짜 플레이어, 360×780dp, 1.5배 저장). 수준 L1.

| 화면 | 상태 | 그림 |
| --- | --- | --- |
| S1 서버 연결 | 첫 실행(빈 목록 = 이 화면) | ![s1-01-first](s1-01-first.png) |
| S1 서버 연결 | 서버 확인 카드 → 로그인 | ![s1-02-card](s1-02-card.png) |
| S1 서버 연결 | 오류: 연결 불가 | ![s1-03-unreachable](s1-03-unreachable.png) |
| S1 서버 연결 | 오류: 인증서 | ![s1-04-certificate](s1-04-certificate.png) |
| S1 서버 연결 | 오류: BangMusic 서버 아님 | ![s1-05-not-bangmusic](s1-05-not-bangmusic.png) |
| S1 서버 연결 | 오류: 로컬 네트워크 권한 없음 | ![s1-06-local-network](s1-06-local-network.png) |
| S1 서버 연결 | 오류: 초기 설정 필요 | ![s1-07-setup](s1-07-setup.png) |
| S1 서버 연결 | 버전 불일치: 서버 낮음 | ![s1-08-server-old](s1-08-server-old.png) |
| S1 서버 연결 | 버전 불일치: 앱 낮음 | ![s1-09-app-old](s1-09-app-old.png) |
| S1 서버 연결 | 등록된 서버 목록 | ![s1-10-saved](s1-10-saved.png) |
| S1 서버 연결 | 큰 글씨 2.0 | ![s1-11-big-text](s1-11-big-text.png) |
| S1 서버 연결 | 오류: 로그인 실패(5회 후 대기 시간) | ![s1-12-login-failed](s1-12-login-failed.png) |
| S1 서버 연결 | 오프라인(저장된 서버는 오프라인으로 계속) | ![s1-13-offline](s1-13-offline.png) |
| S2 홈 | 기본 | ![s2-01-home](s2-01-home.png) |
| S2 홈 | 다크 테마 | ![s2-02-home-dark](s2-02-home-dark.png) |
| S2 홈 | 빈 목록(서버에 음악 없음) | ![s2-03-empty](s2-03-empty.png) |
| S2 홈 | 오류 | ![s2-04-error](s2-04-error.png) |
| S2 홈 | 빈 목록: 플레이리스트 없음("첫 플레이리스트 만들기") | ![s2-07-first-playlist](s2-07-first-playlist.png) |
| S2 홈 | 큰 글씨 2.0 | ![s2-05-big-text](s2-05-big-text.png) |
| 공통 | 세션 만료 배너 | ![c-01-expired](c-01-expired.png) |
| 공통 | 서버 연결 불가 배너 | ![c-02-unreachable](c-02-unreachable.png) |
| 공통 | 오프라인 배너 | ![c-03-offline](c-03-offline.png) |
| 공통 | 서버 점검 배너 | ![c-04-maintenance](c-04-maintenance.png) |
| 공통 | 앱 업데이트 필요 배너 | ![c-05-update](c-05-update.png) |
| 공통 | 같은 주소 다른 서버 배너 | ![c-06-server-changed](c-06-server-changed.png) |
| 공통 | 접근 취소 전체 화면 | ![c-07-revoked](c-07-revoked.png) |
| S3 라이브러리 | 앨범 2열 격자 | ![s3-01-albums](s3-01-albums.png) |
| S3 라이브러리 | 곡 목록 | ![s3-02-tracks](s3-02-tracks.png) |
| S3 라이브러리 | 아티스트 | ![s3-03-artists](s3-03-artists.png) |
| S3 라이브러리 | 빈 목록(+ 새 플레이리스트) | ![s3-04-empty](s3-04-empty.png) |
| S3 라이브러리 | 오류(첫 페이지) | ![s3-05-error](s3-05-error.png) |
| S3 라이브러리 | 큰 글씨 2.0(격자 → 1열) | ![s3-06-big-text](s3-06-big-text.png) |
| S3 라이브러리 | 오프라인("다운로드한 항목만" 자동) | ![s3-07-offline](s3-07-offline.png) |
| S2 홈 | 오프라인(받은 음악) | ![s2-06-offline](s2-06-offline.png) |
| S4 검색 | 오프라인(로컬 검색) | ![s4-05-offline](s4-05-offline.png) |
| S5 앨범 | 오프라인(다운로드한 n곡 재생) | ![s5-03-offline](s5-03-offline.png) |
| S7 미니 플레이어 | 오프라인(받은 곡 재생 중 아이콘) | ![s7-06-offline](s7-06-offline.png) |
| S8 몰입 화면 | 오프라인(받지 않은 곡 흐림 + 오프라인에서 건너뜀) | ![s8-12-offline-queue](s8-12-offline-queue.png) |
| S2 홈 | 로딩(자리표시자) | ![s2-08-loading](s2-08-loading.png) |
| S3 라이브러리 | 오류: 다음 페이지 실패(목록 끝 다시 시도) | ![s3-08-next-page-error](s3-08-next-page-error.png) |
| S4 검색 | 로딩(이전 결과 흐리게) | ![s4-07-loading](s4-07-loading.png) |
| S8 몰입 화면 | 빈 목록: 대기열(이어서 재생할 곡 없음) | ![s8-11-queue-empty](s8-11-queue-empty.png) |
| S10 설정 | 세션 목록 로딩 | ![s10-07-sessions-loading](s10-07-sessions-loading.png) |
| S10 설정 | 세션 목록: 이 기기만("다른 기기 없음") | ![s10-08-sessions-only-me](s10-08-sessions-only-me.png) |
| S10 설정 | 세션 목록 오류(다시 시도) | ![s10-09-sessions-error](s10-09-sessions-error.png) |
| S4 검색 | 입력 전(최근 검색어) | ![s4-01-recent](s4-01-recent.png) |
| S4 검색 | 결과 | ![s4-02-results](s4-02-results.png) |
| S4 검색 | 빈 목록 | ![s4-03-empty](s4-03-empty.png) |
| S4 검색 | 오류 | ![s4-04-error](s4-04-error.png) |
| S4 검색 | 큰 글씨 2.0 | ![s4-06-big-text](s4-06-big-text.png) |
| S5 앨범 | 기본 | ![s5-01-album](s5-01-album.png) |
| S5 앨범 | 오류 404 | ![s5-02-404](s5-02-404.png) |
| S5 앨범 | 세션 만료(다운로드 버튼 없음) | ![s5-04-expired](s5-04-expired.png) |
| S5 앨범 | 큰 글씨 2.0 | ![s5-05-big-text](s5-05-big-text.png) |
| S6 플레이리스트 | 기본(재생할 수 없는 곡 포함) | ![s6-01-playlist](s6-01-playlist.png) |
| S6 플레이리스트 | 편집 모드 | ![s6-02-edit](s6-02-edit.png) |
| S6 플레이리스트 | 빈 목록 | ![s6-03-empty](s6-03-empty.png) |
| S6 플레이리스트 | 충돌(다른 기기에서 변경) | ![s6-04-conflict](s6-04-conflict.png) |
| S7 미니 플레이어 | 재생 중(다운로드본) | ![s7-01-mini](s7-01-mini.png) |
| S7 미니 플레이어 | 로딩·서버에서 준비 중 | ![s7-02-preparing](s7-02-preparing.png) |
| S7 미니 플레이어 | 오류 | ![s7-03-error](s7-03-error.png) |
| S7 미니 플레이어 | 큰 글씨 1.6(아티스트 줄 숨김) | ![s7-04-big-text](s7-04-big-text.png) |
| S8 몰입 화면 | LP | ![s8-01-lp](s8-01-lp.png) |
| S8 몰입 화면 | 3단 가사 | ![s8-02-lyrics](s8-02-lyrics.png) |
| S8 몰입 화면 | 대기열 | ![s8-03-queue](s8-03-queue.png) |
| S8 몰입 화면 | 오류(사유 + 다음 곡) | ![s8-04-error](s8-04-error.png) |
| S8 몰입 화면 | 빈 목록: 가사 없음 | ![s8-05-no-lyrics](s8-05-no-lyrics.png) |
| S8 몰입 화면 | 발음 없음(칩 비활성 + 이유) · 가사 출처 표기 | ![s8-09-lyrics-source](s8-09-lyrics-source.png) |
| S8 몰입 화면 | 로딩: 서버에서 재생용 파일 준비 중 | ![s8-10-preparing](s8-10-preparing.png) |
| S8 몰입 화면 | 가로 화면(LP·제어 | 가사) | ![s8-06-landscape](s8-06-landscape.png) |
| S8 몰입 화면 | 큰 글씨 2.0 | ![s8-07-big-text](s8-07-big-text.png) |
| S8 몰입 화면 | 다크 테마 | ![s8-08-dark](s8-08-dark.png) |
| S7 미니 플레이어 | 대기열 없음(숨김) | ![s7-05-empty](s7-05-empty.png) |
| S9 다운로드 | 빈 목록 | ![s9-01-empty](s9-01-empty.png) |
| S9 다운로드 | 진행 중·확인 필요·완료 (상태 문구 1:1) | ![s9-02-states](s9-02-states.png) |
| S9 다운로드 | 세션 만료(로그인 필요) | ![s9-03-expired](s9-03-expired.png) |
| S9 다운로드 | 접근 취소(잠김) | ![s9-04-revoked](s9-04-revoked.png) |
| S9 다운로드 | 오프라인(네트워크 연결 대기) | ![s9-05-offline](s9-05-offline.png) |
| S9 다운로드 | 큰 글씨 2.0(버튼 다음 줄) | ![s9-06-big-text](s9-06-big-text.png) |
| S10 설정 | 기본(서버 구획) | ![s10-01-settings](s10-01-settings.png) |
| S10 설정 | 재생·가사·화면·개인정보 | ![s10-02-settings-more](s10-02-settings-more.png) |
| S10 설정 | 오프라인(서버 항목 비활성) | ![s10-03-offline](s10-03-offline.png) |
| S10 설정 | 세션 만료(다시 로그인) | ![s10-04-expired](s10-04-expired.png) |
| S10 설정 | 재로그인 시트(서버 고정) | ![s10-05-relogin](s10-05-relogin.png) |
| S10 설정 | 큰 글씨 2.0 | ![s10-06-big-text](s10-06-big-text.png) |
| S11 구매 | 판매 방식 미정(구매 버튼 비활성) | ![s11-01-purchase](s11-01-purchase.png) |
| S11 구매 | 복원 결과(스토어 연결 불가) | ![s11-02-restore](s11-02-restore.png) |
| S11 구매 | 오프라인 | ![s11-03-offline](s11-03-offline.png) |