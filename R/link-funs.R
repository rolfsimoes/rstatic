#' @title Add a link to a STAC document
#'
#' @name add_link
#'
#' @description
#' Pure builder that appends a link to a STAC document's `links` list.
#' The document is returned unchanged if a link with the same `rel` and `href`
#' already exists. No disk I/O is performed.
#'
#' @param doc   A STAC document (`doc_catalog`, `doc_collection`, or
#'   `doc_item`).
#' @param rel   A `character` link relation (`self`, `root`, `parent`, `child`,
#'   `item`, `collection`, etc.).
#' @param href  A `character` link target (path or URL). Relative paths are
#'   recommended for static catalogs.
#' @param type  A `character` media type. Defaults to `"application/json"`.
#' @param title An optional `character` human-readable title for the link.
#'
#' @return The updated STAC document, with the new link appended and the
#'   appropriate `doc_*` class preserved.
#'
#' @examples
#' cat <- new_catalog("cat", "Catalog", "Example")
#' cat <- add_link(cat, "child", "collections/col/collection.json",
#'                 title = "My Collection")
#'
#' item <- new_item("i", bbox = c(0, 0, 1, 1))
#' item <- add_link(item, "derived_from", "source.json")
#'
#' @export
add_link <- function(doc,
                     rel,
                     href,
                     type = "application/json",
                     title = NULL) {
  if (!inherits(doc, "rstac_doc")) {
    stop("`doc` must be a STAC document (`doc_catalog`, `doc_collection`, ",
         "or `doc_item`).", call. = FALSE)
  }
  if (!is.character(rel) || length(rel) != 1L) {
    stop("`rel` must be a single character string.", call. = FALSE)
  }
  if (!is.character(href) || length(href) != 1L) {
    stop("`href` must be a single character string.", call. = FALSE)
  }
  doc$links <- .add_link(doc$links, rel, href, type = type, title = title)
  .as_rstac(doc)
}
