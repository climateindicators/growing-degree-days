# Provenance of raw inputs

Everything in this folder is a work of the U.S. Government prepared by EPA staff
as part of their official duties, and is therefore not subject to domestic
copyright (17 U.S.C. 105). It is reproduced here unmodified.

Indicator page (the canonical source, January 19 2025 snapshot):
<https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-growing-degree-days/index.html>

Technical documentation (PDF, not vendored here):
<https://19january2025snapshot.epa.gov/system/files/documents/2024-06/growing-degree-days_documentation.pdf>

## Files

Every vendored file is identified by its sha256 and by its own URL in this
repository. **Never record a path on someone's local machine.** The vendored
copy is the citable artifact: it is public, permanent, and fetchable by anyone,
which a local archive folder is not.

<!-- TODO: one row per vendored file. Full sha256, from file_sha256(). The raw
     URL is https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/<file>
     with spaces percent-encoded as %20. -->

| File | sha256 | Raw URL |
|---|---|---|
| `TODO` | `TODO` | <https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/TODO> |

<!-- TODO: describe what the vendored data file actually is. State plainly
     whether it is EPA's public per-figure CSV download or an internal ERG
     workbook, because that decides how R/build_data.R reads it and what
     precision guarantee applies. Where EPA also publishes the file at a stable
     URL, give that URL here. If a public CSV exists for a figure built here
     from a workbook, say whether the two were cross-checked and to what
     precision. -->

<!-- TODO: list which sheets or columns R/build_data.R actually reads, and name
     the ones present but unread, so nobody assumes the whole file is in use. -->

<!-- TODO: if any figure built here is NOT on EPA's published indicator page,
     this is where that is documented: what it is, where EPA published it
     instead, why it is built anyway, and the requirement that anything
     presenting it says so outright. -->

## Source documents for the prose

The indicator prose is extracted from these Word files, reproduced here
unmodified:

| File | sha256 | Raw URL |
|---|---|---|
| `TODO` | `TODO` | <https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/TODO> |

They are vendored so the extraction is reproducible from this repository alone:
`R/gen_narrative.R` reads them out of `data-raw/` and writes `narrative.qmd`,
which is a generated artifact, not a hand-edited one. The generator resolves its
inputs relative to the repository root and never takes a path outside it.

Note that Word documents of this kind routinely carry tracked-change and
reviewer metadata that is not part of the published page.
`R/utils/read_docx.R` reproduces the accept-all-tracked-changes rendering and
never opens `comments.xml`.

<!-- TODO: say what each document contributes (indicator page text, technical
     documentation), and how it cites sources: real Word endnotes
     (w:endnoteReference plus word/endnotes.xml), typed superscript numbers, or
     Zotero ADDIN fields. That decides how R/gen_narrative.R builds the
     reference list. -->

The checksums above identify the exact revisions used.

## Precision

<!-- TODO: keep whichever paragraph applies and delete the other. -->

*For a published EPA CSV:* values are preserved as source text byte for byte.
`R/utils/epa_csv.R` reads every column as character and nothing in the build
calls `as.numeric()`, so the source file's own precision survives into `data/`
unchanged.

*For a workbook read as doubles:* values are read as IEEE 754 doubles (via
`readxl`), not parsed from formatted text, so there is no source-file decimal
precision to preserve byte for byte. `R/build_data.R` rounds to N decimal
places: TODO justify N against the source's own stated precision, so nothing
meaningful is lost, and fixed so reruns are byte-identical.

## Updating the data

Replace the source file in this folder and rerun `R/build_data.R`. The build
reads its inputs by header cell, not by column position, so a renamed or
reordered column stops the build with a clear error instead of silently
mismatching a series. Update the table above with the new sha256.
