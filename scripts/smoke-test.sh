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

READY_LOG="Khoj is ready to engage"

for _ in $(seq 1 240); do
    CURRENT_LOGS="$(docker logs "${CONTAINER_NAME}" 2>&1 || true)"
    if [[ "${CURRENT_LOGS}" == *"${READY_LOG}"* ]]; then
        break
    fi
    if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
        echo "Smoke test container exited unexpectedly." >&2
        docker logs "${CONTAINER_NAME}" >&2 || true
        exit 1
    fi
    sleep 2
done

CURRENT_LOGS="$(docker logs "${CONTAINER_NAME}" 2>&1 || true)"
[[ "${CURRENT_LOGS}" == *"${READY_LOG}"* ]]

for _ in $(seq 1 30); do
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
grep -q "${READY_LOG}" "${LOG_FILE}"
rm -f "${LOG_FILE}"
