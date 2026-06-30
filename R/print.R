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
    assets = names(x$assets),
    links = length(x$links)
  ))
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_item <- function(x, ...) {
  .print_header("STAC Item", x$id)
  .print_fields(list(
    collection = x$collection,
    bbox = x$bbox,
    datetime = x$properties$datetime,
    assets = names(x$assets),
    links = length(x$links)
  ))
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
