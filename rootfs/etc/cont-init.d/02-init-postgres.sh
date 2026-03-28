#!/command/with-contenv bash
set -euo pipefail

case "${KHOJ_USE_INTERNAL_POSTGRES:-true}" in
    false|FALSE|False|0|no|NO|No)
        exit 0
        ;;
esac

if [ -n "${POSTGRES_HOST:-}" ]; then
    exit 0
fi

PG_VERSION="$(ls /usr/lib/postgresql | sort -V | tail -n1)"
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PGDATA="/var/lib/postgresql/data"
PGUSER="khoj"
PGPASS="khoj_internal_pass"
PGDB="khoj"

mkdir -p "$PGDATA" /run/postgresql
chown -R postgres:postgres "$PGDATA" /run/postgresql
chmod 700 "$PGDATA"

if [ -z "$(find "$PGDATA" -mindepth 1 -maxdepth 1 2>/dev/null | head -n1)" ]; then
    echo "[khoj-aio] Initializing internal PostgreSQL database..."
    su postgres -s /bin/sh -c "\"$PG_BIN/initdb\" -D \"$PGDATA\" >/dev/null"
fi

if ! su postgres -s /bin/sh -c "\"$PG_BIN/pg_ctl\" -D \"$PGDATA\" status" >/dev/null 2>&1; then
    su postgres -s /bin/sh -c "\"$PG_BIN/pg_ctl\" -D \"$PGDATA\" -w start >/dev/null"
fi

su postgres -s /bin/sh -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${PGUSER}'\" | grep -q 1" || \
    su postgres -s /bin/sh -c "psql -c \"CREATE USER ${PGUSER} WITH SUPERUSER PASSWORD '${PGPASS}';\" >/dev/null"

su postgres -s /bin/sh -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${PGDB}'\" | grep -q 1" || \
    su postgres -s /bin/sh -c "psql -c \"CREATE DATABASE ${PGDB} OWNER ${PGUSER};\" >/dev/null"

su postgres -s /bin/sh -c "\"$PG_BIN/pg_ctl\" -D \"$PGDATA\" -m fast -w stop >/dev/null"
