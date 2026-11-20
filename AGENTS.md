# Agent guidance

This file is the canonical cross-agent entry point for this repository. Read it
and the skills in `.agents/skills/` before changing code, documentation,
workflows, or release files. `CLAUDE.md` points here for tools that use that
filename.

## Repository facts

- Module: `github.com/Dangthrimble/scan2pdf`
- Command: `scan2pdf` (under `cmd/`)
- Product: turn a numbered set of scan-page images into a print-ready PDF.
- Minimum Go: see `go.mod`.

## Language

Use UK English spelling in documentation, code comments, commit messages, and
user-facing output. Examples:

- licence (noun), licensed (verb)
- colour, behaviour, centre, grey
- organise, initialise, recognise, standardise, normalise, serialise
- analyse, catalogue, defence, prioritise, summarise, optimise

Keep proper nouns, quoted third-party text, URLs, filenames, identifiers, and
external API names as they are. Do not rewrite quoted material to match this
rule. If a document already contains a US spelling in a direct quotation, leave
the quotation unchanged and use UK spelling around it.

## Shared conventions

- Keep `README.md` a short hub. Procedures belong in `docs/`.
- Required documentation: `docs/install-go.md`, `docs/usage.md`,
  `docs/developing.md`; root `INSTALL.md`, `BACKLOG.md`, and
  `DEVELOPMENT_HISTORY.md`.
- Run `gofmt -l .`, `go vet ./...`, and `go test ./...` before proposing a
  commit. Keep the checks in `.github/workflows/ci.yml` green.
- Follow the release and packaging rules in
  `.agents/skills/release-and-packaging/SKILL.md`.
- Use a branch for each change and squash-merge it into `main` after review.
- Do not commit, push, tag, or publish a release unless the maintainer has
  explicitly asked for that action.

## Skills

- `.agents/skills/repo-conventions/SKILL.md` — shared language, documentation,
  code, and git conventions.
- `.agents/skills/release-and-packaging/SKILL.md` — release and packaging rules.
- `.agents/skills/go-cli-install-docs/SKILL.md` — install documentation.
- `.agents/skills/readme-hub-docs/SKILL.md` — README and documentation structure.
- `.agents/skills/maintain-before-commit/SKILL.md` — pre-commit checks.
