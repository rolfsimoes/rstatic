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
#'   `doc_item`, `doc_asset`, `doc_link`, or `doc_links`.
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

#' Print a styled header line, e.g. `# STAC Item land-cover-2020`
#'
#' @keywords internal
#' @noRd
.stac_header <- function(type, subtitle = NULL) {
  cat(cli::style_bold(cli::col_cyan(paste0("# STAC ", type))))
  if (!is.null(subtitle) && nzchar(as.character(subtitle))) {
    cat(" ", cli::col_silver(as.character(subtitle)), sep = "")
  }
  cat("\n")
}

#' Format a field value into a single, compact line
#'
#' @keywords internal
#' @noRd
.stac_value <- function(v) {
  if (is.list(v)) {
    v <- unlist(v, use.names = FALSE)
  }
  if (is.null(v) || length(v) == 0) {
    return("")
  }
  paste(format(v, trim = TRUE, scientific = FALSE), collapse = ", ")
}

#' Print aligned `label  value` rows, dropping empty fields
#'
#' @keywords internal
#' @noRd
.stac_fields <- function(fields) {
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
  labels <- names(fields)
  width <- max(nchar(labels))
  for (label in labels) {
    cat(
      "  ", cli::col_silver(formatC(label, width = -width)), "  ",
      .stac_value(fields[[label]]), "\n",
      sep = ""
    )
  }
  invisible()
}

# ---- documents --------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_catalog <- function(x, ...) {
  .stac_header("Catalog", x$id)
  .stac_fields(list(
    title = x$title,
    description = x$description,
    links = length(x$links)
  ))
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_collection <- function(x, ...) {
  .stac_header("Collection", x$id)
  .stac_fields(list(
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
  .stac_header("Item", x$id)
  .stac_fields(list(
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
  .stac_header("Asset", x$title)
  .stac_fields(list(
    href = x$href,
    type = x$type,
    roles = x$roles
  ))
  invisible(x)
}

# ---- links ------------------------------------------------------------------

#' @rdname print_rstatic
#' @export
print.doc_link <- function(x, ...) {
  .stac_header("Link", x$rel)
  .stac_fields(list(
    href = x$href,
    type = x$type,
    title = x$title
  ))
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_links <- function(x, n = 10, ...) {
  .stac_header("Links", sprintf("(%d)", length(x)))
  show <- utils::head(unclass(x), n)
  rels <- vapply(show, function(l) l$rel %||% "", character(1))
  width <- if (length(rels) > 0) max(nchar(rels)) else 0
  for (link in show) {
    rel <- formatC(link$rel %||% "", width = -width)
    label <- link$title %||% link$href %||% ""
    cat("  ", cli::col_silver(rel), "  ", label, "\n", sep = "")
  }
  more <- length(x) - length(show)
  if (more > 0) {
    cat(cli::col_silver(sprintf("  ... and %d more\n", more)))
  }
  invisible(x)
}
