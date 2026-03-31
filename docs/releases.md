# Releases

`khoj-aio` uses upstream-version-plus-AIO-revision releases such as `2.0.0-beta.28-aio.1`.

## Version format

- first wrapper release for upstream `2.0.0-beta.28`: `2.0.0-beta.28-aio.1`
- second wrapper-only release on the same upstream: `2.0.0-beta.28-aio.2`
- first wrapper release after upgrading upstream: `2.0.0-beta.29-aio.1`

## Published image tags

Every `main` build publishes:

- `latest`
- the exact pinned upstream version
- an explicit packaging line tag like `2.0.0-beta.28-aio-v1`
- `sha-<commit>`

## Release flow

1. Trigger **Release / Khoj-AIO** from `main` with `action=prepare`.
2. The workflow computes the next `upstream-aio.N` version and opens a release PR.
3. Review and merge that PR into `main`.
4. Trigger **Release / Khoj-AIO** from `main` again with `action=publish`.
5. The workflow reads the merged `CHANGELOG.md` entry, creates the Git tag, and publishes the GitHub Release.
