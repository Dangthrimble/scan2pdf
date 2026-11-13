# Install-with-Go guide skeleton (`docs/install-go.md`)

Fill `MODULE`, `CMD` (repeat per command), `MIN_GO`, and `CLONE_URL` from the repo.
Keep every section in non-technical plain English. Prefer short numbered steps and
copy-paste commands.

Use this content in `docs/install-go.md` (or an equivalent linked guide). The
README stays a short hub: upfront “no clone required” note, links to this guide
and any ZIP install path, then usage/docs map—not the full procedure below.

Start with the upfront note below. For **Git**, **Go**, and **any other dependency**
needed to install or update the CLIs: include a plain-English description **or** a
link to one that covers both install and update. If linking out, the link target
must suit non-technical readers; add a one-line summary beside the link.

Document **This project’s files (repository)** only as optional, **after Update**.

## Upfront note (required)

Before **Git**, say in plain English:

- If you only want the command-line program(s), you do **not** need to download
  this project’s files.
- Skip **This project’s files (optional)** below.
- The Install step uses `go install …@latest`, which fetches what it needs.

## Git (required)

- **Install Git** — what Git is in one sentence (“a tool that downloads and updates
  project files”), then how to get it on Mac / Windows / Linux (official downloads
  or the platform’s usual method).
- **Upgrade Git** — how to get a newer Git later (re-run the installer, or the
  platform’s upgrade steps).

Afterward: open a new Terminal and run `git --version` to confirm it worked.

## Go (required)

- **What it is** — one sentence (“Go is the programming toolkit used to download
  and install these command-line programs”).
- **Install** — get Go **MIN_GO** or newer from https://go.dev/dl/ (choose the
  installer for their computer). Run the installer; accept the defaults unless they
  know they need otherwise.
- **Check** — open a **new** Terminal window and run:

  ```bash
  go version
  ```

  You should see a version of MIN_GO or higher.
- **Update** — later, download a newer installer from the same page and run it
  again (or follow that page’s update steps), then open a new Terminal and run
  `go version` to confirm.

## Other dependencies (when needed)

For each extra tool or runtime required to install or update the CLIs (none yet
unless the project adds one):

- One-sentence plain-English what it is
- How to install it
- How to update it later
- How to check it worked

Place each dependency **before** the CLI **Install** section. When a new
dependency is introduced, add it here in the same style as Git and Go.

## Install

In Terminal, run (one line per command):

```bash
go install MODULE/cmd/CMD@latest
```

## Check that it worked

```bash
command -v CMD
```

Each command should print a path (often ending in `go/bin/…`).

Then try running `CMD` (usage text or a clear usage error means it is installed).

## If `command -v` prints nothing (PATH)

Go puts the programs in a `bin` folder that your computer may not search yet.

1. Show the folder:

   ```bash
   go env GOBIN
   go env GOPATH
   ```

   Use `GOBIN` if it is non-empty; otherwise use `GOPATH` + `/bin`
   (example: `/Users/you/go/bin`).

2. **zsh** (default on Mac) — add this line to `~/.zshrc`:

   ```bash
   export PATH="$(go env GOPATH)/bin:$PATH"
   ```

   If `go env GOBIN` printed a path, use that instead of `$(go env GOPATH)/bin`.

3. Save the file. Open a **new** Terminal window (or run `source ~/.zshrc`).

4. Run `command -v` again.

**bash:** same `export PATH=…` line in `~/.bashrc` or `~/.bash_profile`.

**Windows:** add the folder from `go env GOPATH` + `\bin` (or `GOBIN`) to your
user Path in Environment Variables, then open a new Command Prompt and run
`where CMD`.

## Update

1. Upgrade Git if needed (see Git section).
2. Update Go if needed (see Go section).
3. Update any other dependencies if needed (see Other dependencies).
4. Update the project files if you use a local copy (`git pull`, see repository section).
5. Re-run the same `go install …@latest` commands as in Install.
6. Run `command -v` again.

## This project’s files (repository) (optional)

Only for people who want a local copy of the project files. Not required to install
or update the command-line program(s).

- **Install (first time)** — download a full copy of the project, e.g.:

  ```bash
  git clone CLONE_URL
  cd REPO_DIR
  ```

  Say where the files will appear (a new folder on their computer).

- **Upgrade (later)** — get the latest project files:

  ```bash
  cd REPO_DIR
  git pull
  ```

Explain that this updates the source files; updating the installed commands is a
separate step under **Update** above (re-run `go install`).
