ARG DISTRO=alpine
ARG DISTRO_VARIANT=3.18

FROM docker.io/tiredofit/nginx:${DISTRO}-${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG UPTIMEKUMA_VERSION

ENV UPTIMEKUMA_VERSION=${UPTIMEKUMA_VERSION:-"1.23.2"} \
    UPTIMEKUMA_REPO_URL=https://github.com/louislam/uptime-kuma \
    NGINX_SITE_ENABLED="uptimekuma" \
    NGINX_ENABLE_CREATE_SAMPLE_HTML=FALSE \
    NGINX_WORKER_PROCESSES=1 \
    IMAGE_NAME="tiredofit/uptimekuma" \
    IMAGE_REPO_URL="https://github.com/tiredofit/uptimekuma/"

RUN source assets/functions/00-container && \
    set -x && \
    addgroup -S -g 8080 uptimekuma && \
    adduser -D -S -s /sbin/nologin \
            -h /dev/null \
            -G uptimekuma \
            -g "uptimekuma" \
            -u 8080 uptimekuma \
            && \
    \
    package update && \
    package upgrade && \
    package install .uptimekuma-build-deps \
                    git \
                    npm \
                    && \
    \
    package install .uptimekuma-run-deps \
                    chromium \
                    nodejs \
                    && \
    \
    clone_git_repo "${UPTIMEKUMA_REPO_URL}" "${UPTIMEKUMA_VERSION}" && \
    if [ -d "/build-assets/src" ] && [ -n "$(ls -A "/build-assets/src" 2>/dev/null)" ]; then cp -R /build-assets/src/* ${GIT_REPO_SRC_UPTIMEKUMA} ; fi; \
    if [ -d "/build-assets/scripts" ] && [ -n "$(ls -A "/build-assets/scripts" 2>/dev/null)" ]; then for script in /build-assets/scripts/*.sh; do echo "** Applying $script"; bash $script; done && \ ; fi ; \
    mkdir -p /app && \
    cp .npmrc /app && \
    cp package*.json /app && \
    npm ci && \
    npm run build && \
    cp -R dist db server src /app/ && \
    cd /app/ && \
    npm ci --omit=dev && \
    chown -R uptimekuma:uptimekuma /app && \
    \
    package remove .uptimekuma-build-deps && \
    package cleanup && \
    rm -rf \
            /build-assets \
            /root/.cache \
            /root/.npm \
            /usr/src/*

EXPOSE 3001

COPY install /
