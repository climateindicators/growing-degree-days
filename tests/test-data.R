# Regression checks on the generated data files.
#
#   Rscript tests/test-data.R
#
# These are value snapshots, deliberately separate from R/build_data.R. The
# build asserts structural invariants that survive a data update (header match,
# conservation, coordinates inside the contiguous 48 states, no duplicate
# station, no value on a legend class edge); this file pins the actual numbers,
# so after an update it tells you exactly what changed instead of silently
# accepting it.
#
# When the data is legitimately updated, expect failures here and update the
# expectations after checking each one against the new source file. Several of
# the pins below are EPA's own published Key Points, so a failure there means
# either the data or EPA's prose moved, and narrative.qmd and data/ would no
# longer agree.

setwd(here::here())
source("R/utils/write_stable.R")
source("R/utils/epa_csv.R")

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

f1 <- rd("growing_degree_days_change_by_station.csv")
v  <- as.numeric(f1$value)

cat("\nFigure 1 (growing_degree_days_change_by_station.csv)\n")
check("280 rows, one per weather station", nrow(f1) == 280L)
check("columns as documented",
      identical(names(f1), c("latitude", "longitude", "change_class_key",
                             "change_class_label", "measure", "unit",
                             "value", "flag")))
check("one measure and one unit throughout",
      identical(unique(f1$measure), "percent_change_in_growing_degree_days") &&
        identical(unique(f1$unit), "percent change"))
check("no flags set (EPA publishes no suppressed values here)", all(f1$flag == ""))

cat("\nValues, as exact strings\n")
# Row order is EPA's own file order, so first and last pin that ordering as well
# as the values.
check("first row is 34.5686, -85.6064, 5.615602058",
      identical(unlist(f1[1L, c("latitude", "longitude", "value")], use.names = FALSE),
                c("34.5686", "-85.6064", "5.615602058")))
check("last row is 46.8997, -95.0669, 12.00104009",
      identical(unlist(f1[280L, c("latitude", "longitude", "value")], use.names = FALSE),
                c("46.8997", "-95.0669", "12.00104009")))
check("largest increase is 116.8068182, at 37.7494, -107.095 (Colorado)",
      identical(f1$value[which.max(v)], "116.8068182") &&
        identical(f1$latitude[which.max(v)], "37.7494"))
check("largest decrease is -10.91039598, at 40.4517, -99.3803 (Nebraska)",
      identical(f1$value[which.min(v)], "-10.91039598") &&
        identical(f1$latitude[which.min(v)], "40.4517"))

# The point of holding values as character: this compares data/ against
# data-raw/ byte for byte, which no numeric comparison could do.
src <- read_epa_csv(file.path("data-raw", "growing-degree-fig-1.csv"))
check("latitude is byte-identical to the source file", identical(src[[1]], f1$latitude))
check("longitude is byte-identical to the source file", identical(src[[2]], f1$longitude))
check("value is byte-identical to the source file", identical(src[[3]], f1$value))

# Each pin below is a number EPA states in words in narrative.qmd, recomputed
# from the data. A failure here means the data and EPA's prose have stopped
# agreeing, which is not the same as a build bug. See "The Key Points block ties
# the data to the prose" in CLAUDE.md before changing any expected number.
cat("\nEPA's published Key Points, reproduced from the data\n")
check("221 of 280 stations increased (EPA: 'increased at 221 of the 280')",
      sum(v > 0) == 221L)
check("59 stations decreased", sum(v < 0) == 59L)
check("50 stations increased by 20 percent or more (EPA: 'Fifty stations')",
      sum(v >= 20) == 50L)
check("mean change is 10.72 percent (EPA: 'an increase of about 10 percent')",
      round(mean(v), 2) == 10.72)

cat("\nLegend classes\n")
class_counts <- c(lt_neg_20 = 0L, neg_20_to_neg_10 = 2L, neg_10_to_neg_1 = 49L,
                  neg_1_to_1 = 15L, pos_1_to_10 = 93L, pos_10_to_20 = 71L,
                  gt_pos_20 = 50L)
