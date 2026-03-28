<div align="center">

# Khoj AIO (All-in-One) for Unraid

[![Docker Image](https://img.shields.io/badge/Image-ghcr.io%2Fjsonbored%2Fkhoj--aio-blue)](https://github.com/JSONbored/khoj-aio/pkgs/container/khoj-aio)
[![GitHub License](https://img.shields.io/github/license/khoj-ai/khoj?color=green)](https://github.com/khoj-ai/khoj/blob/main/LICENSE)
[![Unraid Community Applications](https://img.shields.io/badge/Unraid-CA%20Template-orange)](https://unraid.net/community/apps)

An ultra-simplified, self-contained deployment of [Khoj](https://github.com/khoj-ai/khoj) designed for Unraid users who want a clean, beginner-friendly install without giving up advanced controls.

</div>

---

Instead of making newcomers wire up a multi-container `docker-compose` stack by hand, this AIO wrapper runs Khoj inside a single Unraid container and manages an internal PostgreSQL database automatically for the easiest possible first boot. Advanced users can still override the defaults and point Khoj at external model providers, search backends, code sandboxes, reverse proxies, or an external PostgreSQL database.

## What's Inside the AIO Container
This image uses `s6-overlay v3` to wrap the upstream `ghcr.io/khoj-ai/khoj` image with a more Unraid-friendly startup flow:

- The Khoj web app and API
- An internally managed PostgreSQL database for a true single-container setup
- First-run credential bootstrapping for `KHOJ_DJANGO_SECRET_KEY` and admin password if you leave them blank
- Persistent config and model cache storage mapped into Unraid `appdata`

This keeps the install simple for beginners while preserving the upstream environment variables and admin-panel driven customization model for power users.

## Installation (For Beginners)

1. Add this repository to Unraid Community Applications, or import the XML directly.
2. Install **Khoj AIO**.
3. Leave the default paths alone unless you know you want them elsewhere.
4. Optionally set your own `Admin Email`, `Admin Password`, and `Django Secret Key`.
5. Click **Apply**.

If you leave the password or secret blank, the container will generate secure values on first boot and save them under `/root/.khoj/aio/generated.env` inside your mapped config folder.

Wait about 30-60 seconds on the first launch. Once the logs show that Khoj is ready, open the WebUI on port `42110`.

After the very first boot, restart the container once. Khoj's self-host docs recommend a restart after initial setup so all settings are fully applied.

## Power User Configuration

This template is intentionally beginner-first, but it does not lock you into beginner-only behavior.

If you click **Show more settings...** in Unraid, you can configure:

- [OpenAI-compatible local providers like Ollama, vLLM, LocalAI, or compatible gateways](docs/power-user.md#2-local-ai-and-openai-compatible-providers)
- [External PostgreSQL instead of embedded DB mode](docs/power-user.md#1-external-database-overrides)
- [Remote access, reverse proxy, and custom domain handling](docs/power-user.md#5-remote-access-and-reverse-proxying)
- [Magic link authentication with Resend](docs/power-user.md#6-authentication-and-multi-user-access)
- [External web search and code execution backends](docs/power-user.md#3-online-search-providers) and [here](docs/power-user.md#4-code-execution)
- [Telemetry disablement and voice/TTS options](docs/power-user.md#7-voice-and-speech-options)

## Data Persistence

Your data survives container updates because the important paths are mapped to Unraid storage:

- Khoj config and uploads: `/mnt/user/appdata/khoj-aio/config`
- Internal PostgreSQL data: `/mnt/user/appdata/khoj-aio/postgres`
- Hugging Face model cache: `/mnt/user/appdata/khoj-aio/models/huggingface`
- SentenceTransformer cache: `/mnt/user/appdata/khoj-aio/models/sentence-transformers`

If you back up `/mnt/user/appdata/khoj-aio`, you are backing up the important state for this deployment.

## Notes

- This AIO image manages its own internal PostgreSQL database inside the container so first boot works cleanly without extra sidecars.
- Upstream `docker-compose` also includes separate SearxNG and Terrarium containers. In this AIO design those are optional advanced integrations, not first-boot requirements.
- Basic webpage reading still works out of the box, since Khoj can fetch pages directly without an external scraper.
- For remote IP/domain access, you should set `KHOJ_DOMAIN` and, when needed, `KHOJ_ALLOWED_DOMAIN` to avoid admin-panel CSRF or `DisallowedHost` issues.
- Google OAuth is not exposed in this base AIO because upstream documents it against the `khoj-cloud` prod image rather than the standard self-hosted image.

## License and Acknowledgements

- The upstream application is maintained by the [khoj-ai/khoj](https://github.com/khoj-ai/khoj) team.
- Khoj is licensed under **AGPL-3.0**.
- This repository is an Unraid-focused AIO wrapper intended to make self-hosting easier for homelab users.
