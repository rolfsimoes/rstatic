#' @title Read a STAC document from disk
#'
#' @name stac_read
#'
#' @description
#' Reads a STAC `Catalog`, `Collection`, or `Item` JSON file from disk and
#' returns it as an in-memory `doc_*` object. This is the only reader in the
#' package; together with [stac_save()] it forms the effectful boundary around
#' the pure constructors (`new_*`) and builders (`add_*`).
#'
#' When the file does not exist, `stac_read()` returns `default` if one is
#' supplied (e.g. a freshly built `new_catalog()`), otherwise it errors. This
#' supports the load-or-create pattern without ever writing to disk:
#'
#' ```r
#' catalog <- stac_read(
#'   file.path(root, "stac", "catalog.json"),
#'   default = new_catalog("my-catalog", "My Catalog", "...")
#' )
#' ```
#'
#' @param path    A `character` path to a STAC JSON file.
#' @param default An optional in-memory `doc_*` object returned when `path` does
#'   not exist. If `NULL` (the default), a missing file is an error.
#'
#' @return A `doc_catalog`, `doc_collection`, or `doc_item` object.
#'
#' @examples
#' dir <- tempfile("stac-")
#' cat <- new_catalog("c", "Catalog", "An example catalog")
#' stac_save(catalog = cat, root_dir = dir)
#'
#' # Read it back
#' path <- file.path(dir, "stac", "catalog.json")
#' stac_read(path)$id
#'
#' # Missing file with a default returns the default, without writing
#' stac_read(file.path(dir, "missing.json"),
#'           default = new_catalog("fallback", "Fallback", "..."))$id
#'
#' @export
stac_read <- function(path, default = NULL) {
  if (!file.exists(path)) {
    if (!is.null(default)) {
      return(default)
    }
    stop("STAC document not found at ", path, call. = FALSE)
  }
  doc <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  .as_rstac(doc)
}
