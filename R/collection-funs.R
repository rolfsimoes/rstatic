#' @title Create and attach STAC collections
#'
#' @name collection_functions
#'
#' @description
#' Pure builders for a STAC `Collection` document. Neither function touches
#' disk; use [stac_save()] to persist.
#'
#' \itemize{
#'   \item `new_collection()`: creates an in-memory `Collection` object.
#'   \item `add_collection()`: registers a collection as a `child` of a catalog
#'     and returns the updated catalog.
#' }
#'
#' @param id           A `character` identifier for the collection.
#' @param title        A `character` human-readable title.
#' @param description  A `character` description of the collection.
#' @param license      A `character` license identifier or URL.
#'   Defaults to `"proprietary"`.
#' @param extent       A `list` with the collection `spatial` and `temporal`
#'   extent. If `NULL`, an empty extent is created and later updated by
#'   [add_items()].
#' @param stac_version A `character` STAC specification version.
#'   Defaults to `"1.0.0"`.
#' @param catalog      A `doc_catalog` object the collection is attached to.
#' @param collection   A `doc_collection` object to register.
#' @param ...          Additional named fields added to the collection document.
#'
#' @return
#' \itemize{
#'   \item `new_collection()`: a `doc_collection` object.
#'   \item `add_collection()`: the updated `doc_catalog` (the parent), so it can
#'     be chained with another call.
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
#' cat <- new_catalog("cat", "Catalog", "Example")
#' cat <- add_collection(cat, col)
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
add_collection <- function(catalog, collection) {
  if (!inherits(catalog, "doc_catalog")) {
    stop("`catalog` must be a `doc_catalog` object from `new_catalog()`.",
         call. = FALSE)
  }
  if (!inherits(collection, "doc_collection")) {
    stop("`collection` must be a `doc_collection` object from ",
         "`new_collection()`.", call. = FALSE)
  }

  add_link(
    catalog,
    "child",
    glue::glue("collections/{collection$id}/collection.json"),
    title = collection$title
  )
}
