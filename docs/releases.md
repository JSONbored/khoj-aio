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
- an explicit packaging line tag like `2.0.0-beta.28-aio-v1`
- `sha-<commit>`

If Docker Hub credentials are configured, the same publish job pushes the matching tags to Docker Hub in parallel with GHCR.

## Template sync behavior

When `khoj-aio.xml` changes on `main`, the build workflow opens or refreshes a pull request against `awesome-unraid` instead of pushing directly. This keeps protected-branch rules intact.

## Release flow

### Standard

1. Trigger **Release / Khoj-AIO** from `main` with `action=prepare`.
2. The workflow computes the next `upstream-aio.N` version, updates `CHANGELOG.md`, syncs the template `<Changes>` block, and opens a release PR.
3. Review and merge that PR into `main`.
4. Trigger **Release / Khoj-AIO** from `main` again with `action=publish`.
5. The workflow reads the merged `CHANGELOG.md` entry, creates the Git tag and GitHub Release, then triggers the image-publish workflow with the correct `aio-vN` track tag.

### Full

If you want the workflow to handle the whole release path:

1. Trigger **Release / Khoj-AIO** from `main` with `action=full`.
2. The workflow prepares the release PR, optionally auto-merges it, then triggers the publish step.

Use `full` only when branch protections and tokens are already configured correctly.
