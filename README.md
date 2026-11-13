# scan2pdf

`scan2pdf` (formerly `score2pdf`) turns a numbered set of scan-page images into a print-ready PDF.
See the [backlog](BACKLOG.md) for outstanding work.

It is designed for a simple workflow: manually remove scanner/book-edge noise and correct any obvious rotation first, then let `scan2pdf` trim the remaining white border, fit each page proportionally onto a PDF page, and write the pages in numeric order.

The program is written in pure Go and has no runtime dependency on ImageMagick, Python, `img2pdf`, or any external PDF library. JPEG and PNG use Go's standard image decoders; TIFF and BMP use the pure-Go `golang.org/x/image` decoders, compiled into the executable.

If you only want the command-line program, you do **not** need to download this
project’s files. Choose an install path below; `go install …@latest` fetches
what it needs without a local copy of the repository.

## Install

Pick one:

- **With Go** (recommended for updates from source): follow
  [Install with Go](docs/install-go.md) — Git, Go, `go install`, PATH, and
  optional project files.
- **Without Go** (pre-built package): follow [INSTALL.md](INSTALL.md) — download a
  release package for your computer and run the executable.

## Try it

With files such as `Sample p01.png`, `Sample p02.jpg` in the current directory:

```sh
scan2pdf "Sample.pdf"
```

Full options, page geometry, and formats are in
[Using scan2pdf](docs/usage.md).

## Docs

- [Using scan2pdf](docs/usage.md) — quick start, filenames, formats, geometry, options
- [Install with Go](docs/install-go.md) — Git, Go, `go install`, PATH, update, optional clone
- [INSTALL.md](INSTALL.md) — install from a release package (no Go required)
- [Developing](docs/developing.md) — local builds, tests, CI and compression comparison
- [Backlog](BACKLOG.md) — outstanding work

## Licence

scan2pdf is licensed under the [MIT licence](LICENSE), copyright 2026 Dangthrimble.
Third-party components retain their own licences, reproduced separately in
`THIRD_PARTY_NOTICES.txt`.
