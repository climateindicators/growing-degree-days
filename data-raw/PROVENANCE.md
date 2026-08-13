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

| File | sha256 | Raw URL |
|---|---|---|
| `growing-degree-fig-1.csv` | `3ea32327c9e82623cb3512c052bc8cff8b6e81d5eaa4cbe1ce51eae3a292e46b` | <https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/growing-degree-fig-1.csv> |

### What this file is

It is **EPA's public per-figure CSV download**, taken from the link on the
indicator page itself, not an internal ERG workbook. That decides how
`R/build_data.R` reads it: through `read_epa_csv()` and `read_epa_preamble()` in
`R/utils/epa_csv.R`, with every column held as character. EPA publishes it at:

| File | EPA URL |
|---|---|
| `growing-degree-fig-1.csv` | <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/growing-degree-fig-1.csv> |

The vendored copy is byte-identical to that download: 8,788 bytes, sha256
`3ea32327...a292e46b`, verified by fetching the URL and hashing the result
against the file above.

It carries EPA's standard five-line preamble (figure title, `Source:`,
`Data source:`, `Web update:`, `Units:`), a blank line, then the column header on
line 7. The file is **windows-1252 with CRLF line endings**, which is how EPA
published it. It contains one non-ASCII byte, a `0x96` at offset 74, the
windows-1252 en dash in `1948-2023` in its title, which is why the reader
converts explicitly with `iconv()` rather than tagging an encoding.
`.gitattributes` marks `data-raw/**` as `-text` so git's LF normalization cannot
rewrite these bytes and invalidate the checksum above. Without that pin the
committed blob is 8,501 bytes, 287 CR bytes short of the file this table
describes.

### What the build reads

Every column of the file is read; none is present but unread. There are no
sheets: this is a flat CSV, not a workbook.

| Header cell (line 7) | Read as | Notes |
|---|---|---|
| `Latitude` | character | decimal degrees north, 26.1019 to 48.9672 |
| `Longitude` | character | decimal degrees east (all negative here), -124.3539 to -70.1564 |
| `Percent change in growing degree days` | character | -10.9104 to 116.8068 |

280 data rows, one per weather station, with no duplicate coordinate pair and no
blank cell anywhere. **Each row is a station, not a year.** The figure is a point
map of change across the whole 1948 to 2023 period, so the file carries no year
column and no time series.

The preamble lines are read as metadata, not dropped: `data_source`,
`web_update`, and `unit` in `data/meta.yml` come from `read_epa_preamble()`
rather than being typed by hand.

Three counts in the file reproduce EPA's own Key Points exactly, which is what
`R/build_data.R` asserts and `tests/test-data.R` pins: 221 of the 280 stations
show an increase, 50 show an increase of 20 percent or more, and the mean change
across all stations is 10.72 percent, EPA's "about 10 percent".

### Figures not on EPA's published page

None. The one figure built here is EPA's Figure 1, under EPA's own title.

The technical documentation describes a **Figure TD-1**, annual growing degree
days for five sample sites chosen to span the distribution of regression slopes.
EPA publishes no data file for it, so it is not vendored here and not built. If
a data file for it ever surfaces, whatever presents it must say outright that it
is technical documentation material and not part of the published indicator, the
way `cold-related-deaths` Figure TD-1 does.

## Source documents for the prose

The indicator prose is extracted from these Word files, reproduced here
unmodified:

| File | sha256 | Raw URL |
|---|---|---|
| `GDD_2024 updated May 2024.docx` | `92959da8bf3f91cb251457521dee74b67619b45b5e621040cdd7275aec3ef08c` | <https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/GDD_2024%20updated%20May%202024.docx> |
| `GDD TD_2024 updated May 2024- CLEAN.docx` | `cd3041b43cf16ce1b303dc465e2175cbedd76c95fabe05c538d34c3494e35fb5` | <https://raw.githubusercontent.com/climateindicators/growing-degree-days/main/data-raw/GDD%20TD_2024%20updated%20May%202024-%20CLEAN.docx> |

