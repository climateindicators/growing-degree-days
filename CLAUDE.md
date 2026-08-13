# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**This file is the only place project rules live.** Code comments explain the
specific line or block they sit above, why *this* header is asserted, why *this*
value is rounded, and nothing broader. If a comment would apply to more than one
file, it belongs here instead.

## Project Overview

This repository is the **data and narrative pipeline for a single EPA climate
indicator, Growing Degree Days**. It takes the raw source files EPA/ERG produced, in
`data-raw/`, and turns them into two products:

1. `data/` for tidy long-format CSVs plus `data/meta.yml`, a machine-readable
   data dictionary
2. `narrative.qmd` for EPA's own published prose, extracted from the source Word
   documents

Both are consumed by the website repository, `../climateindicators.us`
(published at [climateindicators.us](https://climateindicators.us)): `data/` is
fetched off `raw.githubusercontent.com` at render time, and the prose in
`narrative.qmd` was lifted into `indicators/growing-degree-days.qmd` there.

**This repository is not a website and draws no figures.** All chart code lives
in the site repository, in `R/growing-degree-days.R`. Nothing here should produce a plot, a
theme, a palette, or an htmlwidget, and nothing here should be rendered.

Source of the indicator, and the canonical reference for any wording question:
<https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-growing-degree-days/index.html>

## Common Commands

```sh
Rscript R/build_data.R      # data-raw/ -> data/*.csv + data/meta.yml
Rscript R/gen_narrative.R   # data-raw/*.docx -> narrative.qmd
Rscript tests/test-data.R   # regression checks on the generated data
```

On this machine `Rscript` is not on PATH. Use the full path:
`"C:\Program Files\R\R-4.5.3\bin\Rscript.exe"`.

There is no test runner and no `testthat`: each file under `tests/` is a
standalone script run with `Rscript` from the repository root, printing
PASS/FAIL lines and exiting non-zero on failure. To run one check, edit or
comment within that script; there is no selector.

`R/build_data.R` never touches the network. Rerunning it with unchanged inputs
must produce byte-identical output.

## Architecture

### Two pipelines, both one-way

**Data.** `data-raw/growing-degree-fig-1.csv`, which is EPA's public per-figure
CSV download and not an internal ERG workbook, goes to `R/build_data.R`, which
writes the tidy CSV and `data/meta.yml`. Because it is a published CSV, it is
read through `read_epa_csv()` with every column held as character, and nothing
in the build calls `as.numeric()`.

- **Figure 1**, percent change in annual growing degree days at 280 long-term
  NOAA weather stations in the contiguous 48 states, one row per station carrying
  latitude, longitude, and percent change, 1948 to 2023, percent change. On
  EPA's published page.

This indicator has one figure, and each row of it is a station rather than a
year. It is a point map of change over the whole period, not a time series, so
no output here carries a `year` column and no coverage check can look for one.

The technical documentation describes a Figure TD-1 (annual growing degree days
for five sample sites). EPA publishes no data file for it, so this repository
does not build it. Do not invent one.

`data/meta.yml` is generated, never hand-edited. It is what the site repository
reads for figure titles, data-source lines, web-update dates, units, and column
descriptions, so a caption on the website cannot drift from the build.

**Narrative.** The source Word documents in `data-raw/` go to
`R/gen_narrative.R`, which writes `narrative.qmd`.

`data-raw/GDD_2024 updated May 2024.docx` is the indicator page text and carries
everything the published page shows: title, subtitle, Background, About the
Indicator, Key Points, the Figure 1 block (caption, description, and
`Data source:` line), Indicator Notes, Data Sources, and References. It arrives
with tracked changes not yet accepted (52 deletions, 45 insertions), so the
published page equals the accept-all rendering that `read_docx.R` produces.

**This document's citations are typed, not Word endnotes.** It still contains 13
`w:endnoteReference` markers and a populated `word/endnotes.xml`, but every one
of them sits inside a `w:del`: the May 2024 update deleted the endnote apparatus
and replaced it with hand-typed superscript numbers plus a hand-typed
`Bibliography`-styled reference list. In the accepted rendering there are zero
live endnote markers and zero live endnote text, so `R/gen_narrative.R` builds
the reference list from the body's `Bibliography` paragraphs and never calls
`docx_endnotes()`. EPA's typed list runs 1, 2, 3, 4, 5, 7, 8, 9 with no 6, which
is EPA's own numbering after that edit and is reproduced as published, not
renumbered.

`data-raw/GDD TD_2024 updated May 2024- CLEAN.docx` is the technical
documentation, the Word source of the linked PDF. It is clean (no tracked
changes), cites author-date inline against its own References section, and has
no endnote markers at all. The page document already carries every figure block,
so this document supplies nothing the narrative lacks and is not read by the
generator. It is vendored as the citable source of the technical documentation.

**`narrative.qmd` is generated, not hand-edited.** Rerunning the generator
overwrites it. A wording problem is fixed in `R/gen_narrative.R`, or it is not a
wording problem but a deliberate editorial change, which belongs on the page in
the site repository. Wording that differs from EPA's docx is a bug here.

### `R/utils/` for shared, indicator-agnostic readers

- `read_docx.R` parses `word/document.xml` with `xml2` directly. Never
  `officer::docx_summary()`, which leaks deleted text. The published EPA page
  equals the accept-all-tracked-changes rendering of the docx, and this reader
  reproduces exactly that. Raw bytes go to `read_xml()` as a raw vector, never
  through `rawToChar()`, or every curly quote and en dash becomes mojibake.
  Also carries Word endnote markers through as `^rawid^` tokens.
- `write_stable.R` holds byte-stable CSV/YAML/lines writers plus
  `assert_clean_output()` and `file_sha256()`.
- `epa_csv.R` is the reader for EPA's public per-figure CSV downloads (five-line
  preamble, windows-1252), plus the generic `assert_headers()`,
  `assert_conservation()`, and `split_value_flag()` helpers. This indicator's
  one source file is exactly that kind of published CSV, so this reader is the
  build's entry point.

Endnote *display* numbering (the 1..N a reader sees) is derived in
`gen_narrative.R`, not in the shared reader: Word ids need not be contiguous or
start at 1, so numbering follows the order `w:endnoteReference` markers appear
in the body.

### Hard rules

- **`data-raw/` is immutable input.** Files there are reproduced unmodified and
  hashed in `data-raw/PROVENANCE.md`. To update the data, replace the source
  file and rerun the build.
- **Never record a local filesystem path.** A vendored file is identified in
  `PROVENANCE.md` by its sha256 and its own `raw.githubusercontent.com` URL,
  never by the folder it was copied from. The vendored copy is the citable
  artifact: public, permanent, and fetchable by anyone. The same applies in
  code, where every script resolves its inputs relative to `here::here()` and
  none accepts a path outside the repository.
- **Read source columns by their header cells, never by position.** A renamed or
  reordered column must stop the build rather than silently swap two series.
  Where a source lays out side-by-side blocks sharing generic headers, an
  explicit range plus a header assertion is the only defense.
- **Never re-derive a published number outside `R/build_data.R`.** If something
  downstream needs a value `data/` does not carry, add it to the build and
  regenerate, so it is tested and reproducible.
- **Generated output must be byte-identical across reruns and machines.** No
  timestamps in generated files (provenance is the source checksum), no
  locale-dependent sorting (order rows with `match()` against an explicit level
  vector), LF endings and UTF-8 without BOM.
- **Structural invariants belong in the build; value snapshots belong in the
  tests.** `R/build_data.R` asserts what should survive a data update.
  `tests/test-data.R` pins the actual numbers, so a legitimate data update fails
  loudly there and tells you exactly what changed.
- **No em dashes in prose.** Use commas, periods, parentheses, semicolons, or
  colons.

### Tests

`tests/` holds data-quality checks and nothing else: schema, coverage,
documented invariants, value snapshots, file hygiene (UTF-8/LF/no BOM), and
agreement between `data/meta.yml` and the CSVs it documents.

## What must never appear here

Each indicator was once a standalone Quarto website. That scaffolding is gone.
Do not add `_quarto.yml`, `css/`, `images/`, `404.qmd`, `index.qmd`, a
"Data & Downloads" page, `R/figures.R`, `R/_common.R`, or
`R/utils/pick_chart.R`. The figures live in the site repository. Do not
reintroduce a rendered page here.

## Rights

EPA text, captions, and data are U.S. Government works, not subject to domestic
copyright (17 U.S.C. 105). Code and the derived data schema are CC-BY-SA. This
is an independent project, not affiliated with or endorsed by EPA or
NOAA (National Oceanic and Atmospheric Administration). See `NOTICE.md` and `data-raw/PROVENANCE.md`.
