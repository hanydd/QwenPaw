# check=skip=SecretsUsedInArgOrEnv
FROM python:3.12-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG USE_CHINA_MIRRORS=true
ARG PYPI_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG QWENPAW_DISABLED_CHANNELS="imessage"
ARG QWENPAW_ENABLED_CHANNELS=""

LABEL org.opencontainers.image.title="QwenPaw Backend"
LABEL org.opencontainers.image.description="QwenPaw CLI and FastAPI backend without the web console"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUTF8=1 \
    NODE_ENV=production \
    WORKSPACE_DIR=/app \
    QWENPAW_WORKING_DIR=/app/working \
    QWENPAW_SECRET_DIR=/app/working.secret \
    QWENPAW_BACKUP_DIR=/app/working.backups \
    QWENPAW_CONSOLE_STATIC_DIR=/opt/qwenpaw/console-disabled \
    QWENPAW_RUNNING_IN_CONTAINER=1 \
    QWENPAW_PORT=8088 \
    QWENPAW_DISABLED_CHANNELS=${QWENPAW_DISABLED_CHANNELS} \
    QWENPAW_ENABLED_CHANNELS=${QWENPAW_ENABLED_CHANNELS} \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PIP_INDEX_URL=${PYPI_INDEX_URL} \
    UV_DEFAULT_INDEX=${PYPI_INDEX_URL} \
    PATH=/opt/qwenpaw/venv/bin:${PATH}

RUN if [ "${USE_CHINA_MIRRORS}" = "true" ]; then \
        sed -i 's@deb.debian.org@mirrors.aliyun.com@g' /etc/apt/sources.list.d/debian.sources; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        chromium \
        chromium-sandbox \
        curl \
        git \
        libssl-dev \
        fonts-liberation \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${WORKSPACE_DIR}

RUN python3 -m venv venv
ENV PATH="/app/venv/bin:$PATH"

RUN pip install --no-cache-dir uv==0.9.3

COPY pyproject.toml setup.py README.md ./
COPY src ./src
COPY website/public/docs/ ./src/qwenpaw/docs/

RUN uv pip install --no-cache-dir . && rm -rf ./build

COPY --chmod=755 deploy/entrypoint-backend.sh /entrypoint.sh

VOLUME ["/app/working", "/app/working.secret", "/app/working.backups"]

EXPOSE 8088

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${QWENPAW_PORT}/api/version" >/dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["serve"]
