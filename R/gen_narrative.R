# Extract EPA's published prose for the Growing Degree Days indicator and write
# it to narrative.qmd.
#
#   Rscript R/gen_narrative.R
#
# One source document: the indicator page text in data-raw/ carries every
# section, the Figure 1 title, caption and source line, and the nine references.
# The technical documentation document contributes no prose this repo extracts,
# because the one figure is on EPA's published page; see data-raw/PROVENANCE.md.
#
# THIS DOCUMENT IS NOT AN ACCEPT-ALL RENDERING OF ITS OWN TRACKED CHANGES.
#
# R/utils/read_docx.R renders a docx as if every tracked change were accepted,
# which is what EPA's published page equals for every other indicator in this
# project. It is not what the published page equals here. This file carries two
# distinct rounds of revision:
#
#   2024-03-13 to 2024-05-23  the June 2024 data update, six authors. Accepted
#                             before EPA published, and present on the page.
#   2025-02-13                six deletions by one author, made AFTER the
#                             January 19, 2025 snapshot this project rebuilds.
#                             They are NOT on the published page.
#
# That second round deletes the closing sentence of Background (on Non-Hispanic
# Black and Non-Hispanic American Indian/Alaska Native populations having the
# highest rates of asthma), its citation marker, and reference 6 (Burbank et
# al., 2023). An accept-all rendering silently drops all three, leaving a page
# that is missing a sentence EPA published and a reference list numbered
# 1, 2, 3, 4, 5, 7, 8, 9.
#
# So this generator reads the document AS OF the snapshot date: revisions dated
# on or before it are accepted, revisions dated after it are rejected. That is
# implemented by wrapping the shared reader's document loader below, rather than
# by editing R/utils/read_docx.R, which is indicator-agnostic and identical
# across every indicator repository.
#
# Citations are typed superscript numbers against a typed, Bibliography-styled
# reference list. The numbers in the text are final display numbers, not raw
# Word ids needing remapping.
#
# The body also holds 13 w:endnoteReference marks from a superseded citation
# system, every one of them deleted in the 2024 round, and word/endnotes.xml
# still holds all 13 bodies. Never build this reference list from
# word/endnotes.xml: it would render 13 entries where the published page has 9,
# and every one of them empty.

root <- here::here()
source(file.path(root, "R", "utils", "read_docx.R"))
source(file.path(root, "R", "utils", "write_stable.R"))

raw_dir   <- file.path(root, "data-raw")
TEXT_DOCX <- file.path(raw_dir, "GDD_2024 updated May 2024.docx")
OUT_QMD   <- file.path(root, "narrative.qmd")

N_FIGURES <- 1L

# The January 19, 2025 snapshot of epa.gov is this project's canonical source.
# A revision stamped after it was never on the page being rebuilt.
SNAPSHOT_DATE <- "2025-01-19"

if (!file.exists(TEXT_DOCX)) {
  stop("Source document not found: ", basename(TEXT_DOCX), call. = FALSE)
}

# ---- Reading the document as of the snapshot date ----------------------------

#' Reject every tracked deletion stamped after `cutoff`, in place.
#'
#' Word marks a deletion by wrapping runs in `w:del` and renaming their `w:t` to
#' `w:delText`, and marks a deleted paragraph mark with `w:pPr/w:rPr/w:del`.
#' Rejecting one is the exact inverse: rename the text back, unwrap the runs,
#' and drop the paragraph-mark flag so the paragraph is not folded into the next.
#'
#' `w:delInstrText` is deliberately left alone. Nothing in read_docx.R selects
#' it, so a Zotero field code cannot leak back in through this path.
#'
#' @return the number of revisions rejected.
reject_revisions_after <- function(doc, cutoff) {
  dated_after <- function(nodes) {
    if (length(nodes) == 0L) return(nodes)
    d <- xml2::xml_attr(nodes, "date")
    if (anyNA(d)) {
      stop("Tracked revision with no date attribute; it cannot be placed ",
           "relative to the snapshot date.", call. = FALSE)
    }
    nodes[substr(d, 1L, 10L) > cutoff]
  }

  # Paragraph marks first: removing the flag is independent of the runs, and
  # doing it after the unwrap below would mean re-querying a mutated tree.
  marks <- dated_after(xml2::xml_find_all(doc, "//w:pPr/w:rPr/w:del", W_NS))
  for (m in marks) xml2::xml_remove(m)

  dels <- dated_after(xml2::xml_find_all(doc, "//w:del", W_NS))
  for (d in dels) {
    for (t in xml2::xml_find_all(d, ".//w:delText", W_NS)) {
      # Local name only: the node keeps its w namespace, so this is w:delText
      # becoming w:t, not a new unprefixed element.
      xml2::xml_set_name(t, "t")
    }
    # Unwrap: each child is re-inserted in order immediately before the wrapper,
    # then the wrapper goes. LEAF_XPATH in read_docx.R excludes anything with a
    # w:del ancestor, so the wrapper is the whole reason this text is invisible.
    for (kid in xml2::xml_children(d)) {
      xml2::xml_add_sibling(d, kid, .where = "before")
    }
    xml2::xml_remove(d)
  }

  length(marks) + length(dels)
}

