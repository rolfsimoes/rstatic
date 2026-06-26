#' @title Create and register STAC collections
#'
#' @name collection_functions
#'
#' @description
#' Functions to build and attach a STAC `Collection` document.
#'
#' \itemize{
#'   \item `new_collection()`: creates an in-memory `Collection` object.
#'   \item `stac_add_collection()`: persists a collection and registers it as
#'     a `child` of a catalog, then saves the updated catalog.
#' }
#'
#' @param id           A `character` identifier for the collection.
#' @param title        A `character` human-readable title.
#' @param description  A `character` description of the collection.
#' @param license      A `character` license identifier or URL.
#'   Defaults to `"proprietary"`.
#' @param extent       A `list` with the collection `spatial` and `temporal`
#'   extent. If `NULL`, an empty extent is created and later updated by
#'   [stac_add_items()].
#' @param stac_version A `character` STAC specification version.
#'   Defaults to `"1.0.0"`.
#' @param catalog      A `doc_catalog` object the collection is attached to.
#' @param collection   A `doc_collection` object to register. If `NULL`, one is
#'   created from `...`.
#' @param root_dir     A `character` directory under which documents are
#'   written. Defaults to the current working directory.
#' @param ...          Additional named fields. For `new_collection()`, these
#'   are added to the collection document. For `stac_add_collection()`, these
#'   are passed to `new_collection()` when `collection` is `NULL`.
#'
#' @return
#' \itemize{
#'   \item `new_collection()`: a `doc_collection` object.
#'   \item `stac_add_collection()`: invisibly, the saved `doc_collection`.
#' }
#'
#' @examples
#' col <- new_collection(
#'   id = "my-collection",
#'   title = "My Collection",
#'   description = "An example collection"
#' )
#' col$type
#'
#' dir <- tempfile("stac-")
#' cat <- stac_init("cat", "Catalog", "Example", root_dir = dir)
#' stac_add_collection(cat, collection = col, root_dir = dir)
NULL

#' @rdname collection_functions
#' @export
new_collection <- function(id,
                           title,
                           description,
                           license = "proprietary",
                           extent = NULL,
                           stac_version = "1.0.0",
                           ...) {
  if (is.null(extent)) {
    extent <- list(
      spatial = list(bbox = list(c(NA, NA, NA, NA))),
      temporal = list(interval = list(list(NULL, NULL)))
    )
  }

  col_data <- list(
    stac_version = stac_version,
    type = "Collection",
    id = id,
    title = title,
    description = description,
    license = license,
    extent = extent,
    links = list(
      list(rel = "self", href = "collection.json", type = "application/json"),
      list(rel = "root", href = "../../catalog.json", type = "application/json"),
      list(rel = "parent", href = "../../catalog.json",
           type = "application/json")
    )
  )

  extras <- list(...)
  for (nm in names(extras)) {
    col_data[[nm]] <- extras[[nm]]
  }

  .as_rstac(col_data)
}

#' @rdname collection_functions
#' @export
stac_add_collection <- function(catalog,
                                collection = NULL,
                                ...,
                                root_dir = ".") {
  if (is.null(collection)) {
    collection <- new_collection(...)
  }

  stac_save(collection, root_dir = root_dir)

  catalog$links <- .add_link(
    catalog$links,
    "child",
    glue::glue("collections/{collection$id}/collection.json"),
    title = collection$title
  )
  catalog <- .as_rstac(catalog)
  stac_save(catalog, root_dir = root_dir)

  message(glue::glue("Collection {collection$id} added to Catalog."))
  invisible(collection)
}
