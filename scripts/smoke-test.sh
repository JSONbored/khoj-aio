#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2310
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

wait_for_container_running() {
	local deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
	while ((SECONDS < deadline)); do
		if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
			return 0
		fi
		sleep 2
	done
	return 1
}

wait_for_http_ready() {
	local deadline=$((SECONDS + HTTP_TIMEOUT_SECONDS))
	while ((SECONDS < deadline)); do
		if curl -fsS "http://127.0.0.1:${HOST_PORT}/" >/dev/null 2>&1; then
			return 0
		fi
		if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
			return 1
		fi
		sleep 2
	done
	return 1
}

cleanup() {
	local exit_code=$?
	if [[ ${KEEP_SMOKE_ARTIFACTS} == "1" && ${exit_code} -ne 0 ]]; then
		cleanup_needed=0
		echo "Smoke test failed; preserving artifacts for debugging." >&2
		echo "SMOKE_CONTAINER_NAME=${CONTAINER_NAME}" >&2
		echo "SMOKE_CONFIG_DIR=${TMP_CONFIG}" >&2
		echo "SMOKE_PGDATA_DIR=${TMP_PGDATA}" >&2
	fi
	if [[ ${cleanup_needed} -eq 1 ]]; then
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

container_ready=0
if wait_for_container_running; then
	if wait_for_http_ready; then
		container_ready=1
	fi
fi
if [[ ${container_ready} -ne 1 ]]; then
	echo "Smoke test container failed to become HTTP-ready." >&2
	docker logs "${CONTAINER_NAME}" >&2 || true
	exit 1
fi

docker exec "${CONTAINER_NAME}" sh -lc 'grep -q "KHOJ_DJANGO_SECRET_KEY" /root/.khoj/aio/generated.env'
docker exec "${CONTAINER_NAME}" sh -lc 'grep -q "KHOJ_ADMIN_PASSWORD" /root/.khoj/aio/generated.env'
docker exec "${CONTAINER_NAME}" sh -lc 'grep -q "KHOJ_INTERNAL_POSTGRES_PASSWORD" /root/.khoj/aio/generated.env'
docker exec "${CONTAINER_NAME}" sh -lc 'test -f /var/lib/postgresql/data/PG_VERSION'
docker exec "${CONTAINER_NAME}" sh -lc 'pg_isready -h 127.0.0.1 -p 5432 -U khoj'

docker restart "${CONTAINER_NAME}" >/dev/null

restart_ready=0
if wait_for_container_running; then
	if wait_for_http_ready; then
		restart_ready=1
	fi
fi
if [[ ${restart_ready} -ne 1 ]]; then
	echo "Smoke test container failed to become HTTP-ready after restart." >&2
	docker logs "${CONTAINER_NAME}" >&2 || true
	exit 1
fi

docker exec "${CONTAINER_NAME}" sh -lc 'test -s /root/.khoj/aio/generated.env'

LOG_FILE="$(mktemp /tmp/khoj-aio-logs.XXXXXX)"
docker logs "${CONTAINER_NAME}" >"${LOG_FILE}" 2>&1
grep -q "Starting Khoj on" "${LOG_FILE}"
rm -f "${LOG_FILE}"

if [[ ${KEEP_SMOKE_ARTIFACTS} != "1" ]]; then
	cleanup_needed=1
else
	cleanup_needed=0
	echo "SMOKE_CONTAINER_NAME=${CONTAINER_NAME}"
	echo "SMOKE_CONFIG_DIR=${TMP_CONFIG}"
	echo "SMOKE_PGDATA_DIR=${TMP_PGDATA}"
fi
