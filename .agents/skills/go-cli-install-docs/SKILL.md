---
name: go-cli-install-docs
description: >-
  Installs Go command-line tools with go install and writes install/update docs
  for copy-paste users (Git, repository, Go, other dependencies, PATH,
  verification). Prefer a short README hub plus docs/install-go.md (or equivalent
  linked guide). Use when building or installing Go CLIs under cmd/, revising
  install instructions, or when the user mentions go install, GOBIN, GOPATH/bin,
  PATH setup, Git install, Go install/update, dependencies, or cloning/updating
  the repository for a Go utility.
---

# Go CLI install (this repository)

## Policy

- Prefer **Go + `go install`** over release binaries or system package installs.
- Do not suggest unsigned downloads, Gatekeeper workarounds, or copying into
  `/usr/bin` with sudo.
- Audience: can copy-paste Terminal commands; explain PATH explicitly.
- Docs: README must start with a plain-English upfront note that downloading
  this project’s files is **not** required to install the command-line tools.
  Keep the README as a short hub with install-path links. Put the full
  Git → Go → other dependencies → Install → Verify → PATH fix → Update flow in
  `docs/install-go.md` (or an equivalent linked guide). Document **Repository**
  separately as optional (local source copy only), after Update, in that guide.
- There needs to be a link to or description of how to install and upgrade Git
  and (for people who want a local copy) the repository. The description,
  whether included or linked to, needs to use non-technical plain English.
- The same plain-English rule applies to **Go** (install and update) and to **any
  other dependencies** required to install or update the command-line utilities.
  When a new dependency appears, add or link a non-technical install-and-update
  description for it before documenting the CLI install steps that need it.

## Discover the repo first

1. Read `go.mod` → module path + minimum Go version.
2. List packages under `cmd/` → executable names (directory names).
3. Find the public clone URL (`git remote get-url origin` or the hosting page).
4. Note every prerequisite needed to install or update the CLIs (Git, Go, and any
   others that exist now or are added later).
5. Install/doc commands use:
   `go install <module>/cmd/<name>@latest`
   For a local checkout: `go install ./cmd/<name>` from the module root.

If there is no `cmd/`, ask which main packages to install.

## Local install

1. Ensure Git is installed (`git --version`); if not, follow `docs/install-go.md`
   (or the README link to it).
2. Ensure Go meets `go.mod` (`go version`); if not, follow that guide’s Go
   install/update section, then open a new terminal.
3. Ensure any other documented dependencies are installed/updated the same way.
4. `go install` each `cmd/...` as above (`…@latest` does not require a local clone).
5. Binaries: `$(go env GOBIN)` or `$(go env GOPATH)/bin`.
6. Verify: `command -v <name>` (Windows: `where <name>`).
7. If missing → PATH section in the template; new terminal; recheck.
8. Optional: clone or update the repository only when a local source copy is needed
   (see the repository section in `docs/install-go.md`).

## Install doc updates

Keep a short README hub (upfront note + links to Go install and any ZIP install
guide). Fill [readme-install-template.md](readme-install-template.md) into
`docs/install-go.md` using this repo’s module path, `cmd` names, Go version,
clone URL, and dependency list.

Required doc pieces (each install **and** update path in non-technical plain
English, inline or linked):

1. **Upfront note** — install-only users do **not** need to download the project’s
   files; skip the repository section; `go install …@latest` fetches what it needs.
2. **Git** — install and upgrade.
3. **Go** — what Go is in one plain sentence; install the version from `go.mod`;
   how to update Go later; confirm with `go version` after a new terminal.
4. **Other dependencies** — for every extra tool or runtime needed to install or
   update the CLIs, the same install-and-update treatment. If there are none yet,
   omit the section; when one is added, document it before the CLI install steps.
5. **Install the CLIs** — `go install …@latest` with full module paths.
6. **Verify** — `command -v` / `where` and one example run.
7. **PATH fix** — if not found: print bin dir, exact zsh/bash (and short Windows) steps,
   new terminal, recheck.
8. **Update the CLIs** — upgrade Git/Go/other dependencies as needed, update the
   repo copy **only if used**, then re-run the same `go install …@latest` commands.
9. **Repository (optional)** — after Update: first-time download/clone and later
   upgrade (`git pull`) for people who want a local source copy. State clearly that
   this is optional for installing the commands.

Official download pages may be linked; surrounding install-guide text must stay
plain English. Do not lead with `go build` for end users.

## Out of scope

Release binaries, notarization, Homebrew bottles—unless the user explicitly
asks to add them.
