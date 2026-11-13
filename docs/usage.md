# Using scan2pdf

Back to [README](../README.md).

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

Formats can be mixed within the same scan set:

```text
Sample p01.png
Sample p02.jpg
Sample p03.tif
Sample p04.bmp
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

Developer comparison tooling for `--optimise` is documented in
[Developing](developing.md).
