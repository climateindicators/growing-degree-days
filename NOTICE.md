# Rights and attribution

## EPA content

The indicator text, figure captions, and underlying data reproduced in this
repository are works of the U.S. Environmental Protection Agency, prepared by
officers or employees of the U.S. Government as part of their official duties.
Under 17 U.S.C. 105 such works are not subject to copyright protection in the
United States.

Source: *Climate Change Indicators in the United States: Growing Degree Days*,
U.S. EPA, as preserved in the January 19, 2025 snapshot of epa.gov.

<https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-growing-degree-days/index.html>

The underlying data are from NOAA (National Oceanic and Atmospheric Administration). See the indicator's technical
documentation for details:

<https://19january2025snapshot.epa.gov/system/files/documents/2024-06/growing-degree-days_documentation.pdf>

Files in `data-raw/` are reproduced unmodified. Files in `data/` are
reformatted, not altered. Values are preserved as source text byte for byte:
the input is EPA's published per-figure CSV, read as character throughout, so
no rounding rule is applied and no digit is added or lost. That matters here,
because EPA publishes the percent changes to ten significant digits and the
coordinates to four decimal places. See
`data-raw/PROVENANCE.md`. Every transformation is in `R/build_data.R` and is checked by
`tests/test-data.R`. `narrative.qmd` is EPA's published wording, extracted from
the Word documents in `data-raw/` by `R/gen_narrative.R`.

## This rebuild

Code and the derived data schema are licensed CC-BY-SA.

This is an independent project. It is **not** affiliated with, endorsed by, or
approved by the U.S. Environmental Protection Agency or NOAA (National Oceanic and Atmospheric Administration) (the
underlying data source agency).

This repository departs from EPA's published presentation in no way: it carries
EPA's one published figure and no others, EPA's own values unrounded, and EPA's
own wording as extracted from the source Word documents. It draws no figures.
Any presentational difference in the rebuilt map is a decision made in the
website repository and is documented on the page there.
