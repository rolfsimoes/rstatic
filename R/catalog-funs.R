#' @title Create STAC catalogs
#'
#' @name catalog_functions
#'
#' @description
#' Pure builder for a STAC `Catalog` document. It does not touch disk; use
#' [stac_save()] to persist and [stac_read()] to load an existing catalog.
#'
#' @param id           A `character` identifier for the catalog.
#' @param title        A `character` human-readable title.
#' @param description  A `character` description of the catalog.
#' @param stac_version A `character` STAC specification version.
#'   Defaults to `"1.0.0"`.
#' @param ...          Additional named fields to add to the catalog document.
#'
#' @return A `doc_catalog` object.
#'
#' @examples
#' cat <- new_catalog(
#'   id = "my-catalog",
#'   title = "My Catalog",
#'   description = "An example STAC catalog"
#' )
#' cat$type
#'
#' # Write a root catalog to a temporary directory
#' dir <- tempfile("stac-")
#' stac_save(catalog = cat, root_dir = dir)
#'
#' @export
new_catalog <- function(id,
                        title,
                        description,
                        stac_version = "1.0.0",
                        ...) {
  cat_data <- list(
    stac_version = stac_version,
    type = "Catalog",
    id = id,
    title = title,
    description = description,
    links = list(
      list(rel = "self", href = "catalog.json", type = "application/json"),
      list(rel = "root", href = "catalog.json", type = "application/json")
    )
  )

  extras <- list(...)
  for (nm in names(extras)) {
    cat_data[[nm]] <- extras[[nm]]
  }

  .as_rstac(cat_data)
}
