#' @title Print STAC documents
#'
#' @name print_rstatic
#'
#' @description
#' Minimalist, `tibble`-inspired S3 print methods for rstatic STAC documents
#' and their child elements (`doc_link`, `doc_links`, and `doc_asset`). Output
#' is lightly styled with the \pkg{cli} package and degrades gracefully when a
#' terminal does not support colors.
#'
#' A curated set of fields is shown per document. `doc_collection` and
#' `doc_item` also summarize their spatial and temporal extent: the collection
#' prints the union `bbox` and `interval` of its extent, and the item prints its
#' `bbox` and a `datetime` that prefers a `start_datetime`/`end_datetime` range
#' when present. Both close with a dimmed, complete list of their field names,
#' so every accessible field is discoverable without overwhelming the summary.
#'
#' @param x   A STAC document or element: `doc_catalog`, `doc_collection`,
#'   `doc_item`, `doc_asset`, `doc_link`, `doc_links`, or `doc_geometry`.
#' @param n   Maximum number of entries to print for `doc_links`. Defaults to
#'   `10`.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly, `x`.
#'
#' @examples
#' print(new_catalog("c", "Catalog", "An example catalog"))
#' print(new_collection("col", "Collection", "An example collection"))
#' print(new_asset("data.tif", title = "Data"))
NULL

# ---- internal helpers -------------------------------------------------------
# These helpers define the single, shared print style used across the package
# (STAC documents and `rstatic_style` objects alike): an angle-bracket header
# `<type: subtitle>` followed by indented `label: value` rows, lightly styled
# with the cli package.

#' Print a styled header line, e.g. `<STAC Item: land-cover-2020>`
#'
#' The structural parts (brackets and type) are bold cyan; the identifier is
#' yellow, mirroring git's convention of colouring object ids/hashes yellow.
#' This keeps the palette to three restrained roles (cyan, yellow, grey).
#'
#' @keywords internal
#' @noRd
.print_header <- function(type, subtitle = NULL) {
  if (!is.null(subtitle) && nzchar(as.character(subtitle))) {
    cat(
      cli::style_bold(cli::col_cyan(paste0("<", type, ": "))),
      cli::col_yellow(as.character(subtitle)),
      cli::style_bold(cli::col_cyan(">")),
      "\n",
      sep = ""
    )
  } else {
    cat(cli::style_bold(cli::col_cyan(paste0("<", type, ">"))), "\n", sep = "")
  }
}

#' Format a field value into a single, compact line
#'
#' @keywords internal
#' @noRd
.print_value <- function(v) {
  if (is.list(v)) {
    v <- unlist(v, use.names = FALSE)
  }
  if (is.null(v) || length(v) == 0) {
    return("")
  }
  paste(format(v, trim = TRUE, scientific = FALSE), collapse = ", ")
}

#' Print `label: value` rows, dropping empty fields
#'
#' @keywords internal
#' @noRd
.print_fields <- function(fields) {
  keep <- !vapply(
    fields,
    function(v) is.null(v) || length(v) == 0 ||
      (length(v) == 1 && !is.list(v) && is.na(v)),
    logical(1)
  )
  fields <- fields[keep]
  if (length(fields) == 0) {
    return(invisible())
  }
  for (label in names(fields)) {
    cat(
      "  ", cli::col_silver(label), ": ",
      .print_value(fields[[label]]), "\n",
      sep = ""
    )
  }
  invisible()
}

#' Print the full, sorted list of a document's field names, de-emphasized
#'
#' Mirrors rstac's `field(s):` line so users can see every accessible field.
#' It is dimmed so it recedes below the curated `label: value` rows above.
#'
#' @keywords internal
#' @noRd
.print_field_names <- function(x) {
  nms <- names(x)
  if (length(nms) == 0) {
    return(invisible())
  }
  cat(
    cli::style_dim(paste0("  fields: ", paste(sort(nms), collapse = ", "))),
    "\n",
    sep = ""
  )
  invisible()
}

#' Format an interval `[start, end]` as `start / end`, using `..` for open ends
#'
#' Returns `NULL` when both ends are open, so the row is dropped.
#'
#' @keywords internal
#' @noRd
.format_interval <- function(start, end) {
  if (is.null(start) && is.null(end)) {
    return(NULL)
  }
  paste0(start %||% "..", " / ", end %||% "..")
}

