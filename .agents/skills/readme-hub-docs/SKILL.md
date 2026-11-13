---
name: readme-hub-docs
description: >-
  Keeps a short README hub plus docs/ guides for Go CLI repos (install-go,
  usage, developing, optional topic docs, optional root INSTALL.md for release
  ZIPs). Use when writing or updating README.md, docs/, INSTALL.md, packaging
  that ships docs, or when splitting a long README into hub-linked guides.
---

# README hub + docs/

## Contract

README is a **short hub**. Procedures live in linked guides. Look and feel stay
consistent across sibling Go CLI repos; content stays appropriate to each repo.

Required hub shape:

1. `#` title and short product blurb
2. Plain-English note that installing the CLI(s) does **not** require downloading
   this project’s files
3. `## Install` — path links only (no full procedures)
4. `## Try it` — one short example; link to usage for the rest
5. `## Docs` — link map to guides and root backlog/history when they exist
6. `## Licence` or `## License` — keep that repo’s existing spelling

## Required docs/

| Path | Role |
|------|------|
| `docs/install-go.md` | Full Git → Go → deps → Install → Verify → PATH → Update → optional repository. Owned with `go-cli-install-docs`. |
| `docs/usage.md` | Day-to-day CLI use (commands, flags, examples) |
| `docs/developing.md` | Local build/test/CI and other contributor notes |

Every `docs/*.md` starts with **Back to [README](../README.md)** and uses relative
links.

## Optional pieces

- **Topic docs** under `docs/` — only when the README already has a distinct
  domain section that is neither “how to run it” nor developer setup (example:
  filename/metadata rules). One concern per file. Do **not** invent a topic
  guide from `BACKLOG.md` or `DEVELOPMENT_HISTORY.md`.
- **`INSTALL.md` at repo root** — only when a pre-built release ZIP/tar path
  already exists. Link it from Install as the Without Go path. Never invent a
  ZIP path for a Go-only repo.
- Keep `BACKLOG.md` and `DEVELOPMENT_HISTORY.md` at the repo root; link them from
  the Docs map when present.

## Install section rules

- **With Go** → link `docs/install-go.md`.
- **Without Go** → link `INSTALL.md` only if that file exists for this repo.
- Go-only repos: a single Install link to `docs/install-go.md` is enough.

## Writing and updating

- **Move existing prose.** Do not rewrite procedures, command examples, or
  explanations when splitting or refreshing. Retitle sections to match this
  contract and fix links.
- Put install-procedure updates into `docs/install-go.md` via
  `go-cli-install-docs`. Do not re-inline the full install flow into README.
- After a split, fix in-repo links that still pointed at README sections that
  moved (backlog, related docs, packaging notes).

## Packaging

When a release packager ships documentation, include `README.md`, the `docs/`
tree, and `INSTALL.md` when present. Do not ship a hub-only README that leaves
ZIP users without the guides. Update packager and archive-member checks together.

## Sibling consistency

This skill file is identical across sibling repos. Repo-specific facts (module
path, command names, Go version, whether `INSTALL.md` exists, which topic docs
exist) live in each repo’s files and in that repo’s `go-cli-install-docs` skill.
`go-cli-install-docs` may differ per repo for those facts; its **policy** must
still target hub + `docs/install-go.md`.
