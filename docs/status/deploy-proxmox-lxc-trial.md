# Proxmox 시험 설치 기록 (LXC, 합성 음원)

> **2026-10-04 이후**: CT 107은 P6 실서버가 되었다(실제 음악, HTTPS). 현재 구성은 [`P6.md`](P6.md), 설치·업데이트 절차는 [`docs/install/proxmox-lxc.md`](../install/proxmox-lxc.md)가 기준이다. 아래는 당시 기록이다.

작성 2026-10-02. **이것은 P6(배포 검증)이 아니다.** P2~P5를 거치지 않은 P1 서버를 사용자의 Proxmox에 올려 써 보기 위한 시험 설치이며, 05장 P6 수용 기준(FN-01/06/07/09/10의 L2 통과, 설치 문서만으로 재설치 등)을 확인하지 않았다. 이 설치의 성공을 배포 완료로 표시하지 않는다.

## 설계와 다른 점

| 설계 | 이번 설치 | 이유 |
| --- | --- | --- |
| VM + Docker Compose (01장 §2.1 결정) | 비특권 LXC에 Node·FFmpeg 직접 설치 + systemd (01장 §2.1의 "비공식 대안") | 사용자 선택. 호스트의 다른 서비스도 모두 LXC이고 메모리(7.5GB)를 아끼려는 목적 |
| 서버 컨테이너 비루트·읽기 전용 루트 | systemd: `User=bangmusic`, `ProtectSystem=strict`, `NoNewPrivileges`, 빈 `CapabilityBoundingSet`, 쓰기는 `/var/lib/bangmusic`·`/var/cache/bangmusic`만 | Docker 없이 같은 목적(비루트, 원본·프로그램 쓰기 불가)을 달성 |
| 음악 원본 읽기 전용 마운트 2겹 | `/srv/music`(root 소유, 755) + `ProtectSystem=strict`로 서비스 쪽 읽기 전용 | 지금은 CT 안의 합성 음원. 실제 음악을 붙일 때는 `pct set 107 --mp0 <호스트경로>,mp=/srv/music/<이름>,ro=1` |
| Caddy 프록시(HTTPS) | 없음. `http://192.168.1.173:8080` 직접 | 시험용. 기존 NPM(CT 105)으로 HTTPS 연결은 다음 단계 |
| FFmpeg 배포 방식 [미결] | Debian 패키지 ffmpeg 7.1.5 | 본인 환경 설치라 재배포가 아님. 판매용 결정(README §4)은 그대로 미결 |

## 환경

| 항목 | 값 |
| --- | --- |
| 호스트 | `pve` 192.168.1.4, Proxmox VE 9.2.20, 커널 7.0.14-19-pve |
| CT | 107 `bangmusic`, 비특권, `nesting=1`(Debian 13의 systemd 257), 2코어, RAM 1GB + 스왑 512MB, 디스크 8GB(local-lvm), `onboot=1` |
| 네트워크 | vmbr0, DHCP → **192.168.1.173** (공유기에서 이 주소를 고정 예약할 것) |
| OS | Debian 13.6 템플릿 |
| 런타임 | Node v24.21.0 (nodejs.org 공식 tar, SHASUMS256 검증), FFmpeg 7.1.5 (Debian) |
| 서버 | 커밋 `4a62191`(P2) → `/opt/bangmusic/releases/4a62191`, `/opt/bangmusic/current` 링크. 이전 `b0e7ea1`(P1) 보관 |
| 데이터 | DB·서명 키 `/var/lib/bangmusic`(700, 키 600), 캐시 `/var/cache/bangmusic` |
| 음악 | `/srv/music/lib1`, `/srv/music/lib2` (합성 음원 `--quick`) |
| 설정 | `/etc/bangmusic/env` (비밀값 없음) |

## 설치 결과 (2026-10-02)

