#!/bin/sh
# 이미지 안 /licenses: 서버(MIT), Node 의존성, FFmpeg(GPL)·Debian 패키지 고지 (05장 §8.5)
set -eu
L=/licenses
mkdir -p "$L/ffmpeg" "$L/node" "$L/debian"
cp /app/LICENSE "$L/BangMusic-LICENSE.txt"
node /tmp/collect-licenses.mjs /app/node_modules "$L/node"
# FFmpeg: 빌드 구성, 패키지 버전, 저작권 고지, 소스 위치
ffmpeg -hide_banner -buildconf > "$L/ffmpeg/buildconf.txt" 2>&1 || true
ffmpeg -hide_banner -version | head -1 > "$L/ffmpeg/version.txt"
for p in $(dpkg-query -W -f '${Package}\n' | grep -E '^(ffmpeg|libav|libsw|libpostproc)'); do
  cp "/usr/share/doc/$p/copyright" "$L/ffmpeg/$p.copyright" 2>/dev/null || true
done
SRCVER=$(dpkg-query -W -f '${source:Version}' ffmpeg)
cat > "$L/ffmpeg/SOURCE.txt" <<TXT
이 이미지의 FFmpeg는 Debian 패키지 ffmpeg ${SRCVER} 이며 GPL 옵션으로 빌드되었습니다(buildconf.txt).
대응 소스: https://snapshot.debian.org/package/ffmpeg/${SRCVER}/
           또는 Debian 시스템에서 apt-get source ffmpeg=${SRCVER}
BangMusic 릴리스마다 같은 소스 묶음을 릴리스 첨부 파일로도 제공합니다(docs/install/docker.md "라이선스").
TXT
# 그 밖의 Debian 패키지: 이름·버전·소스 패키지 목록과 저작권 파일
dpkg-query -W -f '${Package}\t${Version}\t${source:Package}\t${source:Version}\n' | sort > "$L/debian/packages.tsv"
for d in /usr/share/doc/*/copyright; do p=$(basename "$(dirname "$d")"); cp "$d" "$L/debian/$p.copyright"; done
chmod -R a+rX "$L"
