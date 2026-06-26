#' @title Create and initialize STAC catalogs
#'
#' @name catalog_functions
#'
#' @description
#' Functions to build a STAC `Catalog` document.
#'
#' \itemize{
#'   \item `new_catalog()`: creates an in-memory `Catalog` object.
#'   \item `stac_init()`: creates (or updates) the root catalog on disk under
#'     a `stac/` directory, preserving any existing child links.
#' }
#'
#' @param id           A `character` identifier for the catalog.
#' @param title        A `character` human-readable title.
#' @param description  A `character` description of the catalog.
#' @param stac_version A `character` STAC specification version.
#'   Defaults to `"1.0.0"`.
#' @param root_dir     A `character` directory under which the catalog is
#'   written. Defaults to the current working directory.
#' @param ...          Additional named fields to add to the catalog document.
#'
#' @return
#' \itemize{
#'   \item `new_catalog()`: a `doc_catalog` object.
#'   \item `stac_init()`: invisibly, the saved `doc_catalog` object.
#' }
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
#' stac_init(
#'   id = "my-catalog",
#'   title = "My Catalog",
#'   description = "An example STAC catalog",
#'   root_dir = dir
#' )
NULL

#' @rdname catalog_functions
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

#' @rdname catalog_functions
#' @export
stac_init <- function(id, title, description, root_dir = ".") {
  cat_path <- file.path(root_dir, "stac", "catalog.json")

  existing <- .read_json(cat_path)
  cat_data <- new_catalog(id, title, description)

  if (!is.null(existing$links)) {
    child_links <- existing$links[vapply(
      existing$links,
      function(l) isTRUE(l$rel == "child"),
      logical(1)
    )]
    cat_data$links <- c(cat_data$links, child_links)
  }

  stac_save(cat_data, root_dir = root_dir)
  message(glue::glue("Catalog {id} initialized/updated at {cat_path}"))
  invisible(cat_data)
}
