# Releases

`khoj-aio` uses upstream-version-plus-AIO-revision releases such as `2.0.0-beta.28-aio.1`.

## Published image tags

Every `main` build publishes:

- `latest`
- the exact pinned upstream version
- an explicit packaging line tag like `2.0.0-beta.28-aio-v1`
- `sha-<commit>`

## Release flow

1. Trigger **Release / Khoj-AIO** from `main`.
2. The workflow computes the next `upstream-aio.N` version and opens a release PR.
3. Merge that PR into `main`.
4. After merge, the workflow creates the Git tag and GitHub Release automatically.
