# growing-degree-days

Data and narrative for the U.S. EPA climate indicator **Growing Degree Days**.

This repository holds EPA's raw source files, the pipeline that turns them into
analysis-ready data, and EPA's own published prose extracted from the source
Word documents. It produces two things:

- `data/` for tidy long-format CSVs plus `meta.yml`, a machine-readable data
  dictionary
- `narrative.qmd` for EPA's indicator text, figure captions, and references

Both are read over the network by the website repository,
[climateindicators.us](https://github.com/climateindicators/climateindicators.us),
which is where the figures for this indicator are drawn. **No chart code lives
here.**

Part of the [climateindicators.us](https://climateindicators.us) project, which
rebuilds the EPA *Climate Change Indicators* preserved in the
[January 19, 2025 snapshot](https://19january2025snapshot.epa.gov/climate-indicators/view-indicators/index.html).

Original page: <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-growing-degree-days/index.html>

## Rebuilding

```sh
Rscript R/build_data.R      # data-raw/ -> data/*.csv + data/meta.yml
Rscript R/gen_narrative.R   # data-raw/*.docx -> narrative.qmd
Rscript tests/test-data.R   # data-quality checks
```

Nothing touches the network, and rerunning with unchanged inputs produces
byte-identical output.

## Figures

One, and it is on EPA's published indicator page. There is no supplementary or
technical documentation figure in this indicator.

| Figure | Content | Coverage |
|---|---|---|
| Figure 1 | Percent change in growing degree days at 280 long-term weather stations, mapped by latitude and longitude | 1948 to 2023 |

Each row is one station, not one year: the figure is a point map of change over
the full period, not a time series. See `data-raw/PROVENANCE.md`.

## Rights

EPA text and data are U.S. Government works, not subject to domestic copyright.
Code and the derived data schema are CC-BY-SA. See `NOTICE.md`.