#' Resolve an item's temporal summary, preferring a start/end range
#'
#' When `start_datetime` or `end_datetime` is present, the range is shown (and
#' takes precedence over `datetime`); otherwise the single `datetime` is used.
#'
#' @keywords internal
#' @noRd
.item_temporal <- function(properties) {
  if (is.null(properties)) {
    return(NULL)
  }
  start <- properties$start_datetime
  end <- properties$end_datetime
  if (!is.null(start) || !is.null(end)) {
    return(.format_interval(start, end))
  }
  properties$datetime
}

#' Union of a collection's spatial extent bounding boxes
#'
#' Returns the overall `c(xmin, ymin, xmax, ymax)` (or the 6-value form with a
#' vertical axis) spanning every bbox in `extent$spatial$bbox`, or `NULL` when
#' no usable bbox is present.
#'
#' @keywords internal
#' @noRd
.extent_bbox <- function(x) {
  bboxes <- x$extent$spatial$bbox
  if (length(bboxes) == 0) {
    return(NULL)
  }
  rows <- lapply(bboxes, function(b) {
    suppressWarnings(as.numeric(unlist(b, use.names = FALSE)))
  })
  len <- length(rows[[1]])
  rows <- rows[vapply(
    rows, function(r) length(r) == len && !all(is.na(r)), logical(1)
  )]
  if (length(rows) == 0 || len < 4) {
    return(NULL)
  }
  m <- do.call(rbind, rows)
  half <- len %/% 2
  c(
    apply(m[, seq_len(half), drop = FALSE], 2, min, na.rm = TRUE),
    apply(m[, half + seq_len(half), drop = FALSE], 2, max, na.rm = TRUE)
  )
}

#' Union of a collection's temporal extent intervals, as `start / end`
#'
#' Takes the earliest start and latest end across `extent$temporal$interval`
#' (RFC 3339 strings sort lexicographically). Returns `NULL` when fully open.
#'
#' @keywords internal
#' @noRd
.extent_interval <- function(x) {
  intervals <- x$extent$temporal$interval
  if (length(intervals) == 0) {
    return(NULL)
  }
  starts <- unlist(lapply(intervals, `[[`, 1L), use.names = FALSE)
  ends <- unlist(lapply(intervals, `[[`, 2L), use.names = FALSE)
  start <- if (length(starts)) min(starts, na.rm = TRUE) else NULL
  end <- if (length(ends)) max(ends, na.rm = TRUE) else NULL
  .format_interval(start, end)
}

# ---- documents --------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_catalog <- function(x, ...) {
  .print_header("STAC Catalog", x$id)
  .print_fields(list(
    title = x$title,
    description = x$description,
    links = length(x$links)
  ))
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_collection <- function(x, ...) {
  .print_header("STAC Collection", x$id)
  .print_fields(list(
    title = x$title,
    description = x$description,
    license = x$license,
    bbox = .extent_bbox(x),
    interval = .extent_interval(x),
    assets = names(x$assets),
    links = length(x$links)
  ))
  .print_field_names(x)
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_item <- function(x, ...) {
  .print_header("STAC Item", x$id)
  .print_fields(list(
    collection = x$collection,
    bbox = x$bbox,
    datetime = .item_temporal(x$properties),
    assets = names(x$assets),
    links = length(x$links)
  ))
  .print_field_names(x)
  invisible(x)
}

# ---- assets -----------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_asset <- function(x, ...) {
  .print_header("STAC Asset", x$title)
  .print_fields(list(
    href = x$href,
    type = x$type,
    roles = x$roles
  ))
  invisible(x)
}

# ---- geometry ---------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_geometry <- function(x, ...) {
  .print_header("GeoJSON Geometry", x$type)
  pts <- matrix(
    unlist(x$coordinates, use.names = FALSE),
    ncol = 2, byrow = TRUE
  )
  .print_fields(list(
    bbox = c(min(pts[, 1]), min(pts[, 2]), max(pts[, 1]), max(pts[, 2]))
  ))
  invisible(x)
}

# ---- links ------------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_link <- function(x, ...) {
  .print_header("STAC Link", x$rel)
  .print_fields(list(
    href = x$href,
    type = x$type,
    title = x$title
  ))
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_links <- function(x, n = 10, ...) {
  .print_header("STAC Links", sprintf("%d", length(x)))
  show <- utils::head(unclass(x), n)
  for (link in show) {
    rel <- link$rel %||% ""
    label <- link$title %||% link$href %||% ""
    cat("  ", cli::col_silver(rel), ": ", label, "\n", sep = "")
  }
  more <- length(x) - length(show)
  if (more > 0) {
    cat(cli::col_silver(sprintf("  ... and %d more\n", more)))
  }
  invisible(x)
}
