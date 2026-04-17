# Power User Guide: Khoj-AIO Configs

This AIO image keeps the first-run path simple, but the advanced template fields let you move much closer to the full upstream self-hosted runtime surface when you want to.

One upstream note is worth repeating here: after first boot or after changing core environment variables, restart the container once so Khoj reapplies the settings cleanly.

## 1. External Database Overrides

By default, `khoj-aio` keeps everything in one container by running an internal PostgreSQL service and storing its data under your mapped `/var/lib/postgresql/data` path, while app config and generated secrets live under `/root/.khoj`.

If you already run PostgreSQL elsewhere and want Khoj to use that instead:

1. Open the Unraid template and click **Show more settings...**
2. Set `KHOJ_USE_INTERNAL_POSTGRES=false`.
3. Fill in the external PostgreSQL variables:
   - `POSTGRES_HOST`
   - `POSTGRES_PORT`
   - `POSTGRES_DB`
   - `POSTGRES_USER`
   - `POSTGRES_PASSWORD`
4. Re-apply the container.

If `POSTGRES_HOST` is set, the wrapper treats that as an external DB deployment even if you forget to toggle `KHOJ_USE_INTERNAL_POSTGRES`.

## 2. Local AI and OpenAI-Compatible Providers

Khoj supports OpenAI-compatible APIs, which makes local and third-party model endpoints easy to use.

Typical knobs:

- `OPENAI_BASE_URL`
- `OPENAI_API_KEY`
- `KHOJ_DEFAULT_CHAT_MODEL`
- `KHOJ_LLM_SEED`

### Ollama

Set:

- `OPENAI_BASE_URL=http://host.docker.internal:11434/v1/`

If your LLM server runs on the Unraid host rather than in another container, you may also need an Unraid extra parameter such as `--add-host=host.docker.internal:host-gateway`.

### Other OpenAI-Compatible Providers

You can also point Khoj at:

- vLLM
- LM Studio
- LiteLLM
- LocalAI
- hosted OpenAI-compatible gateways

Khoj's admin panel is still the best place to finalize model definitions and defaults after first boot.

## 3. Search and Webpage Reading

The upstream `docker-compose.yml` defaults to separate search services. This AIO image keeps those integrations optional.

### Search providers

Use one or more of:

- `KHOJ_SEARXNG_URL`
- `SERPER_DEV_API_KEY`
- `GOOGLE_SEARCH_API_KEY`
- `GOOGLE_SEARCH_ENGINE_ID`
- `FIRECRAWL_API_KEY`
- `EXA_API_KEY`

### Webpage reading providers

Use one or more of:

- `OLOSTEP_API_KEY`
- `FIRECRAWL_API_KEY`
- `EXA_API_KEY`

Optional API base URL overrides:

- `OLOSTEP_API_URL`
- `FIRECRAWL_API_URL`
- `EXA_API_URL`

Optional behavior override:

- `KHOJ_AUTO_READ_WEBPAGE=true`

If none of these are set, Khoj still works. Search and page-read quality will just depend more heavily on the basic self-hosted path.

## 4. Code Execution and Operator

### Code execution

Use one of:

- `KHOJ_TERRARIUM_URL=http://your-terrarium-host:8080`
- `E2B_API_KEY`

Optional E2B override:

- `E2B_TEMPLATE`

### Operator / computer mode

Enable only if you understand the security tradeoff:

- `KHOJ_OPERATOR_ENABLED=true`
- mount `/var/run/docker.sock`

Optional expert knobs:

- `KHOJ_OPERATOR_ITERATIONS`
- `KHOJ_CDP_URL`

If you do not configure these, normal chat/search/document workflows still work.

## 5. Remote Access and Reverse Proxying

For LAN or internet access, the Khoj docs recommend setting:

- `KHOJ_DOMAIN`
- `KHOJ_ALLOWED_DOMAIN`
- `KHOJ_NO_HTTPS=true` when you intentionally serve plain HTTP on a trusted LAN or behind a reverse proxy that terminates TLS

Typical examples:

- `KHOJ_DOMAIN=192.168.1.50`
- `KHOJ_DOMAIN=khoj.example.com`
- `KHOJ_ALLOWED_DOMAIN=server`
- `KHOJ_ALLOWED_DOMAIN=192.168.1.50`

If you use Nginx Proxy Manager, Traefik, Caddy, or Cloudflare Tunnel, these settings are the first place to look when you hit CSRF or `DisallowedHost` errors.

## 6. Authentication and Multi-User Access

Khoj's self-hosted defaults are single-user and anonymous-mode friendly. This AIO template follows that same beginner-oriented default.

To enable sign-in:

1. Set `KHOJ_ANONYMOUS_MODE=false`.
2. Configure one of the auth paths below.
3. Re-apply the container and restart once.

### Magic links with Resend

- `RESEND_API_KEY`
- `RESEND_EMAIL`
- `RESEND_AUDIENCE_ID` (optional)

Without Resend, Khoj can still generate magic links manually through the admin panel, but you must send them yourself.

### Google OAuth

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`

Upstream currently documents Google OAuth mainly against the prod `khoj-cloud` image. Treat this as an expert path on the standard `khoj` image until you confirm your exact flow works.

## 7. Voice, Notion, Storage, and Twilio

### Voice / TTS

- `ELEVEN_LABS_API_KEY`

### Notion OAuth

- `NOTION_OAUTH_CLIENT_ID`
- `NOTION_OAUTH_CLIENT_SECRET`
- `NOTION_REDIRECT_URI`

### AWS-backed upload storage

- `AWS_ACCESS_KEY`
- `AWS_SECRET_KEY`
- `AWS_IMAGE_UPLOAD_BUCKET`
- `AWS_USER_UPLOADED_IMAGES_BUCKET_NAME`

### Twilio

- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_VERIFICATION_SID`

These are advanced integrations. Beginners can leave them unset.

## 8. Runtime Tuning and Privacy

Optional runtime tuning:

- `GUNICORN_WORKERS`
- `GUNICORN_TIMEOUT`
- `GUNICORN_GRACEFUL_TIMEOUT`
- `GUNICORN_KEEP_ALIVE`
- `KHOJ_RESEARCH_ITERATIONS`

Telemetry:

- `KHOJ_TELEMETRY_DISABLE=true`

Leave the runtime knobs unset unless you have a specific reason to change them. The defaults are safer than random tuning.
