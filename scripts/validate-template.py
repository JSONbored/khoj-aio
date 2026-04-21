#!/usr/bin/env python3
from __future__ import annotations

import sys
import xml.etree.ElementTree as ET  # nosec B405
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_PATH = ROOT / "khoj-aio.xml"

REQUIRED_TARGETS = {
    "/root/.khoj",
    "/var/lib/postgresql/data",
    "/root/.cache/huggingface",
    "/root/.cache/torch/sentence_transformers",
    "/var/run/docker.sock",
    "42110",
    "ANTHROPIC_API_KEY",
    "AWS_ACCESS_KEY",
    "AWS_IMAGE_UPLOAD_BUCKET",
    "AWS_SECRET_KEY",
    "AWS_USER_UPLOADED_IMAGES_BUCKET_NAME",
    "E2B_API_KEY",
    "E2B_TEMPLATE",
    "ELEVEN_LABS_API_KEY",
    "EXA_API_KEY",
    "EXA_API_URL",
    "FIRECRAWL_API_KEY",
    "FIRECRAWL_API_URL",
    "GEMINI_API_KEY",
    "GOOGLE_CLIENT_ID",
    "GOOGLE_CLIENT_SECRET",
    "GOOGLE_SEARCH_API_KEY",
    "GOOGLE_SEARCH_ENGINE_ID",
    "GUNICORN_GRACEFUL_TIMEOUT",
    "GUNICORN_KEEP_ALIVE",
    "GUNICORN_TIMEOUT",
    "GUNICORN_WORKERS",
    "KHOJ_ADMIN_EMAIL",
    "KHOJ_ADMIN_PASSWORD",
    "KHOJ_ALLOWED_DOMAIN",
    "KHOJ_ANONYMOUS_MODE",
    "KHOJ_AUTO_READ_WEBPAGE",
    "KHOJ_CDP_URL",
    "KHOJ_DEBUG",
    "KHOJ_DEFAULT_CHAT_MODEL",
    "KHOJ_DJANGO_SECRET_KEY",
    "KHOJ_DOMAIN",
    "KHOJ_EXTRA_ARGS",
    "KHOJ_HOST",
    "KHOJ_LLM_SEED",
    "KHOJ_NO_HTTPS",
    "KHOJ_NON_INTERACTIVE",
    "KHOJ_OPERATOR_ENABLED",
    "KHOJ_OPERATOR_ITERATIONS",
    "KHOJ_RESEARCH_ITERATIONS",
    "KHOJ_SEARXNG_URL",
    "KHOJ_TELEMETRY_DISABLE",
    "KHOJ_TERRARIUM_URL",
    "KHOJ_USE_INTERNAL_POSTGRES",
    "NOTION_OAUTH_CLIENT_ID",
    "NOTION_OAUTH_CLIENT_SECRET",
    "NOTION_REDIRECT_URI",
    "OLOSTEP_API_KEY",
    "OLOSTEP_API_URL",
    "OPENAI_API_KEY",
    "OPENAI_BASE_URL",
    "POSTGRES_DB",
    "POSTGRES_HOST",
    "POSTGRES_PASSWORD",
    "POSTGRES_PORT",
    "POSTGRES_USER",
    "RESEND_API_KEY",
    "RESEND_AUDIENCE_ID",
    "RESEND_EMAIL",
    "SERPER_DEV_API_KEY",
    "TWILIO_ACCOUNT_SID",
    "TWILIO_AUTH_TOKEN",
    "TWILIO_VERIFICATION_SID",
}

def main() -> int:
    tree = ET.parse(TEMPLATE_PATH)  # nosec B314
    root = tree.getroot()

    targets = {
        elem.attrib["Target"]
        for elem in root.findall(".//Config")
        if "Target" in elem.attrib and elem.attrib["Target"]
    }

    missing = sorted(REQUIRED_TARGETS - targets)
    if missing:
        print("khoj-aio.xml is missing required runtime targets:", file=sys.stderr)
        for target in missing:
            print(f"  - {target}", file=sys.stderr)
        return 1

    overview = (root.findtext("Overview") or "").strip()
    if not overview:
        print("khoj-aio.xml is missing a non-empty <Overview>", file=sys.stderr)
        return 1

    changes = (root.findtext("Changes") or "").strip()
    if not changes:
        print("khoj-aio.xml is missing a non-empty <Changes> section", file=sys.stderr)
        return 1
    invalid_option_configs: list[str] = []
    invalid_pipe_configs: list[str] = []
    for config in root.findall(".//Config"):
        name = config.attrib.get("Name", config.attrib.get("Target", "<unnamed>"))
        if config.findall("Option"):
            invalid_option_configs.append(name)

        default = config.attrib.get("Default", "")
        if "|" not in default:
            continue

        allowed_values = default.split("|")
        selected_value = (config.text or "").strip()
        if selected_value not in allowed_values:
            invalid_pipe_configs.append(
                f"{name} (selected={selected_value!r}, allowed={allowed_values!r})"
            )

    if invalid_option_configs:
        print(
            "khoj-aio.xml uses nested <Option> tags, which are not allowed by the catalog-safe template format:",
            file=sys.stderr,
        )
        for name in invalid_option_configs:
            print(f"  - {name}", file=sys.stderr)
        return 1

    if invalid_pipe_configs:
        print(
            "khoj-aio.xml has pipe-delimited defaults whose selected value is not one of the allowed options:",
            file=sys.stderr,
        )
        for detail in invalid_pipe_configs:
            print(f"  - {detail}", file=sys.stderr)
        return 1

    print(
        f"khoj-aio.xml parsed successfully and includes {len(REQUIRED_TARGETS)} required targets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
