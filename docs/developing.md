# Developing

Back to [README](../README.md).

## Local build and test

From a local checkout of this repository:

```sh
go build ./cmd/scan2pdf
go test ./...
```

## Hosted runtime verification

CI runs tests and native runtime checks on all six release targets. The race
detector runs on every target except Windows ARM64, where Go does not support it.
A lint job checks `gofmt`, `go vet`, staticcheck and govulncheck, and a final
`CI gate` job aggregates the required checks. The
native runtime checks cover image conversion, page ordering, trimming, geometry,
alignment, mirrored margins, overwrite behaviour, and related edge cases. Verification helpers use Python and pypdf only on the
build/test hosts; the installed `scan2pdf` command itself remains a standalone
Go binary.

## Packaging

`cmd/buildpackage` builds the release archive from a tested `scan2pdf`
executable. It verifies that the executable was built with `CGO_ENABLED=0`,
checks its `--version` output, adds the documentation, dependency notices and an
internal checksum list, and writes the archive plus a `.zip.sha256` file.

```sh
go run ./cmd/buildpackage -binary dist/scan2pdf -version v0.2.3 -out dist/packages
```

`release.json` supplies the product name, module path, command name and extra
files. Archives are named `scan2pdf-v<version>-<platform>.zip` for all six
targets. The [release workflow](../.github/workflows/release.yml) accepts only
`vMAJOR.MINOR.PATCH` tags, calls the CI workflow with the tag as the package
version, and publishes the six archives and a combined `SHA256SUMS.txt` only
after every package has verified.

## Optional lossless PDF size optimisation (developer comparison)

For a reproducible comparison with independent decoding and JSON size/timing
results, build the executable, install the verification dependencies, and run:

```sh
go build -o dist/scan2pdf ./cmd/scan2pdf
python -m pip install -r scripts/requirements-runtime.txt
python scripts/compare_compression.py --binary dist/scan2pdf --output dist/comparison
```

On Windows use `dist/scan2pdf.exe` for both build and comparison commands.
Without input options this tests the tiny four-format runtime fixtures plus
synthetic black-and-white, greyscale, colour and noisy pages. Synthetic results
are not predictions for actual scans. The script verifies every decoded pixel,
page dimensions, placement, and that the complete PDF is no larger.

To compare your own scans, use a new output directory each time:

```sh
python scripts/compare_compression.py --binary dist/scan2pdf \
  --input-dir /path/to/scans --prefix "Sample" --output dist/sample-comparison
```

The comparison outputs include `default.pdf`, `optimised.pdf`, and
`comparison.json`. This developer verification needs Python and pypdf; the
scan2pdf executable remains standalone. CI also runs the comparison suite on
supported targets.

User-facing `--optimise` behaviour is documented in [Using scan2pdf](usage.md).

## Repository settings

Maintainer-only GitHub settings are applied with:

```bash
./scripts/apply-repo-settings.sh
```

The script requires `gh` authentication with admin access. It sets the
description, topics, squash-only merging, automatic branch deletion, secret
scanning and push protection, Dependabot alerts and automated security fixes,
SHA-pinned Actions, read-only default workflow tokens, and the required
`CI gate` status check.

Use `--check` to report drift without changing anything:

```bash
./scripts/apply-repo-settings.sh --check
```
