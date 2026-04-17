# khoj-aio

<div align="center">

<img src="https://socialify.git.ci/JSONbored/khoj-aio/image?custom_description=Unraid-first+All-in-One+Khoj+image+with+beginner-safe+defaults+and+a+power-user+config+surface.&custom_language=Dockerfile&description=1&font=Raleway&forks=1&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F64120301%3Fv%3D4&name=1&owner=1&pattern=Solid&stargazers=1&theme=Dark" alt="khoj-aio" width="640" height="320" />

</div>

---

An Unraid-first, single-container deployment of [Khoj](https://github.com/khoj-ai/khoj) for people who want the easiest reliable self-hosted install without manually wiring PostgreSQL or reworking the upstream compose stack for Unraid.

`khoj-aio` keeps the critical first-boot dependency bundled: PostgreSQL with `pgvector`. The wrapper is opinionated for a predictable beginner install, but it does not hide the real tradeoffs: remote exposure still needs correct auth and domain settings, operator/computer features carry meaningful security implications, and advanced search/sandbox/provider integrations still consume real resources.

## What This Image Includes

- Khoj web UI and API on port `42110`
- Embedded PostgreSQL with `pgvector`
- Persistent appdata paths for config, database state, and model caches
- First-run generation for `KHOJ_DJANGO_SECRET_KEY`, `KHOJ_ADMIN_PASSWORD`, and the internal DB password when left unset
- Unraid CA template at [khoj-aio.xml](khoj-aio.xml)

## Beginner Install

If you want the simplest supported path:

1. Install the Unraid template.
2. Leave the default appdata paths in place.
3. Optionally set `KHOJ_ADMIN_EMAIL`, `KHOJ_ADMIN_PASSWORD`, and `KHOJ_DJANGO_SECRET_KEY`.
4. Leave `KHOJ_ANONYMOUS_MODE=true` for the default private single-user flow.
5. Start the container and wait for first-boot initialization to complete.
6. Open the web UI on port `42110`.
7. Restart the container once after the initial setup so all settings are fully applied.

If you leave the admin password or Django secret blank, the wrapper generates secure values and writes them to `/root/.khoj/aio/generated.env` inside your mapped config path.

## Power User Surface

This repo is deliberately not a stripped-down wrapper. The template now tracks the practical self-hosted environment surface exposed by upstream source and docs, plus AIO-specific controls for the bundled database flow. In Advanced View you can:

- move PostgreSQL out of the container with the standard `POSTGRES_*` settings
- point Khoj at OpenAI, Anthropic, Gemini, Ollama, LM Studio, LiteLLM, vLLM, or other OpenAI-compatible endpoints
- configure SearxNG, Serper, Google Search, Firecrawl, Olostep, or Exa for search and webpage reading
- enable Terrarium or E2B code execution
- tune operator/computer behavior and optionally mount the Docker socket for that path
- configure Resend, Google auth, Notion OAuth, Twilio, and AWS-backed upload storage
- expose runtime tuning knobs like Gunicorn worker/timeouts and research iteration limits

The wrapper still defaults to the internal bundled database and a minimal beginner-safe install path so new Unraid users are not forced into extra containers on day one.

## Runtime Notes

- Upstream Khoj releases are currently tagged as beta releases. This wrapper tracks the latest published production-facing release line rather than floating `latest`.
- The internal PostgreSQL service is bound to loopback inside the container and now uses a generated per-install password instead of a fixed hardcoded credential.
- The bundled database user is no longer created as a PostgreSQL superuser; the wrapper creates the `vector` extension as `postgres` during initialization instead.
- Search, webpage-reading, and code-execution integrations are intentionally optional. The AIO image does not currently bundle SearxNG or Terrarium by default because that would materially increase resource cost and attack surface for all users.
- If you expose Khoj beyond your LAN, you should set strong credentials, set `KHOJ_DOMAIN` and `KHOJ_ALLOWED_DOMAIN` correctly, and strongly consider disabling anonymous mode.

## Publishing and Releases

- Wrapper releases use the upstream version plus an AIO revision, such as `2.0.0-beta.28-aio.1`.
- The repo monitors upstream releases and image digest changes through [upstream.toml](upstream.toml) and [scripts/check-upstream.py](scripts/check-upstream.py).
- Release notes are generated with `git-cliff`.
- The Unraid template `<Changes>` block is synced from `CHANGELOG.md` during release preparation.
- `main` publishes `latest`, the pinned upstream version tag, an explicit AIO packaging line tag, and `sha-<commit>`.
- When Docker Hub credentials are configured, the same publish flow pushes Docker Hub tags in parallel with GHCR so the CA template can read Docker Hub metadata.

See [docs/releases.md](docs/releases.md) for the release workflow details.

## Validation

Local validation is built around:

- XML validation for the audited template surface
- shell and Python syntax checks
- local Docker build on `linux/amd64`
- end-to-end smoke coverage for first boot, generated credentials, internal PostgreSQL readiness, restart, and persistence

## Support

- Repo issues: [JSONbored/khoj-aio issues](https://github.com/JSONbored/khoj-aio/issues)
- Upstream app: [khoj-ai/khoj](https://github.com/khoj-ai/khoj)

## Funding

If this work saves you time, support it here:

- [GitHub Sponsors](https://github.com/sponsors/JSONbored)
- [Ko-fi](https://ko-fi.com/jsonbored)
- [Buy Me a Coffee](https://buymeacoffee.com/jsonbored)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=JSONbored/khoj-aio&theme=dark)](https://star-history.com/#JSONbored/khoj-aio&Date)
