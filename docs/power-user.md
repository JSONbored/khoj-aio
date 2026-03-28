# Power User Guide: Khoj-AIO Configs

This AIO image keeps the first-run path simple, but the advanced template fields let you move much closer to the upstream self-hosted Khoj configuration when you want to.

One upstream note is worth repeating here: after first boot or after changing core environment variables, restart the container once so Khoj reapplies the settings cleanly.

## 1. External Database Overrides

By default, `khoj-aio` keeps everything in one container by running an internal PostgreSQL service and storing its data under your mapped `/root/.khoj` path.

If you already run PostgreSQL elsewhere and want Khoj to use that instead:

1. Open the Unraid template and click **Show more settings...**
2. Set `Use Internal PostgreSQL` to `false`.
3. Fill in the external PostgreSQL variables:
   - `POSTGRES_HOST`
   - `POSTGRES_PORT`
   - `POSTGRES_DB`
   - `POSTGRES_USER`
   - `POSTGRES_PASSWORD`
4. Re-apply the container.

If `POSTGRES_HOST` is set, the wrapper will treat that as an external DB deployment even if you forget to toggle `Use Internal PostgreSQL`.

## 2. Local AI and OpenAI-Compatible Providers

Khoj supports OpenAI-compatible APIs, which makes local and third-party model endpoints easy to use.

### Ollama

Per the Khoj docs, set:

- `OPENAI_BASE_URL=http://your-ollama-host:11434/v1/`

Then start Khoj and finish model selection in the admin panel.

### Other OpenAI-Compatible Providers

You can also point Khoj at:

- vLLM
- LocalAI
- LiteLLM or other compatible gateways
- hosted OpenAI-compatible gateways

Use:

- `OPENAI_BASE_URL`
- `OPENAI_API_KEY` if your endpoint requires one
- `KHOJ_DEFAULT_CHAT_MODEL` if you already know the model name you want to prefer

Khoj's admin panel is still the best place to finalize model definitions and defaults after first boot.

If your model server runs directly on the Unraid host rather than in another container, you may need to add an Unraid extra parameter such as `--add-host=host.docker.internal:host-gateway` and then use `http://host.docker.internal:<port>/v1/` as the base URL.

## 3. Online Search Providers

The upstream `docker-compose.yml` defaults to a separate SearxNG container. This AIO image does not bundle SearxNG internally, so you have two advanced paths:

### Option A: External SearxNG

Set:

- `KHOJ_SEARXNG_URL=http://your-searxng-host:8080`

This best matches the upstream default behavior.

### Option B: Provider APIs

Khoj also supports several external web-search or webpage-read APIs. Use whichever service you prefer:

- `SERPER_DEV_API_KEY`
- `OLOSTEP_API_KEY`
- `FIRECRAWL_API_KEY`
- `EXA_API_KEY`

If none of these are set, Khoj still works fine. Basic webpage reading still works via Khoj's normal HTTP fetching, but online search quality and advanced page extraction will be more limited.

## 4. Code Execution

The upstream compose stack points Khoj at a separate Terrarium container by default.

For this AIO template, use one of these approaches:

### Option A: External Terrarium

Set:

- `KHOJ_TERRARIUM_URL=http://your-terrarium-host:8080`

### Option B: E2B

Set:

- `E2B_API_KEY`

If neither is configured, normal chat/search/document workflows still work, but code execution features will not be available.

## 5. Remote Access and Reverse Proxying

For LAN or internet access, the Khoj docs recommend setting:

- `KHOJ_DOMAIN` to your externally reachable IP or hostname
- `KHOJ_ALLOWED_DOMAIN` to your internal host or reverse-proxy upstream target when needed
- `KHOJ_NO_HTTPS=True` if you are intentionally running over HTTP behind a trusted private network or reverse proxy

Typical examples:

- `KHOJ_DOMAIN=192.168.1.50`
- `KHOJ_DOMAIN=khoj.example.com`
- `KHOJ_ALLOWED_DOMAIN=192.168.1.50`
- `KHOJ_ALLOWED_DOMAIN=khoj`

If you use Nginx Proxy Manager, Traefik, Caddy, or a Cloudflare Tunnel, these settings are the first place to look when you hit CSRF or `DisallowedHost` errors.

## 6. Authentication and Multi-User Access

Khoj's self-hosted defaults are single-user and anonymous-mode friendly. This AIO template follows that same beginner-oriented default.

To enable sign-in:

1. Set `Anonymous Mode` to `false`.
2. Configure magic-link email delivery if desired:
   - `RESEND_API_KEY`
   - `RESEND_EMAIL`
3. Re-apply the container and use the admin panel to manage users.

Without Resend, Khoj can still generate magic links manually through the admin panel, but you will have to send them yourself.

If you are exposing Khoj beyond localhost, strongly consider disabling anonymous mode before opening access externally.

## 7. Voice and Speech Options

Khoj voice input works locally by default after initialization. For optional text-to-speech voice responses, set:

- `ELEVEN_LABS_API_KEY`

OpenAI Whisper-based speech-to-text model choices are then configured through the Khoj admin panel.

## 8. Telemetry

To disable telemetry entirely, set:

- `KHOJ_TELEMETRY_DISABLE=True`

This matches the upstream self-hosting docs.