- 스캔: lib1 파일 30개 → 곡 29개, 실패 1(0바이트 파일), 루트 밖 링크 1개 제외. lib2 곡 3개. 약 5초.
- Linux에서 처음 생성된 것: 대소문자만 다른 이름 2곡, 루트 밖 심볼릭 링크(제외됨 — SEC-02 동작을 실제 ext4에서 확인).
- `systemctl is-active bangmusic` = active, `healthcheck` 성공, 메모리 사용 약 90MB.
- 이 PC(LAN)에서 `GET /v1/server` 200, 다른 API는 `503 setup_required`(관리자 생성 전).
- 서비스 권한으로 `/srv/music`, `/opt/bangmusic`에 쓰기 → `Read-only file system`.

## P2 업데이트 (2026-10-02)

- `4a62191` 배포 → 기동 시 마이그레이션 0002 적용, 적용 전 스냅샷 `/var/lib/bangmusic/backups/20261002T121809Z-pre-migrate-2` 자동 생성, `server_id` 유지.
- 재스캔으로 사이드카 가사 5종 등록. `features`에 `transcode`, 프로파일 aac_256/aac_128.
- 변환 처리량·메모리 측정(03장 §4.6). 측정용으로 `time` 패키지 설치.
- 참고: 개발 PC와 Proxmox 시계가 약 39초 다르다(배포 시 tar 경고). 호스트 NTP 확인 권장.

## 시험 설치 중 발견해 고친 것

- 합성 음원의 "아주 긴 파일 이름"이 Linux에서 `ENAMETOOLONG`. Linux는 UTF-8 255바이트, Windows는 UTF-16 255자 기준이라 Windows에서는 드러나지 않았다 → 커밋 `b0e7ea1`.
- `/etc/bangmusic/env`의 값에 공백·괄호가 있으면 셸 래퍼가 읽지 못한다 → 큰따옴표로 감쌈.

## 사용자가 할 일

1. **관리자 계정 만들기** (비밀번호는 직접 입력):
   Proxmox 웹 → CT 107 → Console, 또는 `pct enter 107` 후
   `runuser -u bangmusic -- bangmusic-server admin create <사용자이름>`
2. 공유기 DHCP에서 192.168.1.173 고정 예약.
3. WireGuard(CT 101)로 외부에서 `http://192.168.1.173:8080/v1/server` 접속 확인.

## 운영 명령

```bash
# 상태·로그
systemctl status bangmusic
journalctl -u bangmusic -f

# 관리 명령 (서비스 사용자로)
runuser -u bangmusic -- bangmusic-server library list
runuser -u bangmusic -- bangmusic-server scan

# 새 버전 배포 (개발 PC에서) — 커밋된 내용만 보낸다
git archive --format=tar HEAD | ssh root@192.168.1.173 'REL=/opt/bangmusic/releases/<rev>; mkdir -p $REL && tar -xf - -C $REL && cd $REL && npm ci --omit=dev --workspace server --ignore-scripts && ln -sfn $REL /opt/bangmusic/current && systemctl restart bangmusic'
# 롤백: current 링크를 이전 releases/<rev>로 되돌리고 재시작 (스키마가 바뀐 버전이면 백업 스냅샷 복원 필요 — 01장 §5.3, P2)
```

## 다음 단계로 남은 것

- HTTPS: NPM(CT 105)에서 프록시 호스트 추가 + 인증서. 앱 릴리스 빌드는 HTTPS만 허용한다(05장 §9.3). 프록시 뒤에 두면 `BANGMUSIC_TRUST_PROXY`에 NPM 주소(192.168.1.5)를 넣는다.
- 실제 음악 연결(호스트 경로 → `mp0 ... ro=1`).
- 접근 권한: 작업이 끝나면 Proxmox 호스트 `~/.ssh/authorized_keys`에서 `<배포용 SSH 키>` 키를 지운다(CT 107에도 같은 키가 root로 들어가 있다).
