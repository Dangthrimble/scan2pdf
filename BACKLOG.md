# Backlog

Outstanding work and unresolved questions for scan2pdf. Order does not imply
priority. Current usage is in [README.md](README.md).

## PDF and encoding

- Optionally embed original JPEG streams instead of decoding and re-encoding
  losslessly (called out under optional `--optimise` in the README).
- Preserve 16-bit samples, transparency and colour profiles through the
  pipeline. The current writer composites onto white and stores 8-bit samples.

## Input and product scope

- Multi-page TIFF and BigTIFF remain out of scope unless separately designed;
  one image file equals one PDF page.
- Automatic removal of dark scanner edges, shadows or neighbouring pages stays
  out of scope; crop those manually before conversion.
