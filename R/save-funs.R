#' @title Save a STAC document to its canonical path
#'
#' @name stac_save
#'
#' @description
#' Writes a STAC `Catalog`, `Collection`, or `Item` to disk following the
#' canonical static catalog layout:
#' \itemize{
#'   \item `Catalog`    -> `stac/catalog.json`
#'   \item `Collection` -> `stac/collections/{id}/collection.json`
#'   \item `Item`       -> `stac/collections/{collection}/items/{id}/item.json`
#' }
#'
#' Items must carry a `collection` field so their path can be resolved.
#'
#' @param obj      A `doc_catalog`, `doc_collection`, or `doc_item` object.
#' @param root_dir A `character` directory under which the `stac/` tree is
#'   written. Defaults to the current working directory.
#'
#' @return Invisibly, the saved object (re-classed as an rstatic document).
#'
#' @examples
#' dir <- tempfile("stac-")
#' cat <- new_catalog("c", "Catalog", "An example catalog")
#' stac_save(cat, root_dir = dir)
#'
#' @export
stac_save <- function(obj, root_dir = ".") {
  if (inherits(obj, "doc_catalog")) {
    path <- file.path(root_dir, "stac", "catalog.json")
  } else if (inherits(obj, "doc_collection")) {
    path <- file.path(
      root_dir, "stac", "collections", obj$id, "collection.json"
    )
  } else if (inherits(obj, "doc_item")) {
    col_id <- obj$collection
    if (is.null(col_id)) {
      stop("Item object must have a 'collection' field to be saved.",
           call. = FALSE)
    }
    path <- file.path(
      root_dir, "stac", "collections", col_id, "items", obj$id, "item.json"
    )
  } else {
    stop("Unknown STAC object type. Must be Catalog, Collection, or Item.",
         call. = FALSE)
  }

  .write_json(obj, path)
  invisible(.as_rstac(obj))
}
