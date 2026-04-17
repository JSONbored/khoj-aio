#!/command/with-contenv bash
# shellcheck shell=bash
# shellcheck disable=SC2249,SC2312
set -euo pipefail

ENV_FILE="/root/.khoj/aio/generated.env"
if [[ -f ${ENV_FILE} ]]; then
	set -a
	# shellcheck disable=SC1090
	. "${ENV_FILE}"
	set +a
fi

case "${KHOJ_USE_INTERNAL_POSTGRES:-true}" in
false | FALSE | False | 0 | no | NO | No)
	exit 0
	;;
*) ;;
esac

if [[ -n ${POSTGRES_HOST-} ]]; then
	exit 0
fi

PG_VERSION="$(find /usr/lib/postgresql -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tail -n1)"
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PGDATA="/var/lib/postgresql/data"
PGUSER="khoj"
PGPASS="${KHOJ_INTERNAL_POSTGRES_PASSWORD-}"
PGDB="khoj"

if [[ -z ${PGPASS} ]]; then
	echo "[khoj-aio] Missing generated internal PostgreSQL password." >&2
	exit 1
fi

mkdir -p "${PGDATA}" /run/postgresql
chown -R postgres:postgres "${PGDATA}" /run/postgresql
chmod 700 "${PGDATA}"

if [[ -z "$(find "${PGDATA}" -mindepth 1 -maxdepth 1 2>/dev/null | head -n1)" ]]; then
	echo "[khoj-aio] Initializing internal PostgreSQL database..."
	su postgres -s /bin/sh -c "\"${PG_BIN}/initdb\" -D \"${PGDATA}\" --auth-local=peer --auth-host=scram-sha-256 >/dev/null"
fi

pg_status_cmd="\"${PG_BIN}/pg_ctl\" -D \"${PGDATA}\" status"
if ! su postgres -s /bin/sh -c "${pg_status_cmd}" >/dev/null 2>&1; then
	su postgres -s /bin/sh -c "\"${PG_BIN}/pg_ctl\" -D \"${PGDATA}\" -w start >/dev/null"
fi

su postgres -s /bin/sh -c "psql -v ON_ERROR_STOP=1 -c \"DO \\\$\\\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${PGUSER}') THEN CREATE ROLE ${PGUSER} LOGIN PASSWORD '${PGPASS}'; ELSE ALTER ROLE ${PGUSER} WITH LOGIN PASSWORD '${PGPASS}'; END IF; END \\\$\\\$;\" >/dev/null"

su postgres -s /bin/sh -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${PGDB}'\" | grep -q 1" ||
	su postgres -s /bin/sh -c "psql -c \"CREATE DATABASE ${PGDB} OWNER ${PGUSER};\" >/dev/null"

su postgres -s /bin/sh -c "psql -d \"${PGDB}\" -c \"CREATE EXTENSION IF NOT EXISTS vector;\" >/dev/null"

su postgres -s /bin/sh -c "\"${PG_BIN}/pg_ctl\" -D \"${PGDATA}\" -m fast -w stop >/dev/null"
