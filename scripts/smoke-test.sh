#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-khoj-aio:test}"
CONTAINER_NAME="khoj-aio-smoke"
HOST_PORT="${HOST_PORT:-54210}"
TMP_CONFIG="$(mktemp -d /tmp/khoj-aio-config.XXXXXX)"
TMP_PGDATA="$(mktemp -d /tmp/khoj-aio-pg.XXXXXX)"

cleanup() {
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    rm -rf "${TMP_CONFIG}" "${TMP_PGDATA}"
}
trap cleanup EXIT

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${HOST_PORT}:42110" \
    -v "${TMP_CONFIG}:/root/.khoj" \
    -v "${TMP_PGDATA}:/var/lib/postgresql/data" \
    "${IMAGE_TAG}" >/dev/null

for _ in $(seq 1 180); do
    if curl -fsS "http://127.0.0.1:${HOST_PORT}/" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

curl -fsS "http://127.0.0.1:${HOST_PORT}/" >/dev/null
grep -q "KHOJ_DJANGO_SECRET_KEY" "${TMP_CONFIG}/aio/generated.env"
grep -q "KHOJ_ADMIN_PASSWORD" "${TMP_CONFIG}/aio/generated.env"
test -f "${TMP_PGDATA}/PG_VERSION"

LOG_FILE="$(mktemp /tmp/khoj-aio-logs.XXXXXX)"
docker logs "${CONTAINER_NAME}" >"${LOG_FILE}" 2>&1
grep -q "Khoj is ready to engage" "${LOG_FILE}"
rm -f "${LOG_FILE}"
