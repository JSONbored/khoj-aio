# khoj-aio Agent Notes

`khoj-aio` wraps Khoj as a single-container Unraid deployment with an internal PostgreSQL database.

## Runtime Shape

- Upstream app: `ghcr.io/khoj-ai/khoj`
- Internal PostgreSQL with `pgvector`
- Persistent config and model/cache storage under appdata
- Optional first-run secret/admin credential generation

## Important Behavior

- This repo tracks upstream prereleases because current upstream packaging reality is prerelease-oriented.
- `upstream.toml` intentionally uses `stable_only = false`.
- Default mode should remain self-contained and beginner-friendly.
- Advanced users can still override providers, proxies, sandboxes, or external PostgreSQL.

## CI And Publish Policy

- Validation and smoke tests should run on PRs and branch pushes.
- Publish should happen only from the default branch.
- GHCR image naming must stay lowercase.

## What To Preserve

- Keep the XML easy for first-time Unraid users.
- Generated secrets should be persisted so restarts are stable.
- Smoke coverage should include first boot, restart, and persistence.

## Known Good Pattern

- After the first boot, a restart remains a useful validation step because Khoj settings finalize cleanly on restart.
