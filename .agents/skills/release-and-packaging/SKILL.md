---
name: release-and-packaging
description: >-
  Release and package this Go command-line tool. Use when tagging a release,
  changing the release workflow, the packaging tool, archive contents,
  checksums, or INSTALL.md.
---

# Release and packaging

## Contract

- Tags use `vMAJOR.MINOR.PATCH`. Reject other tag shapes.
- Build and verify on six native targets: `macos-intel`, `macos-apple-silicon`,
  `windows-x64`, `windows-arm64`, `linux-x64`, `linux-arm64`.
- Archive name: `<product>-v<version>-<platform>.zip` on every platform.
- Each archive contains: the executable, `README.md`, `INSTALL.md`, the `docs/`
  tree, `LICENSE`, `THIRD_PARTY_NOTICES.txt`, and `VERSION.txt`.
- Publish a `.sha256` beside each archive and a combined `SHA256SUMS.txt`.
- Verify the packaged executable runs `--version` and reports the tag before
  publishing.
- Release title: `v<version>`. Generate release notes from the commits.
- Workflow permissions: top level `contents: read`; only the publish job gets
  `contents: write`.
- Do not publish a partial release. If a platform fails, fix it and re-run; do
  not leave a tag without a verified release.

## Packaging tool

Use the repository's Go packaging command (for example `cmd/buildpackage`) for
archive creation, document copying, dependency notices, and checksums. Python is
allowed only for domain-specific verification that cannot reasonably be written
in Go.

## Install documentation

`INSTALL.md` is required when the repository publishes release archives.
`docs/install-go.md` is the With Go path; `INSTALL.md` is the Without Go path.
Link both from the README Install section.
