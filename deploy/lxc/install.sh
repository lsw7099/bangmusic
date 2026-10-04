#!/bin/bash
# BangMusic 서버 설치·업데이트 (Debian 13 LXC 또는 VM, root로 실행)
#   bash install.sh <릴리스 tar 파일>
# 같은 명령으로 업데이트도 한다: 새 릴리스를 /opt/bangmusic/releases/<이름>에 풀고 current 링크를 바꾼 뒤 재시작.
# 설정(/etc/bangmusic/env)과 데이터(/var/lib/bangmusic)는 이미 있으면 건드리지 않는다.
set -euo pipefail
# pct exec·cron 등 최소 환경에서도 같게 동작하도록 (재설치 시험에서 PATH에 /usr/local/bin이 없어 실패했다)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LC_ALL=C.UTF-8 LANG=C.UTF-8

NODE_VERSION="${NODE_VERSION:-24.21.0}"
MUSIC_GID="${MUSIC_GID:-1100}"   # 음악 폴더 읽기 그룹. 비특권 LXC면 호스트에서는 100000 + 이 값
TAR="${1:?사용법: bash install.sh <릴리스 tar 파일>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ "$(id -u)" = 0 ] || { echo "root로 실행하세요"; exit 1; }
[ -f "$TAR" ] || { echo "릴리스 파일이 없습니다: $TAR"; exit 1; }

echo "== 1/7 패키지 (ffmpeg 등)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg ca-certificates curl xz-utils >/dev/null

echo "== 2/7 Node.js ${NODE_VERSION} (nodejs.org 공식 파일, SHA-256 확인)"
if [ "$(/usr/local/bin/node -v 2>/dev/null || true)" != "v${NODE_VERSION}" ]; then
  T=$(mktemp -d)
  F="node-v${NODE_VERSION}-linux-x64.tar.xz"
  curl -fsSL -o "$T/$F" "https://nodejs.org/dist/v${NODE_VERSION}/$F"
  curl -fsSL -o "$T/SHASUMS256.txt" "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"
  (cd "$T" && grep " $F\$" SHASUMS256.txt | sha256sum -c -)
  mkdir -p /opt/node
  tar -xJf "$T/$F" -C /opt/node --no-same-owner
  ln -sfn "/opt/node/node-v${NODE_VERSION}-linux-x64" /opt/node/current
  for b in node npm npx; do ln -sfn "/opt/node/current/bin/$b" "/usr/local/bin/$b"; done
  rm -rf "$T"
fi
node -v

echo "== 3/7 서비스 사용자·음악 그룹"
id bangmusic >/dev/null 2>&1 || useradd --system --home-dir /var/lib/bangmusic --no-create-home --shell /usr/sbin/nologin bangmusic
getent group music >/dev/null || groupadd -g "$MUSIC_GID" music
usermod -aG music bangmusic

echo "== 4/7 폴더"
install -d -m 755 /etc/bangmusic /opt/bangmusic/releases /srv/music
install -d -m 700 -o bangmusic -g bangmusic /var/lib/bangmusic /var/cache/bangmusic
[ -f /etc/bangmusic/env ] || install -m 644 "$HERE/env.example" /etc/bangmusic/env

echo "== 5/7 서버 파일"
REL="/opt/bangmusic/releases/$(basename "$TAR" .tar)"
rm -rf "$REL.new" && mkdir -p "$REL.new"
tar -xf "$TAR" -C "$REL.new" --no-same-owner --warning=no-timestamp
(cd "$REL.new" && npm ci --omit=dev --workspace server --ignore-scripts --no-audit --no-fund --no-update-notifier --loglevel=error)
rm -rf "$REL" && mv "$REL.new" "$REL"
ln -sfn "$REL" /opt/bangmusic/current

echo "== 6/7 서비스"
install -m 755 "$HERE/bangmusic-server" /usr/local/bin/bangmusic-server
install -m 644 "$HERE/bangmusic.service" /etc/systemd/system/bangmusic.service
systemctl daemon-reload
systemctl enable bangmusic >/dev/null
systemctl restart bangmusic

echo "== 7/7 확인"
for i in $(seq 1 20); do
  runuser -u bangmusic -- bangmusic-server healthcheck >/dev/null 2>&1 && break
  sleep 1
done
runuser -u bangmusic -- bangmusic-server healthcheck
systemctl is-active bangmusic
echo "설치 완료: $(readlink /opt/bangmusic/current)"
