# Developing

Back to [README](../README.md).

## Local build and test

From a local checkout of this repository:

```sh
go build ./cmd/scan2pdf
go test ./...
```

## Hosted runtime verification

CI runs tests and native runtime checks on supported operating-system and
architecture combinations. Those checks cover image conversion, page ordering,
trimming, geometry, alignment, mirrored margins, overwrite behaviour, and
related edge cases. Verification helpers use Python and pypdf only on the
build/test hosts; the installed `scan2pdf` command itself remains a standalone
Go binary.

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
