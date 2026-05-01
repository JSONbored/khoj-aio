# Releases

`khoj-aio` uses upstream-version-plus-AIO-revision releases such as `2.0.0-beta.28-aio.1`.

## Version format

- first wrapper release for upstream `2.0.0-beta.28`: `2.0.0-beta.28-aio.1`
- second wrapper-only release on the same upstream: `2.0.0-beta.28-aio.2`
- first wrapper release after upgrading upstream: `2.0.0-beta.29-aio.1`

## Main-branch image publishing

`main` is the package-publishing branch for this repo.

When a build-related change lands on `main`, the central `aio-fleet` publish path publishes:

- `latest`
- the exact pinned upstream version
- `sha-<commit>`

Release commits also publish the exact immutable wrapper release tag, for example `2.0.0-beta.28-aio.1`. Ordinary `main` pushes do not overwrite that release tag.

Central publish uses Docker Hub credentials and the shared GHCR token stored in `aio-fleet`.

## Template sync behavior

When catalog XML changes, `aio-fleet` opens or refreshes the `awesome-unraid` catalog pull request instead of pushing directly. This keeps protected-branch rules intact.

## Release flow

1. From `aio-fleet`, run `python -m aio_fleet release status --repo khoj-aio` to inspect the next release.
2. Run `python -m aio_fleet release prepare --repo khoj-aio` on a release branch, then open a `chore(release): <version>` PR.
3. Review and merge that PR into `main`.
4. Run the central `aio-fleet` control check for the release target commit with publish enabled, and require `aio-fleet / required` to pass.
5. Run `python -m aio_fleet release publish --repo khoj-aio` from `aio-fleet` to create the GitHub Release.
