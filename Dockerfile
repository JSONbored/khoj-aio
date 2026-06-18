# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769
# checkov:skip=CKV_DOCKER_7:Upstream image is pinned by immutable digest instead of a mutable tag.
# checkov:skip=CKV_DOCKER_8:The wrapper needs root for s6 init, package install, and managed internal PostgreSQL startup.
ARG UPSTREAM_VERSION=2.0.0-beta.28
ARG UPSTREAM_IMAGE_DIGEST=sha256:eb2e44669df44b51cb206b394dc0a00c782ac152dda02c97c9e3dac3d643dbb4
FROM jsonbored/aio-base:s6-3.2.1.0@sha256:07db479a01a95ba28480b4605f5d1cc8bedb574b77cf167ee46e29b9558fee90 AS aio-base

FROM ghcr.io/khoj-ai/khoj@${UPSTREAM_IMAGE_DIGEST}


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3002
USER root

# hadolint ignore=DL3008,SC2086
# Shared, pinned s6-overlay from the fleet aio-base overlay.
COPY --from=aio-base /aio-overlay/ /

RUN aio-harden pre && \
    DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
    postgresql-14-pgvector \
    postgresql-15 \
    postgresql-client-15 \
    postgresql-15-pgvector && \
    apt-mark manual postgresql-14 postgresql-client-14 postgresql-14-pgvector postgresql-15 postgresql-client-15 postgresql-15-pgvector postgresql-common postgresql-client-common && \
    python3 -m pip install --no-cache-dir --upgrade pillow==12.2.0 && \
    mkdir -p /root/.khoj /var/lib/postgresql/data /root/.cache/huggingface /root/.cache/torch/sentence_transformers /run/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql /run/postgresql && \
    DEBIAN_FRONTEND=noninteractive apt-get purge -y \
      build-essential \
      g++ \
      g++-11 \
      gcc \
      gcc-11 \
      libc-dev-bin \
      libc6-dev \
      libc-devtools \
      libcrypt-dev \
      libexpat1-dev \
      libgcc-11-dev \
      libnsl-dev \
      libpython3.10-dev \
      libstdc++-11-dev \
      libtirpc-dev \
      linux-libc-dev \
      make \
      python3-dev \
      python3.10-dev \
      rpcsvc-proto && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y --purge && \
    rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem && \
    rm -rf /tmp/* /var/lib/apt/lists/*

COPY rootfs/ /

RUN find /etc/cont-init.d -type f -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \;

LABEL org.opencontainers.image.source="https://github.com/JSONbored/khoj-aio" \
      org.opencontainers.image.title="khoj-aio" \
      org.opencontainers.image.description="Unraid-first AIO wrapper image for Khoj with an internal PostgreSQL default" \
      io.jsonbored.wrapper.name="khoj-aio" \
      io.jsonbored.wrapper.type="unraid-aio"

VOLUME ["/root/.khoj", "/var/lib/postgresql/data", "/root/.cache/huggingface", "/root/.cache/torch/sentence_transformers"]

EXPOSE 42110

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=300000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:42110/ >/dev/null || exit 1

ENTRYPOINT ["/init"]
