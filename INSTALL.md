# Installing scan2pdf from a release package

These packages contain a command-line executable. You do not need Go to run it.

## Download and extract

Prefer a numbered release from the repository’s
[Releases page](https://github.com/Dangthrimble/scan2pdf/releases).
Download the archive for your computer, for example
`scan2pdf-v0.2.3-macos-apple-silicon.zip` or `scan2pdf-v0.2.3-linux-x64.zip`.

Extract the archive and keep the extracted folder together. It contains:

- the `scan2pdf` executable (`scan2pdf.exe` on Windows)
- [README.md](README.md)
- this guide
- the `docs/` guides
- `BACKLOG.md` and `DEVELOPMENT_HISTORY.md`
- `LICENSE`, `THIRD_PARTY_NOTICES.txt` and `THIRD_PARTY_LICENSES/`
- `VERSION.txt` and `SHA256SUMS.txt`

## Check the download

Each archive has a `.zip.sha256` file, and the release provides a combined
`SHA256SUMS.txt`. Compare the checksum before extracting:

```sh
shasum -a 256 scan2pdf-v0.2.3-macos-apple-silicon.zip
```

On Linux, use `sha256sum` with the downloaded filename. In PowerShell, use:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath 'scan2pdf-v0.2.3-windows-x64.zip'
```

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
