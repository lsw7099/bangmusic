# BangMusic 서버 설치 — Proxmox LXC

Proxmox VE 8 이상에서 비특권 LXC 하나에 서버를 설치한다. Docker를 쓰지 않고 Node.js와 FFmpeg를 직접 설치해 systemd로 돌린다.
(Docker Compose 설치 방법은 따로 준비 중이다 — 05장 P6 결정 참고.)

필요한 것:

- Proxmox 호스트 root 셸
- 음악 폴더(호스트 경로). 서버는 **읽기 전용**으로만 붙인다.
- 릴리스 파일 `bangmusic-<버전>.tar`
- HTTPS용 도메인과 리버스 프록시(앱의 정식 빌드는 HTTPS 서버에만 연결한다). 집 안에서만 시험할 때는 없어도 된다.

아래에서 `<CTID>`는 새 컨테이너 번호(예: 107), `<음악 경로>`는 호스트의 음악 폴더(예: `/mnt/media/library/music`)다.

## 1. 컨테이너 만들기 (호스트)

```bash
pveam update && pveam download local debian-13-standard_13.6-1_amd64.tar.zst   # 이미 있으면 생략
pct create <CTID> local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst \
  --hostname bangmusic --unprivileged 1 --features nesting=1 \
  --cores 2 --memory 1024 --swap 512 --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 --onboot 1
```

- `nesting=1`은 Debian 13의 systemd가 제대로 돌기 위해 필요하다.
- 메모리 1GB면 곡 수천 개와 변환 2개 동시 처리에 충분하다(실측: 176곡 스캔 최대 180MB, 대기 90MB).
- DHCP로 받은 주소는 공유기에서 고정 예약해 둔다.

## 2. 음악 폴더 붙이기 (호스트)

```bash
pct set <CTID> --mp0 <음악 경로>,mp=/srv/music/main,ro=1
```

`ro=1`이 첫 번째 읽기 전용 보호다(두 번째는 서비스의 `ProtectSystem=strict`).

**읽기 권한.** 비특권 컨테이너 안의 서버 계정은 호스트의 일반 사용자와 다르다. 음악 파일이 "다른 사용자 읽기"를 허용하지 않으면(예: 640/750) 서버가 읽지 못한다. 파일 권한은 그대로 두고 그룹만 맞추는 방법을 권한다:

```bash
chgrp -R 101100 <음악 경로>      # 컨테이너 안의 music 그룹(1100) = 호스트 101100
chmod g+s <음악 경로>            # 새로 넣는 파일도 같은 그룹을 물려받게(폴더에만)
```

이미 다른 사용자도 읽을 수 있는 권한(644/755)이면 이 단계는 필요 없다.

## 3. 서버 설치 (컨테이너)

```bash
pct start <CTID>
pct push <CTID> bangmusic-<버전>.tar /root/bangmusic-<버전>.tar
pct enter <CTID>
```

컨테이너 안에서:

```bash
cd /root
mkdir -p setup && tar -xf bangmusic-<버전>.tar -C setup deploy/lxc
bash setup/deploy/lxc/install.sh /root/bangmusic-<버전>.tar
```

설치 스크립트가 하는 일: FFmpeg 설치, Node.js 공식 파일 내려받기(SHA-256 확인), 서비스 계정 `bangmusic`과 `music` 그룹, 폴더, systemd 서비스 등록·시작, 상태 확인. 마지막 줄이 `설치 완료: ...`면 성공이다.

서버 이름 등 설정은 `/etc/bangmusic/env`에서 바꾸고 `systemctl restart bangmusic`.

## 4. 관리자와 라이브러리 (컨테이너)

```bash
runuser -u bangmusic -- bangmusic-server admin create <사용자 이름>     # 비밀번호를 묻는다(10자 이상)
runuser -u bangmusic -- bangmusic-server library add "내 음악" /srv/music/main
runuser -u bangmusic -- bangmusic-server scan
```

- 비밀번호는 명령행 인자로 받지 않는다(기록에 남지 않게).
- 스캔은 곡 1,000개에 몇 분 걸린다. 끝나면 `files`, `added`, `errors` 수가 나온다.
- 음악 폴더가 비어 있으면(마운트가 안 됐으면) 등록을 거부한다. 2단계를 확인한다.

이 시점에 같은 네트워크에서 `http://<CT 주소>:8080/v1/server`가 열리면 서버는 동작 중이다.

## 5. HTTPS (리버스 프록시)

앱의 정식 빌드는 `https://` 서버에만 연결한다. 예: Nginx Proxy Manager(NPM)와 Cloudflare DNS를 쓰는 경우 — 공유기 포트를 열지 않는다.

