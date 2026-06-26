#' @title Print STAC documents
#'
#' @name print_rstatic
#'
#' @description
#' Compact S3 print methods for rstatic STAC documents.
#'
#' @param x   A `doc_catalog`, `doc_collection`, or `doc_item` object.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly, `x`.
#'
#' @examples
#' print(new_catalog("c", "Catalog", "An example catalog"))
#' print(new_collection("col", "Collection", "An example collection"))
NULL

#' @rdname print_rstatic
#' @export
print.doc_catalog <- function(x, ...) {
  cat("<STAC Catalog>\n")
  cat("  id:    ", x$id %||% "", "\n", sep = "")
  cat("  title: ", x$title %||% "", "\n", sep = "")
  cat("  links: ", length(x$links), "\n", sep = "")
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_collection <- function(x, ...) {
  cat("<STAC Collection>\n")
  cat("  id:    ", x$id %||% "", "\n", sep = "")
  cat("  title: ", x$title %||% "", "\n", sep = "")
  cat("  links: ", length(x$links), "\n", sep = "")
  invisible(x)
}

#' @rdname print_rstatic
#' @export
print.doc_item <- function(x, ...) {
  cat("<STAC Item>\n")
  cat("  id:     ", x$id %||% "", "\n", sep = "")
  cat("  assets: ", length(x$assets), "\n", sep = "")
  cat("  links:  ", length(x$links), "\n", sep = "")
  invisible(x)
}
