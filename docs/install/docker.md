# BangMusic 서버 설치 — Docker Compose

Docker가 있는 Linux 기기(NAS, 미니 PC, VM)에 서버를 설치한다. Proxmox LXC에 직접 설치하려면 [proxmox-lxc.md](proxmox-lxc.md)를 본다.

준비물: Docker Engine과 Compose 플러그인(`docker compose version`이 동작해야 한다), 음악 폴더.

## 1. 파일 받기

```bash
mkdir -p ~/bangmusic && cd ~/bangmusic
# 릴리스의 compose.yaml을 받는다 (저장소의 deploy/docker/compose.yaml)
```

## 2. 음악 폴더 지정

`compose.yaml`과 같은 폴더에 `.env`를 만든다.

```bash
MUSIC_DIR=/srv/music          # 내 음악 폴더 (하위 폴더까지 읽는다)
BANGMUSIC_IMAGE=bangmusic-server:0.1.0
```

- 음악 폴더는 **읽기 전용(`:ro`)** 으로만 붙는다. 서버는 음악 원본에 쓰지 않는다.
- 서버는 컨테이너 안에서 사용자 번호 1000으로 돈다. 음악 파일이 모두에게 읽기 권한이 없으면(`ls -l`에서 마지막 `r`이 없으면) `compose.yaml`의 `group_add`에 음악 파일의 그룹 번호(`ls -n`)를 넣는다. 파일 권한은 바꾸지 않아도 된다.

## 3. 시작

```bash
docker compose up -d
docker compose ps          # STATUS가 healthy가 될 때까지 (30초 정도)
curl http://localhost:8080/v1/server
```

## 4. 관리자와 라이브러리

```bash
docker compose exec bangmusic bangmusic-server admin create <사용자 이름>   # 비밀번호를 묻는다(10자 이상)
docker compose exec bangmusic bangmusic-server library add "내 음악" /music
docker compose exec bangmusic bangmusic-server scan
```

- 라이브러리 경로는 컨테이너 안의 경로 `/music`(또는 그 하위 폴더)다.
- 음악 폴더가 비어 있으면(붙지 않았으면) 등록을 거부한다. 2단계를 확인한다.

## 5. HTTPS

앱의 정식 빌드는 `https://` 서버에만 연결한다. 리버스 프록시(Nginx Proxy Manager, Caddy 등)를 앞에 두고, 프록시 주소를 `compose.yaml`의 `BANGMUSIC_TRUST_PROXY`에 넣는다. 프록시 설정(접근 로그에서 미디어 티켓 빼기, 버퍼링 끄기, HSTS)은 [proxmox-lxc.md 5단계](proxmox-lxc.md#5-https-리버스-프록시)와 같다.

## 6. 백업

- 서버가 매일 DB 스냅샷을 `/data/backups`에 만든다(`BANGMUSIC_BACKUP_HOUR_UTC`, 기본 18시 UTC).
- 볼륨 `bangmusic-data`는 같은 디스크에 있으므로 다른 디스크·NAS로 복사해 둔다.
  ```bash
  docker run --rm -v bangmusic_bangmusic-data:/data -v "$PWD":/out debian:trixie-slim tar -czf /out/bangmusic-data.tgz -C /data .
  ```
- 수동 백업: `docker compose exec bangmusic bangmusic-server backup`

## 7. 업데이트와 되돌리기

```bash
# .env의 BANGMUSIC_IMAGE를 새 버전으로 바꾼 뒤
docker compose pull        # 레지스트리에서 받는 경우
docker compose up -d
```

- 업데이트 전에 수동 백업을 만든다(6단계). 새 버전이 DB를 고쳐 쓰면 옛 버전은 그 DB를 읽지 못할 수 있다.
- 되돌리기: `BANGMUSIC_IMAGE`를 옛 버전으로 바꾸고, 업데이트 전 백업으로 복원한 뒤 `docker compose up -d`.
  ```bash
  docker compose exec bangmusic bangmusic-server backup list   # 멈추기 전에 이름 확인
  docker compose stop bangmusic
  docker compose run --rm bangmusic restore <업데이트 전 스냅샷 이름>
  docker compose up -d
  ```

## 라이선스

- BangMusic 서버: MIT (`/licenses/BangMusic-LICENSE.txt`).
- 이미지에 들어 있는 다른 소프트웨어의 고지는 컨테이너 안 `/licenses/`에 있다: Node 패키지(`node/`), FFmpeg(`ffmpeg/`), Debian 패키지(`debian/`).
  ```bash
  docker compose exec bangmusic ls /licenses
  ```
- **FFmpeg는 GPL**로 빌드된 Debian 패키지다. 대응 소스 위치는 `/licenses/ffmpeg/SOURCE.txt`에 있고, 릴리스마다 같은 소스 묶음을 릴리스 첨부 파일로도 제공한다. 서버는 FFmpeg를 별도 프로그램으로 실행하므로 서버 코드의 라이선스(MIT)는 바뀌지 않는다.
