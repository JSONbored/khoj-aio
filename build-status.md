# Build Status

Release-readiness checklist:

- local Docker build passes against a pinned upstream Khoj image digest
- local smoke test passes with generated credentials, restart persistence, and internal PostgreSQL
- GitHub Actions workflows are SHA-pinned and aligned with fleet release/publish behavior
- upstream tracking is configured for release monitoring and PR-based bumps
- optional Docker Hub publishing is supported for CA metadata consumers
