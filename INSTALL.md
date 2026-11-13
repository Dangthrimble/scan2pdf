# Installing scan2pdf from a release package

These packages contain a command-line executable. You do not need Go to run it.

## Download and extract

Prefer a numbered release from the repository’s
[Releases page](https://github.com/Dangthrimble/scan2pdf/releases).
Download the archive for your computer (for example `scan2pdf-macos-apple-silicon.zip`
or `scan2pdf-linux-x64.tar.gz`).

Extract the archive and keep the extracted folder together. It contains:

- the `scan2pdf` executable (`scan2pdf.exe` on Windows)
- [README.md](README.md)
- this guide
- the `docs/` guides
- `LICENSE`
- `THIRD_PARTY_NOTICES.txt`

## Run the program

Open a terminal, change to a folder that holds your scan images, and invoke the
executable by its full path (or add that folder to your PATH). For example:

```sh
/path/to/extracted/scan2pdf --version
/path/to/extracted/scan2pdf "Sample.pdf"
```

On Windows, use `scan2pdf.exe` the same way from Command Prompt or PowerShell.

Usage details are in [docs/usage.md](docs/usage.md). For install with Go instead,
see [docs/install-go.md](docs/install-go.md).
