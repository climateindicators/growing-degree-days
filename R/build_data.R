# Build tidy long-format data for the Growing Degree Days indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published Figure 1 CSV in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical
# output. Nothing here touches the network.
#
# INPUT SHAPE: EPA's public per-figure CSV download (five-line preamble,
# windows-1252), not an internal ERG workbook. Every column is held as
# character from read to write, so the source file's own precision survives
# byte for byte. Nothing here calls as.numeric() on a value that is written.
#
# TO UPDATE THE DATA: drop a replacement CSV into data-raw/ and rerun. The value
# column is matched by header string, so a renamed or reordered column stops the
# build rather than silently mismatching latitude, longitude, and value.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R", "utils", "epa_csv.R"))
source(file.path(root, "R", "utils", "write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Growing Degree Days",
  slug                    = "growing-degree-days",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-growing-degree-days/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/growing-degree-days_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# Column headers of the source file, asserted before anything is read out of it.
LAT_HEADER   <- "Latitude"
LON_HEADER   <- "Longitude"
VALUE_HEADER <- "Percent change in growing degree days"

# Bounding box of the contiguous 48 states, generous on every side. This is a
# sanity check on the coordinates, not a definition of the study area: EPA's own
# station set spans 26.10 to 48.97 north and -124.35 to -70.16 east.
LAT_BOUNDS <- c(24, 50)
LON_BOUNDS <- c(-125, -66)

# ---- Legend classes ----------------------------------------------------------
#
# EPA's published map draws each station as a symbol whose colour and size come
# from one of seven classes. `label` is transcribed from the legend of EPA's own
# figure image, including its descending "-10 to -20" phrasing:
# https://19january2025snapshot.epa.gov/system/files/styles/large/private/images/2024-06/growing-degree_figure1_2024.png
#
# Carrying the class as a column is what lets the site draw EPA's legend without
# re-deriving the bin edges there. `lower` is exclusive and `upper` inclusive,
# which makes the classes a partition of the real line; the build asserts below
# that no station sits exactly on an edge, so this choice never silently decides
# a borderline case. Order is EPA's legend order, most negative first, and it is
# an explicit vector rather than sort(unique(x)), which would be
# locale-dependent.
CHANGE_CLASSES <- tibble::tribble(
  ~class_key,          ~label,        ~lower, ~upper,
  "lt_neg_20",         "<-20",        -Inf,   -20,
  "neg_20_to_neg_10",  "-10 to -20",  -20,    -10,
  "neg_10_to_neg_1",   "-1 to -10",   -10,    -1,
  "neg_1_to_1",        "-1 to 1",     -1,     1,
  "pos_1_to_10",       "1 to 10",     1,      10,
  "pos_10_to_20",      "10 to 20",    10,     20,
  "gt_pos_20",         ">20",         20,     Inf
)

# ---- Figure 1: percent change in growing degree days by station --------------

f1_path <- file.path(raw_dir, "growing-degree-fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)
assert_headers(f1_raw, c(LAT_HEADER, LON_HEADER), VALUE_HEADER, "growing-degree-fig-1.csv")

# split_value_flag() is the guard that every surviving value parses as a number,
# so a stray word in the source stops the build instead of becoming a silent NA.
# This file publishes no suppression markers, so `flag` is empty throughout; the
# column is kept for schema consistency with the other indicators.
f1_split <- split_value_flag(f1_raw[[VALUE_HEADER]])

# The numeric vector below is used ONLY to classify and to assert. The written
# `value` column stays the source string, untouched: EPA publishes ten
# significant digits and a round trip through a double would rewrite them.
f1_numeric <- as.numeric(f1_split$value)

f1 <- tibble::tibble(
  latitude  = f1_raw[[LAT_HEADER]],
  longitude = f1_raw[[LON_HEADER]],
  # findInterval() over the class upper edges, left.open so the intervals are
  # (lower, upper] and match the convention documented on CHANGE_CLASSES. It
  # returns 0 for a value at or below the first edge, hence the + 1L.
  class_i   = findInterval(f1_numeric, CHANGE_CLASSES$upper, left.open = TRUE) + 1L
) |>
  dplyr::mutate(
    change_class_key   = CHANGE_CLASSES$class_key[class_i],
    change_class_label = CHANGE_CLASSES$label[class_i],
    measure            = "percent_change_in_growing_degree_days",
    unit               = f1_meta$units,
    value              = f1_split$value,
    flag               = f1_split$flag
  ) |>
  dplyr::select(latitude, longitude, change_class_key, change_class_label,
                measure, unit, value, flag)

# Row order is EPA's own file order, preserved rather than sorted. It is already
# deterministic, and re-sorting would discard the only ordering the source
# states.

# ---- Assertions --------------------------------------------------------------
#
# Structural invariants only: each of these must still hold after a legitimate
# data update. The actual counts and values are pinned in tests/test-data.R.

assert_conservation(f1_raw, VALUE_HEADER, nrow(f1), "figure 1")

lat_n <- as.numeric(f1$latitude)
lon_n <- as.numeric(f1$longitude)

stopifnot(
  "every station should carry a latitude, a longitude, and a value" =
    !anyNA(lat_n) && !anyNA(lon_n) && !anyNA(f1_numeric),
  "latitudes should fall inside the contiguous 48 states" =
    all(lat_n >= LAT_BOUNDS[1] & lat_n <= LAT_BOUNDS[2]),
  "longitudes should fall inside the contiguous 48 states" =
    all(lon_n >= LON_BOUNDS[1] & lon_n <= LON_BOUNDS[2]),
  "each station should appear once: no duplicate coordinate pair" =
    !any(duplicated(paste(f1$latitude, f1$longitude))),
  "every station should land in exactly one legend class" =
    !anyNA(f1$change_class_key) &&
    all(f1$change_class_key %in% CHANGE_CLASSES$class_key),
  # If a future value lands exactly on an edge, the lower-exclusive convention
  # above would decide it silently. Stop instead, and decide deliberately.
  "no value should sit exactly on a legend class edge" =
    !any(f1_numeric %in% c(-20, -10, -1, 1, 10, 20)),
  # EPA's file carries no suppression markers. If a future one does, the flag
  # column and the site's handling of it both need revisiting.
  "this indicator publishes no suppressed values" = all(f1$flag == "")
)

# ---- Write ------------------------------------------------------------------

write_csv_stable(f1, file.path(out_dir, "growing_degree_days_change_by_station.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# Class ranges written as prose for the dictionary, from the same table the
# classification uses, so the two cannot drift.
class_range <- function(i) {
  lo <- CHANGE_CLASSES$lower[i]
  up <- CHANGE_CLASSES$upper[i]
  if (is.infinite(lo)) sprintf("percent change at or below %g", up)
  else if (is.infinite(up)) sprintf("percent change above %g", lo)
  else sprintf("percent change above %g and at or below %g", lo, up)
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "growing_degree_days_change_by_station.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "growing-degree-fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns = list(
        col("latitude", "number", "Station latitude in decimal degrees north, verbatim from the source file"),
        col("longitude", "number", "Station longitude in decimal degrees east, verbatim from the source file. Negative throughout, the contiguous 48 states being west of the prime meridian."),
        col("change_class_key", "string", paste(
          "Machine-readable key of the legend class EPA's published map draws",
          "this station in. Added by this build; not a column in EPA's file.",
          "Class edges are exclusive at the lower end and inclusive at the",
          "upper end, and the build stops if any value sits exactly on an edge."
        )),
        col("change_class_label", "string", "Display label of that class, transcribed from the legend of EPA's published figure"),
        col("measure", "string", "What is measured"),
        col("unit", "string", "Unit of `value`"),
        col("value", "number", "Percent change in annual growing degree days between 1948 and 2023, verbatim from the source file"),
        col("flag", "string", "Empty for an ordinary observation; a disclosure marker otherwise. Empty throughout this file, which publishes no suppressed values.")
      ),
      series = lapply(seq_len(nrow(CHANGE_CLASSES)), function(i) {
        list(
          key   = CHANGE_CLASSES$class_key[i],
          label = CHANGE_CLASSES$label[i],
          note  = class_range(i)
        )
      }),
      note = paste(
        "One row per weather station, not per year: EPA's Figure 1 is a point",
        "map of change across the whole 1948 to 2023 period, so this file",
        "carries no year column and no time series. The `series` entries above",
        "are the seven classes of EPA's published legend, in EPA's own legend",
        "order, most negative first. A class can be empty in a given vintage;",
        "EPA draws all seven regardless, and a page reproducing the legend",
        "should do the same."
      )
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- file.path(out_dir, c("growing_degree_days_change_by_station.csv", "meta.yml"))
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-45s %6d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
cat(sprintf("\nStations: %d\n", nrow(f1)))
cat("Legend classes:\n")
for (i in seq_len(nrow(CHANGE_CLASSES))) {
  k <- CHANGE_CLASSES$class_key[i]
  cat(sprintf("  %-18s %-12s %3d stations\n", k, CHANGE_CLASSES$label[i], sum(f1$change_class_key == k)))
}