1. Cloudflare DNS: `A music → <NPM 내부 IP>`, 프록시 상태 **DNS 전용(회색 구름)**.
2. Cloudflare API 토큰: "영역 DNS 편집" 템플릿, 해당 도메인만.
3. NPM → SSL Certificates → Let's Encrypt, 도메인 `music.<도메인>`, **Use a DNS Challenge** → Cloudflare, 토큰 입력.
4. NPM → Proxy Hosts → `music.<도메인>` → `http://<CT 주소>:8080`, SSL 탭에서 인증서 선택, **Force SSL**·HTTP/2·**HSTS** 켜기.
   **Advanced 탭**에 아래를 넣는다. 재생 주소에는 미디어 티켓(`?mt=…`, 12시간 유효)이 붙는데, NPM의 기본 접근 로그는 쿼리 문자열까지 남긴다. 서버 자체 로그는 티켓을 가린다(`mt=<redacted>`).
   ```nginx
   access_log off;
   proxy_buffering off;
   ```
   (`proxy_buffering off`는 큰 음악 파일을 프록시가 디스크에 모았다 보내지 않게 한다 — 05장 §9.)
5. 서버에 프록시를 알려 준다: `/etc/bangmusic/env`에 `BANGMUSIC_TRUST_PROXY=<NPM 내부 IP>` → `systemctl restart bangmusic`.

확인: `curl https://music.<도메인>/v1/server`. 집 밖에서는 VPN(WireGuard 등)으로 집 네트워크에 들어온 뒤 같은 주소를 쓴다.
집 DNS가 내부 IP 응답을 막으면(DNS rebinding 보호) 집 DNS(AdGuard·공유기)에 `music.<도메인> → <NPM 내부 IP>`를 직접 넣는다.

## 6. 백업

- 서버가 매일 03:00(KST, 설정 `BANGMUSIC_BACKUP_HOUR_UTC=18`)에 `/var/lib/bangmusic/backups`에 스냅샷을 만든다. 업데이트로 DB 구조가 바뀔 때도 직전에 자동으로 만든다.
- 이 폴더는 **컨테이너 디스크 안**이다. 디스크 장애에 대비하려면 Proxmox의 백업(데이터센터 → 백업)으로 컨테이너를 다른 저장소에 매일 백업한다. 음악 폴더(mp0)는 컨테이너 백업에 포함되지 않는다.
- 지금 바로 스냅샷: `runuser -u bangmusic -- bangmusic-server backup`

**복원** (서버를 멈춘 상태에서):

```bash
systemctl stop bangmusic
runuser -u bangmusic -- bangmusic-server backup list
runuser -u bangmusic -- bangmusic-server restore <스냅샷 이름>
systemctl start bangmusic
```

복원해도 앱은 다시 로그인하지 않아도 된다(첫 요청에서 토큰을 자동으로 새로 받는다). 복원 전 DB는 `db-pre-restore-<시각>`으로 남는다.

## 7. 업데이트

새 릴리스 파일을 3단계처럼 넣고 같은 스크립트를 실행한다:

```bash
mkdir -p setup && tar -xf bangmusic-<새 버전>.tar -C setup deploy/lxc
bash setup/deploy/lxc/install.sh /root/bangmusic-<새 버전>.tar
```

설정과 데이터는 그대로 두고 서버 파일만 바꾼다. 되돌리려면 `ln -sfn /opt/bangmusic/releases/<이전 버전> /opt/bangmusic/current && systemctl restart bangmusic`. DB 구조가 바뀐 버전에서 되돌릴 때는 업데이트 직전 스냅샷(`*-pre-migrate-*`)도 복원한다.

## 8. 점검

| 증상 | 확인 |
| --- | --- |
| 앱에 "서버의 음악 저장소에 연결할 수 없습니다" | 음악 마운트(`ls /srv/music/main`). 다시 붙으면 다음 재생 요청에서 자동으로 복구된다 |
| 스캔이 "라이브러리 루트가 비어 있음"으로 멈춤 | 마운트가 빠져 있다. 곡은 지워지지 않는다 |
| 곡이 0개로 나옴 | 읽기 권한(2단계). `runuser -u bangmusic -- ls /srv/music/main` |
| 상태·로그 | `systemctl status bangmusic`, `journalctl -u bangmusic -f` |

로그에는 파일 경로·토큰·비밀번호가 응답으로 나가지 않는다. 문의할 때는 앱의 설정 → 진단 정보 복사를 쓴다.
