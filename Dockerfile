# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769

ARG UPSTREAM_VERSION=2.0.0-beta.28
ARG UPSTREAM_IMAGE_DIGEST=sha256:41aa881c957a035207c11da239dc436d0f8a0c6a72b372651c5a48e08127043a
FROM ghcr.io/khoj-ai/khoj@${UPSTREAM_IMAGE_DIGEST}

ARG S6_OVERLAY_VERSION=3.1.6.2
ARG TARGETARCH

USER root

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
    openssl \
    ca-certificates \
    postgresql-common && \
    install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    . /etc/os-release && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    postgresql-14 \
    postgresql-client-14 \
    postgresql-14-pgvector && \
    curl -L -o /tmp/s6-overlay-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    case "${TARGETARCH}" in \
      amd64) S6_ARCH="x86_64" ;; \
      arm64) S6_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    curl -L -o /tmp/s6-overlay-${S6_ARCH}.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz && \
    mkdir -p /root/.khoj /var/lib/postgresql/data /root/.cache/huggingface /root/.cache/torch/sentence_transformers /run/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql /run/postgresql && \
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

RUN find /etc/cont-init.d -type f -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \;

VOLUME ["/root/.khoj", "/var/lib/postgresql/data", "/root/.cache/huggingface", "/root/.cache/torch/sentence_transformers"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:42110/ >/dev/null || exit 1

ENTRYPOINT ["/init"]
