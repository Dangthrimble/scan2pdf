# scan2pdf

`scan2pdf` (formerly `score2pdf`) turns a numbered set of scan-page images into a print-ready PDF.
See the [backlog](BACKLOG.md) for outstanding work.

It is designed for a simple workflow: manually remove scanner/book-edge noise and correct any obvious rotation first, then let `scan2pdf` trim the remaining white border, fit each page proportionally onto a PDF page, and write the pages in numeric order.

The program is written in pure Go and has no runtime dependency on ImageMagick, Python, `img2pdf`, or any external PDF library. JPEG and PNG use Go's standard image decoders; TIFF and BMP use the pure-Go `golang.org/x/image` decoders, compiled into the executable.

## Git

Git is a tool that downloads and updates project files on your computer.

- **Install:** get Git from [git-scm.com/downloads](https://git-scm.com/downloads) (choose the installer for your computer) and run it.
- **Upgrade:** download a newer installer from the same page and run it again, or use your computer’s usual update method.

Open a **new** Terminal window and check:

```bash
git --version
```

## This project’s files (repository)

- **First time:** download a full copy of the project. In Terminal:

  ```bash
  git clone https://github.com/Dangthrimble/scan2pdf.git
  cd scan2pdf
  ```

  This creates a folder named `scan2pdf` with the project files inside.

- **Later:** get the latest project files:

  ```bash
  cd scan2pdf
  git pull
  ```

Updating these files does **not** by itself update the installed command. To refresh the command, follow **Update** below.

## Go

Go is the programming toolkit used to download and install this command-line program.

- **Install:** get Go **1.26** or newer from [go.dev/dl](https://go.dev/dl/). Choose the installer for your computer, run it, and accept the defaults unless you know you need otherwise.
- **Check:** open a **new** Terminal window and run:

  ```bash
  go version
  ```

  You should see a version of 1.26 or higher.

- **Update:** later, download a newer installer from the same page and run it again (or follow that page’s update steps), then open a new Terminal and run `go version` to confirm.

## Install

In Terminal, run:

```bash
go install github.com/Dangthrimble/scan2pdf/cmd/scan2pdf@latest
```

## Check that it worked

```bash
command -v scan2pdf
```

The command should print a path (often ending in `go/bin/…`).

Then try:

```bash
scan2pdf --version
```

If you see version text, the program is installed.

## If `command -v` prints nothing (PATH)

Go puts the program in a `bin` folder that your computer may not search yet.

1. Show the folder:

   ```bash
   go env GOBIN
   go env GOPATH
   ```

   Use `GOBIN` if it printed a path; otherwise use `GOPATH` plus `/bin` (example: `/Users/you/go/bin`).

2. **zsh** (default on Mac) — add this line to `~/.zshrc`:

   ```bash
   export PATH="$(go env GOPATH)/bin:$PATH"
   ```

   If `go env GOBIN` printed a path, use that instead of `$(go env GOPATH)/bin`.

3. Save the file. Open a **new** Terminal window (or run `source ~/.zshrc`).

4. Run `command -v scan2pdf` again.

**bash:** put the same `export PATH=…` line in `~/.bashrc` or `~/.bash_profile`.

**Windows:** add the folder from `go env GOPATH` + `\bin` (or `GOBIN`) to your user Path under Environment Variables, open a new Command Prompt, and run `where scan2pdf`.

## Update

1. Upgrade Git if needed (see **Git**).
2. Update Go if needed (see **Go**).
3. If you keep a local copy of the project, run `git pull` (see **This project’s files**).
4. Re-run the same `go install …@latest` command as in **Install**.
5. Run `command -v scan2pdf` again.

## Quick start

With files such as `Sample p01.png`, `Sample p02.jpg`, etc. in the current directory:

```sh
scan2pdf "Sample.pdf"
```

The input prefix defaults to the output PDF basename, so the command above looks for supported files named `Sample pNN.<ext>`.

To use a different output filename:

```sh
scan2pdf --prefix "Sample" "Sample Print.pdf"
```

## Input filenames

Use one image file per final PDF page:

```text
Sample p01.png
Sample p02.jpg
Sample p03.tif
...
```

The `p` prefix is required. Page numbers are sorted numerically, so `p2` correctly comes before `p10`; zero-padding (`p01`, `p02`, ...) is still recommended because it also sorts naturally in Finder and Explorer.

If an original scan contains two facing pages, split it into two image files before running `scan2pdf`.

## Supported image formats

The following input formats are supported:

- **PNG** (`.png`) — recommended for most scanned pages because it is lossless.
- **JPEG** (`.jpg`, `.jpeg`) — useful for scanner/camera output, though lossy compression can soften fine detail.
- **TIFF** (`.tif`, `.tiff`) — useful for archival and scanning workflows. Standard single-page TIFF is supported.
- **BMP** (`.bmp`) — supported for compatibility, particularly with Windows-based workflows.
- **JPEG 2000** (`.jp2`, `.j2k`, `.j2c`, `.jpc`) — JP2 containers and raw codestreams; decoded and then stored in the PDF like other formats.

Formats can be mixed within the same scan set:

```text
Sample p01.png
Sample p02.jpg
Sample p03.tif
Sample p04.bmp
Sample p05.jp2
```

The page number, not the image extension, determines ordering. A duplicate page number is an error even if the two files use different formats.

The program deliberately follows a **one image file = one PDF page** rule. Multi-page TIFF files are rejected with an explanatory error; split them into separate `pNN` files first. BigTIFF is not supported.

## Defaults

- PDF page size: **A4 portrait** (`210 x 297 mm`)
- Minimum margin: **12.7 mm (0.5 inch)** on all sides
- Horizontal alignment: **centred**
- Vertical alignment: **top**
- White-trim threshold: **242/255** per RGB channel
- Lossless size optimisation: **off**

Each cropped image is enlarged as much as possible inside the available page area while preserving its aspect ratio. The raster image itself is not resampled; the PDF scales it at display/print time.

Because aspect ratio is preserved, one pair of margins may be larger than the specified minimum margin.

## Vertical alignment

`--v-align` controls vertical placement within the margins. Top is the default because page numbers and headings are commonly near the top:

```sh
scan2pdf --v-align top "Sample.pdf"
```

Other options are:

```sh
scan2pdf --v-align middle "Sample.pdf"
scan2pdf --v-align bottom "Sample.pdf"
```

## Horizontal alignment

`--h-align` controls horizontal placement within the margins. Centre is the default (`center` is accepted as an alias):

```sh
scan2pdf --h-align centre "Sample.pdf"
scan2pdf --h-align left "Sample.pdf"
scan2pdf --h-align right "Sample.pdf"
```

Horizontal alignment only changes the result when the image is height-limited and there is spare width between the side margins.

## Page sizes

Named sizes:

```sh
scan2pdf --page A4 "Sample.pdf"
scan2pdf --page A3 "Sample.pdf"
scan2pdf --page A5 "Sample.pdf"
scan2pdf --page Letter "Sample.pdf"
scan2pdf --page Legal "Sample.pdf"
```

Custom sizes accept `mm`, `cm`, `in`, or `pt`:

```sh
scan2pdf --page 210x297mm "Sample.pdf"
scan2pdf --page 8.5x11in "Sample.pdf"
```

Swap the dimensions for landscape output, for example `297x210mm`.

## Margins

Set all four margins together:

```sh
scan2pdf --margin 15mm "Sample.pdf"
```

Or override individual margins:

```sh
scan2pdf \
  --margin 12.7mm \
  --margin-top 15mm \
  --margin-bottom 15mm \
  --margin-left 18mm \
  --margin-right 12mm \
  "Sample.pdf"
```

Individual margin options override the base `--margin` value.

## Mirrored margins for double-sided printing

For a conventionally left-bound document:

```sh
scan2pdf \
  --mirror-margins \
  --margin 12.7mm \
  --margin-inner 18mm \
  --margin-outer 12.7mm \
  "Sample.pdf"
```

With left binding:

- odd PDF pages: inner margin on the left, outer margin on the right
- even PDF pages: outer margin on the left, inner margin on the right

For right binding:

```sh
scan2pdf \
  --mirror-margins \
  --binding right \
  --margin-inner 18mm \
  --margin-outer 12.7mm \
  "Sample.pdf"
```

`--margin-left` and `--margin-right` are intentionally not allowed together with `--mirror-margins`; use `--margin-inner` and `--margin-outer` instead.

## Trimming

The program trims surrounding pixels that are sufficiently close to white. The default threshold is `242` on a 0-255 scale:

```sh
scan2pdf --trim-threshold 242 "Sample.pdf"
```

Increase the value to require pixels to be closer to pure white before they are trimmed; decrease it to treat more light-grey pixels as background.

If an input page contains scanner edges, shadows, neighbouring pages, or other dark material outside the content, crop those manually first. `scan2pdf` deliberately does not try to decide whether dark material is content or scanner noise.

## Other options

Use source images from another directory:

```sh
scan2pdf --input-dir ./pages "Sample.pdf"
```

By default, an existing output is never replaced, including one created by another process during conversion. Safe publication requires hard-link support (such as APFS, NTFS or ext4); unsupported filesystems fail with an error. For an exFAT/FAT destination, create the PDF on a supported local disk and then copy it.

Replace an existing PDF:

```sh
scan2pdf --force "Sample.pdf"
```

Show build information:

```sh
scan2pdf --version
```

Show all options:

```sh
scan2pdf -h
```

## Optional lossless PDF size optimisation

Normal conversion favours speed. Add `--optimise` when a smaller PDF is worth
extra processing time:

```sh
scan2pdf --optimise "Sample.pdf"
```

This tries reversible PNG-style row filters and, for pages whose pixels are
already exclusively black or white, packed one-bit storage. It selects the
smallest image object, including PDF decoding metadata, from these candidates
and the normal fast encoding. It does not threshold grey pixels, discard
colour, resample, or apply JPEG recompression. Trying several candidates took
about 2.3 to 2.9 times as long as normal conversion in the initial tests.

With `--optimise`, conversion still reports crop and placement for each page,
and finishes with the PDF size and elapsed time:

```text
Lossless size optimisation: enabled
p01  Sample p01.png                   crop 2400x3200  placed 184.6 x 246.1 mm
...
Created Sample.pdf (3.32 MB) in 21.2 seconds
```

Here, **lossless means identical to the previous scan2pdf output pixels**.
Existing trimming and compositing onto white still apply. The existing image
pipeline still converts 16-bit source samples to 8-bit; this change does not
provide archival preservation of 16-bit data, transparency, or colour profiles.
JPEG inputs are still decoded and compressed losslessly; direct embedding of
original JPEG streams is not part of this first optimisation pass.

Source images are read only. Existing output PDFs are protected unless
`--force` is used.

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

The comparison outputs include `legacy.pdf`, `lossless.pdf`, and
`comparison.json`. This developer verification needs Python and pypdf; the
scan2pdf executable remains standalone. CI also runs the comparison suite on
supported targets.

## For developers

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

## Licence

scan2pdf is licensed under the [MIT licence](LICENSE), copyright 2026 Dangthrimble.
Third-party components retain their own licences, reproduced separately in
`THIRD_PARTY_NOTICES.txt`.
