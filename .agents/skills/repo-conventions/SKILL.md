---
name: repo-conventions
description: >-
  Shared conventions for this repository: UK English, documentation structure,
  Go code and command-line behaviour, git workflow, and sibling-repository
  consistency. Use when writing documentation or code, adding files, or
  preparing a commit.
---

# Repository conventions

## Language

Use UK English spelling in documentation, code comments, commit messages, and
user-facing output:

- licence (noun), licensed (verb)
- colour, behaviour, centre, grey
- organise, initialise, recognise, standardise, normalise, serialise
- analyse, catalogue, defence, prioritise, summarise, optimise

Keep proper nouns, quoted third-party text, URLs, filenames, identifiers, and
external API names unchanged. Do not rewrite quoted material. When updating an
existing file, fix incidental US spellings in the text you are already editing;
do not make a spelling-only change across unrelated files unless the task asks
for it.

## Documentation

- `README.md` is a short hub: title, blurb, the "no download required" note,
  Install links, one Try it example, a Docs map, and Licence.
- Required guides: `docs/install-go.md`, `docs/usage.md`,
  `docs/developing.md`. Add topic guides only for a distinct domain concern.
- Every `docs/*.md` starts with `Back to [README](../README.md).`
- Root files: `INSTALL.md` (when release packages exist), `BACKLOG.md`, and
  `DEVELOPMENT_HISTORY.md`.
- Keep the README Install section to links; put procedures in the guides.

## Go code and CLI behaviour

- Format with `gofmt`. Run `go vet ./...` and `go test ./...`; keep the checks
  in `.github/workflows/ci.yml` green.
- Keep `internal/version` as the source of the version string. Release builds
  stamp it with `-ldflags -X .../internal/version.Version=<tag>`.
- `--version` prints one line: `<command> <version>`. A local build prints
  `dev`; a `go install` build prints the module version; a release prints its
  tag.
- Usage errors exit `2`; runtime failures exit `1`; success exits `0`.
- Support `--help`/`-h` and `--` to end flag parsing. Prefix error messages with
  the command name.
- Use `flag` (or a small shared helper) for arguments. Keep stdout for normal
  output and stderr for diagnostics.
- Put fixtures in `testdata/` (package-local where appropriate). Keep them
  small, synthetic, and licence-safe; describe them in `testdata/README.md`.

## Git and review

- Branch names: `standardise/<step>-<short-description>` for shared migration
  work, otherwise `<area>/<short-description>`.
- Use sentence-case commit subjects with a short imperative summary.
- Squash-merge into `main`; delete the branch after merge.
- Do not commit, push, tag, or publish a release unless the maintainer has
  explicitly asked for that action.

## Sibling repositories

This repository is one of `forscore-setlist`, `forscore-metadata`, and
`scan2pdf`. Shared files (`AGENTS.md`, `.agents/skills/`, CI shape, packaging
tool, `.gitattributes`, issue templates) are kept aligned across them. The
long-term source of truth is the `go-cli-template` repository. When changing a
shared file, make the same change in the template and the sibling repositories.
