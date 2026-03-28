#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-khoj-aio:test}"
CONTAINER_NAME="${CONTAINER_NAME:-khoj-aio-smoke}"
HOST_PORT="${HOST_PORT:-54210}"
READY_TIMEOUT_SECONDS="${READY_TIMEOUT_SECONDS:-480}"
HTTP_TIMEOUT_SECONDS="${HTTP_TIMEOUT_SECONDS:-60}"
KEEP_SMOKE_ARTIFACTS="${KEEP_SMOKE_ARTIFACTS:-0}"
TMP_CONFIG="$(mktemp -d /tmp/khoj-aio-config.XXXXXX)"
TMP_PGDATA="$(mktemp -d /tmp/khoj-aio-pg.XXXXXX)"

cleanup_needed=1

cleanup() {
    local exit_code=$?
    if [[ "${KEEP_SMOKE_ARTIFACTS}" == "1" && "${exit_code}" -ne 0 ]]; then
        cleanup_needed=0
        echo "Smoke test failed; preserving artifacts for debugging." >&2
        echo "SMOKE_CONTAINER_NAME=${CONTAINER_NAME}" >&2
        echo "SMOKE_CONFIG_DIR=${TMP_CONFIG}" >&2
        echo "SMOKE_PGDATA_DIR=${TMP_PGDATA}" >&2
    fi
    if [[ "${cleanup_needed}" -eq 1 ]]; then
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        rm -rf "${TMP_CONFIG}" "${TMP_PGDATA}"
    fi
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
ready_deadline=$((SECONDS + READY_TIMEOUT_SECONDS))

while (( SECONDS < ready_deadline )); do
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

http_deadline=$((SECONDS + HTTP_TIMEOUT_SECONDS))

while (( SECONDS < http_deadline )); do
    if curl -fsS "http://127.0.0.1:${HOST_PORT}/" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

curl -fsS "http://127.0.0.1:${HOST_PORT}/" >/dev/null
docker exec "${CONTAINER_NAME}" sh -lc 'grep -q "KHOJ_DJANGO_SECRET_KEY" /root/.khoj/aio/generated.env'
docker exec "${CONTAINER_NAME}" sh -lc 'grep -q "KHOJ_ADMIN_PASSWORD" /root/.khoj/aio/generated.env'
test -f "${TMP_PGDATA}/PG_VERSION"

LOG_FILE="$(mktemp /tmp/khoj-aio-logs.XXXXXX)"
docker logs "${CONTAINER_NAME}" >"${LOG_FILE}" 2>&1
grep -q "${READY_LOG}" "${LOG_FILE}"
rm -f "${LOG_FILE}"

if [[ "${KEEP_SMOKE_ARTIFACTS}" != "1" ]]; then
    cleanup_needed=1
else
    cleanup_needed=0
    echo "SMOKE_CONTAINER_NAME=${CONTAINER_NAME}"
    echo "SMOKE_CONFIG_DIR=${TMP_CONFIG}"
    echo "SMOKE_PGDATA_DIR=${TMP_PGDATA}"
fi
