# Development history

| When | What |
|------|------|
| 2026-09-26 | Initial `score2pdf` implementation: validated image handling and release workflows. |
| 2026-09-27 | Added Linux x64/ARM64 builds, the MIT licence, native verification of all six packages, consistent packaged checksums, and the release-package install guide. |
| 2026-10-05 | Moved the command logic into `internal/geometry`, `internal/imageutil`, `internal/pages` and `internal/pdf`. |
| 2026-10-06 | Added opt-in `--optimise` lossless size reduction. |
| 2026-10-08 | Added the backlog and linked it from the README. |
| 2026-10-13 | Renamed the command to `scan2pdf`; added `--v-align` and `--h-align`. |
| 2026-11-09 | Documented `go install`, split the README into a hub, skipped push CI on version tags, and trialled then removed JPEG 2000 input. |
| 2026-11-12 | Clarified that a project download is optional for CLI-only installs. |
| 2026-11-13 | Added the install and packaging updates, the `maintain-before-commit` skill, and the nested-docs runtime unpack fix. |
| 2026-11-14 | `--version` reports the release tag only; v0.2.2 was tagged but its release run failed. |
| 2026-11-20 | Adopted the shared cross-agent guidance, UK English rule, and release and packaging conventions. |
| 2026-11-20 | Standardised CI with race tests, gofmt, vet, staticcheck, govulncheck, and a required `CI gate`; raised the minimum Go version to 1.26.11. |
| 2026-11-21 | Replaced the Python packager with the shared Go `cmd/buildpackage`, standardised versioned ZIP assets and checksums, and moved release publishing to a tag-validated workflow that reuses CI. |
| 2026-11-21 | `--version` now prints `scan2pdf <version>`; usage and flag errors exit `2`, `--help` exits `0`, and runtime failures remain exit `1`. |
| 2026-11-21 | Added the shared repository-settings script, Dependabot, issue and pull-request templates, and the security policy. |
| 2026-11-28 | Backported the template's generic `repository.json`-driven settings script with private-repository handling and automatic ruleset creation. |

## Design notes

- The tool is pure Go. JPEG, PNG, TIFF and BMP decoding and PDF writing are
  built into the executable; no external PDF or image tool is required at
  runtime.
- One image file is one PDF page. Multi-page TIFF and BigTIFF are rejected with
  an explanatory error.
- Input files are discovered as `<prefix> pNN.<ext>`, sorted numerically, and
  duplicate page numbers are rejected.
- Each page is trimmed using a white threshold, fitted proportionally inside the
  margins, and placed without resampling the raster image.
- Output is written to a temporary file in the destination folder and published
  with a hard link so an existing PDF is never replaced by accident unless
  `--force` is used.
- `--optimise` compares filtered and predictor candidates against the default
  encoding and keeps the default when it is smaller.