They are vendored so the extraction is reproducible from this repository alone:
`R/gen_narrative.R` reads them out of `data-raw/` and writes `narrative.qmd`,
which is a generated artifact, not a hand-edited one. The generator resolves its
inputs relative to the repository root and never takes a path outside it.

Note that Word documents of this kind routinely carry tracked-change and
reviewer metadata that is not part of the published page.
`R/utils/read_docx.R` reproduces the accept-all-tracked-changes rendering and
never opens `comments.xml`.

### What each document contributes

`GDD_2024 updated May 2024.docx` is the **indicator page text**, and it carries
everything the published page shows: the title and subtitle, Background, About
the Indicator, Key Points, the Figure 1 block (caption, map description, and
`Data source:` line), Indicator Notes, Data Sources, and References. It arrives
with tracked changes not yet accepted, 52 deletions and 45 insertions, so the
published page equals the accept-all rendering this repository's reader produces.
It also ships `word/comments.xml`, `word/people.xml`, and
`word/commentsExtended.xml`, none of which the reader opens.

`GDD TD_2024 updated May 2024- CLEAN.docx` is the **technical documentation**,
the Word source of the PDF linked above. It carries the Identification, Revision
History, Data Sources, Data Availability, Methodology, and Analysis sections,
including the three station-selection criteria, the 50°F baseline justification,
and the Sen's slope and Mann-Kendall trend analysis. Its Revision History records
`April 2021: Indicator published.` and `June 2024: Indicator updated with data
through 2023.`, which corroborates the `Web update: June 2024` line in the CSV
preamble. As its filename says, it is clean: zero tracked insertions and zero
tracked deletions.

Because the page document already carries the figure title, caption, and source
line, the technical documentation document supplies nothing the narrative is
missing. It is vendored as the citable source of the technical documentation
and, as of this scaffold, is not read by `R/gen_narrative.R`. Update this
paragraph if that changes.

### How each document cites sources

`GDD_2024 updated May 2024.docx` cites with **hand-typed superscript numbers
against a hand-typed reference list**, not with Word endnotes. This needs saying
plainly, because the file looks like the opposite at first glance: it still
contains 13 `w:endnoteReference` markers and a 47 KB `word/endnotes.xml`. Every
one of those markers sits inside a `w:del`, and every endnote body is
`w:delText`. In the accept-all rendering there are **zero live endnote markers
and zero live endnote characters**. The May 2024 update deleted the whole Word
endnote apparatus and replaced it with typed superscripts plus a list of
`Bibliography`-styled paragraphs at the end of the body. So
`R/gen_narrative.R` builds the reference list from those paragraphs and never
calls `docx_endnotes()`; calling it would return 13 empty rows.

EPA's typed list runs 1, 2, 3, 4, 5, 7, 8, 9, with no 6. The deleted endnote that
held position 6 was an Asthma and Allergy Foundation of America citation, and one
other deleted note read `[ERG to format citation]`. The published numbering was
never closed up after that edit. It is reproduced exactly as published and is not
renumbered here.

`GDD TD_2024 updated May 2024- CLEAN.docx` uses **author-date citations typed
inline** (`Zhang et al., 2015`, `Lo et al., 2019`, `Kunkel et al., 2005`) against
a References section. It contains no `w:endnoteReference` markers at all, so
nothing there feeds an endnote-derived reference list.

The checksums above identify the exact revisions used.

## Precision

Values are preserved as source text byte for byte. `R/utils/epa_csv.R` reads
every column as character and nothing in the build calls `as.numeric()`, so the
source file's own precision survives into `data/` unchanged. That guarantee is
load-bearing here rather than decorative: EPA publishes the percent changes to
ten significant digits, such as `5.615602058` and `116.8068182`, and publishes
coordinates with trailing zeros already stripped, so 8 latitudes and 9 longitudes
carry two decimal places, 5 and 10 carry three, and the rest carry four. Any
round trip through a double, or any uniform rounding rule, would rewrite digits
EPA chose to publish.

## Updating the data

Replace the source file in this folder and rerun `R/build_data.R`. The build
reads its inputs by header cell, not by column position, so a renamed or
reordered column stops the build with a clear error instead of silently
mismatching a series. Update the table above with the new sha256.
