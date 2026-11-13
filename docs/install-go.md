# Install with Go

Back to [README](../README.md). Prefer a [release package](../INSTALL.md) if you do
not want to install Go.

If you only want the command-line program, you do **not** need to download this
project’s files. Skip **This project’s files (optional)** below. The **Install**
step uses `go install …@latest`, which fetches what it needs.

## Git

Git is a tool that downloads and updates project files on your computer.

- **Install:** get Git from [git-scm.com/downloads](https://git-scm.com/downloads) (choose the installer for your computer) and run it.
- **Upgrade:** download a newer installer from the same page and run it again, or use your computer’s usual update method.

Open a **new** Terminal window and check:

```bash
git --version
```

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
3. If you keep a local copy of the source, run `git pull` (see **This project’s files** below).
4. Re-run the same `go install …@latest` command as in **Install**.
5. Run `command -v scan2pdf` again.

Updating the project files on your computer does not replace step 4.

## This project’s files (repository) (optional)

Skip this section if you only want the command. You do not need these files to install or update the command.

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

This updates the source files on your computer. Updating the installed command is a separate step under **Update** above (re-run `go install`).
