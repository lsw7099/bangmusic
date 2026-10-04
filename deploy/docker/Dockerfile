# BangMusic 서버 이미지 (05장 §8.2·8.5). 빌드: 저장소 루트에서
#   docker build -f deploy/docker/Dockerfile -t bangmusic-server:<버전> .
# [P7 결정] FFmpeg는 Debian 배포판 패키지(GPL 빌드)를 쓰고 GPL 의무를 이행한다 → /licenses/ffmpeg/
# 서버는 FFmpeg를 별도 프로세스로 실행한다(라이브러리로 링크하지 않음). libfdk_aac는 쓰지 않는다.
FROM node:24.21.0-trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json package-lock.json LICENSE ./
COPY server/package.json server/package.json
RUN npm ci --omit=dev --workspace server --ignore-scripts --no-audit --no-fund --no-update-notifier --loglevel=error \
 && npm cache clean --force
COPY server/src server/src
COPY deploy/docker/collect-licenses.sh deploy/docker/collect-licenses.mjs /tmp/
RUN sh /tmp/collect-licenses.sh && rm /tmp/collect-licenses.*

RUN printf '#!/bin/sh\nexec node /app/server/src/main.ts "$@"\n' > /usr/local/bin/bangmusic-server \
 && chmod 755 /usr/local/bin/bangmusic-server \
 && install -d -o node -g node -m 700 /data /cache

ENV BANGMUSIC_DATA_DIR=/data \
    BANGMUSIC_CACHE_DIR=/cache \
    BANGMUSIC_HOST=0.0.0.0 \
    BANGMUSIC_PORT=8080 \
    NODE_ENV=production

USER node
EXPOSE 8080
VOLUME ["/data", "/cache"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD ["bangmusic-server", "healthcheck"]
ENTRYPOINT ["/usr/bin/tini", "--", "bangmusic-server"]
CMD ["serve"]
