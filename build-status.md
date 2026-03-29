Release-readiness checklist:

- local Docker build passes against a pinned upstream Khoj image digest
- local smoke test passes with generated credentials and internal PostgreSQL
- GitHub Actions workflows are SHA-pinned and manually dispatchable
- upstream tracking is configured for release monitoring and PR-based bumps
