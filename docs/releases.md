# Releases

`khoj-aio` uses upstream-version-plus-AIO-revision releases such as `2.0.0-beta.28-aio.1`.

## Version format

- first wrapper release for upstream `2.0.0-beta.28`: `2.0.0-beta.28-aio.1`
- second wrapper-only release on the same upstream: `2.0.0-beta.28-aio.2`
- first wrapper release after upgrading upstream: `2.0.0-beta.29-aio.1`

## Main-branch image publishing

`main` is the package-publishing branch for this repo.

When a build-related change lands on `main`, the CI workflow publishes:

- `latest`
- the exact pinned upstream version
- `sha-<commit>`

Release commits also publish the exact immutable wrapper release tag, for example `2.0.0-beta.28-aio.1`. Ordinary `main` pushes do not overwrite that release tag.

If Docker Hub credentials are configured, the same publish job pushes the matching tags to Docker Hub in parallel with GHCR.

## Template sync behavior

When `khoj-aio.xml` changes on `main`, the build workflow opens or refreshes a pull request against `awesome-unraid` instead of pushing directly. This keeps protected-branch rules intact.

## Release flow

1. Trigger **Prepare Release / Khoj-AIO** from `main`.
2. The workflow computes the next `upstream-aio.N` version, updates `CHANGELOG.md`, syncs the XML `<Changes>` block, and opens a release PR.
3. Review and merge that PR into `main`.
4. Wait for the `CI / Khoj-AIO` run on the release target commit to finish green. That same `main` push also publishes the updated package tags automatically.
5. Trigger **Publish Release / Khoj-AIO** from `main`.
6. The workflow verifies CI on the exact release target commit, creates the Git tag if needed, and publishes the GitHub Release.
