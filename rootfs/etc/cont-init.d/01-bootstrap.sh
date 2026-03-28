#!/command/with-contenv bash
set -euo pipefail

mkdir -p /root/.khoj/aio /root/.cache/huggingface /root/.cache/torch/sentence_transformers

ENV_FILE="/root/.khoj/aio/generated.env"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

persist_if_missing() {
    local key="$1"
    local value="$2"
    if ! grep -q "^${key}=" "$ENV_FILE"; then
        printf '%s="%s"\n' "$key" "$value" >> "$ENV_FILE"
    fi
}

if [ -z "${KHOJ_DJANGO_SECRET_KEY:-}" ]; then
    persist_if_missing "KHOJ_DJANGO_SECRET_KEY" "$(openssl rand -hex 64)"
fi

if [ -z "${KHOJ_ADMIN_PASSWORD:-}" ]; then
    persist_if_missing "KHOJ_ADMIN_PASSWORD" "$(openssl rand -base64 32 | tr -d '\n')"
fi

if [ -z "${KHOJ_ADMIN_EMAIL:-}" ]; then
    persist_if_missing "KHOJ_ADMIN_EMAIL" "admin@khoj.local"
fi

echo "[khoj-aio] Generated credentials are stored at $ENV_FILE if any first-run values were auto-created."