# read_docx_paragraphs() calls docx_body_xml() by name at run time, so wrapping
# it here is what makes the whole shared reader render the as-of view. The
# alternative was to copy read_docx_paragraphs()' body into this file and change
# three lines of it, which would have left two renderings of the same document
# format to keep in step.
n_rejected <- 0L
docx_body_xml_accept_all <- docx_body_xml
docx_body_xml <- function(path) {
  doc <- docx_body_xml_accept_all(path)
  n_rejected <<- reject_revisions_after(doc, SNAPSHOT_DATE)
  doc
}

df  <- read_docx_paragraphs(TEXT_DOCX)
sec <- docx_sections(df)

# The "Indicator Notes" heading opens with a hard line break, so its paragraph
# text begins with a newline and the section would otherwise be keyed under
# "\nIndicator Notes". Three other paragraphs carry a trailing space from Word's
# own layout. Normalize both here so section lookup below is by the heading a
# reader would recognize.
names(sec) <- trimws(gsub("[[:space:]]+", " ", names(sec)))

tidy_md <- function(x) sub("[[:space:]]+$", "", x)

get <- function(rng) {
  tidy_md(paste(df$text_md[rng][!df$empty[rng]], collapse = "\n\n"))
}

subtitle <- df$text_plain[df$style == "Subtitle"][1]

kp_idx     <- sec[["Key Points"]]
key_points <- tidy_md(df$text_md[kp_idx][df$style[kp_idx] == "Bullet2" & !df$empty[kp_idx]])

background          <- get(sec[["Background"]])
about_the_indicator <- get(sec[["About the Indicator"]])
indicator_notes     <- get(sec[["Indicator Notes"]])
data_sources        <- get(sec[["Data Sources"]])

# ---- Figures -----------------------------------------------------------------
#
# Word placed the figure block inside the Key Points paragraph range, after the
# bullets, so it is selected by style within that range rather than by a
# position a future edit would shift. A figure starts at a Caption-styled
# paragraph that actually reads "Figure N. ...", which is what separates a title
# from any other Caption-styled text.

cap_idx  <- kp_idx[df$style[kp_idx] %in% c("Caption", "FigureCaption", "SourceText")]
is_title <- df$style[cap_idx] == "Caption" & grepl("^Figure\\s+[0-9]", df$text_plain[cap_idx])
title_at <- cap_idx[is_title]

stopifnot(
  "expected exactly 1 figure title paragraph (Figure 1)" =
    length(title_at) == N_FIGURES
)

figure_block <- function(n) {
  start <- title_at[n]
  end   <- if (n < length(title_at)) title_at[n + 1L] - 1L else max(cap_idx)
  rng   <- cap_idx[cap_idx >= start & cap_idx <= end]
  list(
    title = tidy_md(trimws(df$text_plain[start])),
    body  = tidy_md(df$text_md[rng[rng != start & !df$empty[rng]]])
  )
}

figures <- lapply(seq_len(N_FIGURES), figure_block)

stopifnot(
  "every figure block should carry a caption and a source line" =
    all(vapply(figures, function(f) length(f$body) >= 2L, logical(1))),
  "the figure title should be numbered 1" =
    identical(
      as.integer(sub("^Figure\\s+([0-9]+)\\..*$", "\\1",
                     vapply(figures, function(f) f$title, character(1)))),
      seq_len(N_FIGURES)
    )
)

# ---- References --------------------------------------------------------------

ref_idx <- sec[["References"]]
ref_idx <- ref_idx[df$style[ref_idx] == "Bibliography"]
ref_num <- as.integer(sub("^(\\d{1,2})\\..*$", "\\1", df$text_plain[ref_idx]))