for (k in names(class_counts)) {
  check(sprintf("%s holds %d stations", k, class_counts[[k]]),
        sum(f1$change_class_key == k) == class_counts[[k]])
}
check("the seven class counts sum to 280", sum(class_counts) == 280L)
check("'<-20' is empty in this vintage, and EPA still draws it in the legend",
      !any(f1$change_class_key == "lt_neg_20"))
check("every class key carries exactly one label",
      nrow(unique(f1[c("change_class_key", "change_class_label")])) ==
        length(unique(f1$change_class_key)))

cat("\nStation geometry\n")
lat <- as.numeric(f1$latitude)
lon <- as.numeric(f1$longitude)
check("latitudes span 26.1019 to 48.9672",
      identical(range(lat), c(26.1019, 48.9672)))
check("longitudes span -124.3539 to -70.1564",
      identical(range(lon), c(-124.3539, -70.1564)))
check("every longitude is west of the prime meridian", all(lon < 0))
check("no duplicate station coordinates",
      !any(duplicated(paste(f1$latitude, f1$longitude))))

cat("\nFile hygiene\n")
for (f in list.files("data", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

meta <- yaml::read_yaml("data/meta.yml")
check("meta.yml documents the one dataset", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))
check("meta.yml records the source file's sha256",
      identical(meta$datasets[[1]]$source_sha256,
                file_sha256(file.path("data-raw", "growing-degree-fig-1.csv"))))
check("meta.yml figure title matches the source preamble, en dash intact",
      identical(meta$datasets[[1]]$figure_title,
                read_epa_preamble(file.path("data-raw", "growing-degree-fig-1.csv"))$title))
for (ds in meta$datasets) {
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("meta.yml dictionary matches %s columns", ds$file),
        identical(cols, names(rd(ds$file))))
  check(sprintf("meta.yml row count matches %s", ds$file),
        ds$rows == nrow(rd(ds$file)))
  keys <- vapply(ds$series, function(x) x$key, character(1))
  labs <- vapply(ds$series, function(x) x$label, character(1))
  check("meta.yml series are EPA's seven legend classes, in legend order",
        identical(keys, names(class_counts)))
  check("meta.yml series labels are EPA's own legend text",
        identical(labs, c("<-20", "-10 to -20", "-1 to -10", "-1 to 1",
                          "1 to 10", "10 to 20", ">20")))
}

cat("\nnarrative.qmd\n")
check("narrative.qmd exists", file.exists("narrative.qmd"))
if (file.exists("narrative.qmd")) {
  nq <- readLines("narrative.qmd", warn = FALSE)
  check("narrative.qmd is UTF-8, LF, no BOM, no mojibake",
        tryCatch({ assert_clean_output("narrative.qmd"); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
  check("narrative.qmd has 9 numbered references",
        length(grep('<li id="ref-', nq, fixed = TRUE)) == 9L)
  # These three guard the snapshot-date reading in R/gen_narrative.R. Accepting
  # the 2025-02-13 revisions instead drops the sentence, its marker, and entry 6.
  check("reference 6 (Burbank et al.) is present, as EPA published it",
        any(grepl('<li id="ref-6">Burbank', nq, fixed = TRUE)))
  check("Background keeps its closing sentence on asthma rates",
        any(grepl("highest rates of asthma in the United States", nq, fixed = TRUE)))
  check("that sentence's marker resolves to reference 6",
        any(grepl("symptoms of hay fever.^[6](#ref-6)^", nq, fixed = TRUE)))
  check("every superscript is a resolved reference link",
        all(grepl("^\\^\\[[0-9]+\\]\\(#ref-[0-9]+\\)\\^$",
                  unlist(regmatches(nq, gregexpr("\\^[^^]*\\^", nq))))))
  # Text deleted in the 2024 round, which the published page does not carry.
  for (leak in c("Asthma capitals", "suffering from hay fever", "$56 billion",
                 "Thirty-nine", "ERG to format citation")) {
    check(sprintf("no leaked deleted text: %s", leak),
          !any(grepl(leak, nq, fixed = TRUE)))
  }
}

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
