---
name: go-cli-install-docs
description: >-
  Installs Go command-line tools with go install and writes README install/update
  docs for copy-paste users (Go, other dependencies, PATH, verification; Git and
  a project download only if they want the source). Use when building or
  installing Go CLIs under cmd/, revising install instructions, or when the user
  mentions go install, GOBIN, GOPATH/bin, PATH setup, Git install, Go
  install/update, dependencies, or cloning/updating the repository for a Go
  utility.
---

# Go CLI install (this repository)

## Policy

- Prefer **Go + `go install`** over release binaries or system package installs.
- Do not suggest unsigned downloads, Gatekeeper workarounds, or copying into
  `/usr/bin` with sudo.
- Audience: can copy-paste Terminal commands; explain PATH explicitly.
- Say up front, in plain English, that installing the command does **not**
  require downloading this project’s files. `go install …@latest` gets the
  program. Skip Git and the repository steps unless the reader wants a copy of
  the source.
- Docs order: that note → Go → other dependencies (only when one exists) →
  Install → Verify → PATH fix → Update → optional Git and repository (for
  people who want the source).
- Git and a local copy are not install prerequisites. Still document both, in
  non-technical plain English, as an optional later section (install and
  upgrade, inline or linked).
- The same plain-English rule applies to **Go** (install and update) and to **any
  other dependencies** required to install or update the command-line utilities.
  When a new dependency appears, add or link a non-technical install-and-update
  description for it before documenting the CLI install steps that need it.

## Discover the repo first

1. Read `go.mod` → module path + minimum Go version.
2. List packages under `cmd/` → executable names (directory names).
3. Find the public clone URL (`git remote get-url origin` or the hosting page).
4. Note every prerequisite needed to install or update the CLIs. Go is required.
   Git is only for downloading the project files, not for `go install …@latest`.
   Include any other dependencies that exist now or are added later.
5. Install/doc commands use:
   `go install <module>/cmd/<name>@latest`
   Do not clone just to install. For an existing local checkout:
   `go install ./cmd/<name>` from the module root.

If there is no `cmd/`, ask which main packages to install.

## Local install

1. Do not clone the repository just to install the command.
2. Ensure Go meets `go.mod` (`go version`); if not, follow the README’s plain-English
   Go install/update section or link, then open a new terminal.
3. Ensure any other documented dependencies are installed/updated the same way.
4. `go install` each `cmd/...` with the module path and `@latest` (no checkout).
5. Binaries: `$(go env GOBIN)` or `$(go env GOPATH)/bin`.
6. Verify: `command -v <name>` (Windows: `where <name>`).
7. If missing → PATH section in the template; new terminal; recheck.

## README updates

Fill [readme-install-template.md](readme-install-template.md) using this repo’s
module path, `cmd` names, Go version, clone URL, and dependency list.

Required doc pieces (each install **and** update path in non-technical plain
English, inline or linked), in this order:

1. **No project download** — first, before any steps: to install the command you
   do not need to download this project’s files. `go install …@latest` gets the
   program. Skip Git and the repository section unless you want a copy of the
   source.
2. **Go** — what Go is in one plain sentence; install the version from `go.mod`;
   how to update Go later; confirm with `go version` after a new terminal.
3. **Other dependencies** — for every extra tool or runtime needed to install or
   update the CLIs, the same install-and-update treatment. If there are none yet,
   omit the section; when one is added, document it before the CLI install steps.
4. **Install the CLIs** — `go install …@latest` with full module paths.
5. **Verify** — `command -v` / `where` and one example run.
6. **PATH fix** — if not found: print bin dir, exact zsh/bash (and short Windows) steps,
   new terminal, recheck.
7. **Update the CLIs** — re-run the same `go install …@latest` commands. Upgrade
   Go and any other install dependencies as needed. Upgrade Git or `git pull`
   only if a local copy of the source is kept.
8. **Git** (optional, after Update) — install and upgrade, only for people who
   want the project files.
9. **Repository** (optional, after Git) — first-time download/clone and later
   upgrade (`git pull`). Not required to install or update the command.

Official download pages may be linked; surrounding README text must stay plain English.
Do not lead with `go build` for end users.

## Out of scope

Release binaries, notarization, Homebrew bottles—unless the user explicitly
asks to add them.