# This is also the check that the snapshot-date reading above did its job: with
# the 2025 deletions accepted instead, entry 6 vanishes and this numbering runs
# 1, 2, 3, 4, 5, 7, 8, 9.
stopifnot(
  "reference numbers could not be parsed from the Bibliography paragraphs" =
    !anyNA(ref_num),
  "reference numbering is not 1..N with no gaps; check the snapshot-date reading above" =
    identical(ref_num, seq_along(ref_idx))
)

# Reference text is emitted inside a raw <li>, not interpreted as markdown, so
# the escapes md_escape() added would show as literal backslashes. Only the
# underscore escape occurs in this document, inside a CDC URL, and it is left in
# place: Quarto processes inline markdown inside a raw <li>, so "\_" renders as
# "_" while a bare "_" would open emphasis. Italics are left alone for the same
# reason, which is what italicizes the journal titles.
ref_text <- sub("^\\d{1,2}\\.\\s*", "", df$text_md[ref_idx])

# Body markers are already display numbers, so they need no remapping, only a
# link to the entry they name. The comma-joined shape is preserved for a marker
# citing more than one source in one spot, and a number with no matching entry
# stops the build rather than emitting a link that goes nowhere.
link_refs <- function(x) {
  m <- gregexpr("\\^[0-9,]+\\^", x)
  regmatches(x, m) <- lapply(regmatches(x, m), function(hits) {
    vapply(hits, function(h) {
      nums <- as.integer(strsplit(gsub("\\^", "", h), ",")[[1]])
      unknown <- setdiff(nums, ref_num)
      if (length(unknown)) {
        stop(
          "Reference marker ", h, " cites entry number(s) that do not exist: ",
          paste(unknown, collapse = ", "), call. = FALSE
        )
      }
      paste0("^", paste0("[", nums, "](#ref-", nums, ")", collapse = ","), "^")
    }, character(1))
  })
  x
}

# The mirror of the check inside link_refs(): that one catches a marker with no
# entry, this one catches an entry with no marker, which is what a lost
# superscript looks like.
prose <- c(background, about_the_indicator, key_points, indicator_notes,
           data_sources, unlist(lapply(figures, function(f) f$body)))
cited <- as.integer(unlist(strsplit(
  gsub("\\^", "", unlist(regmatches(prose, gregexpr("\\^[0-9,]+\\^", prose)))), ","
)))
stopifnot(
  "every reference should be cited somewhere in the prose; an uncited entry means a marker was lost" =
    all(ref_num %in% cited)
)

background          <- link_refs(background)
about_the_indicator <- link_refs(about_the_indicator)
key_points          <- link_refs(key_points)
indicator_notes     <- link_refs(indicator_notes)
data_sources        <- link_refs(data_sources)
figures <- lapply(figures, function(f) {
  f$body <- link_refs(f$body)
  f
})

references_html <- paste0(
  '<ol class="references">\n',
  paste0('  <li id="ref-', ref_num, '">', ref_text, "</li>", collapse = "\n"),
  "\n</ol>"
)

# ---- Write -------------------------------------------------------------------

figure_sections <- unlist(lapply(seq_along(figures), function(n) {
  c(
    paste0("## Figure ", n), "",
    paste0("**", figures[[n]]$title, "**"), "",
    paste(figures[[n]]$body, collapse = "\n\n"), ""
  )
}), use.names = FALSE)

out <- c(
  "---",
  'title: "Growing Degree Days"',
  paste0('subtitle: "', subtitle, '"'),
  "---",
  "",
  paste0("<!-- Generated by R/gen_narrative.R from ", basename(TEXT_DOCX), "."),
  "     Do not edit by hand: rerunning the generator overwrites this file. -->",
  "",
  "## Key Points", "",
  paste0("- ", key_points, collapse = "\n\n"), "",
  "## Background", "",
  background, "",
  "## About the Indicator", "",
  about_the_indicator, "",
  "## Indicator Notes", "",
  indicator_notes, "",
  "## Data Sources", "",
  data_sources, "",
  figure_sections,
  "## References", "",
  references_html, ""
)

write_lines_stable(out, OUT_QMD)
assert_clean_output(OUT_QMD)

cat("Wrote", basename(OUT_QMD), "-", length(out), "lines,",
    length(figures), "figure,", length(ref_idx), "references.\n")
cat("Rejected", n_rejected, "tracked revisions stamped after", SNAPSHOT_DATE, "\n")
