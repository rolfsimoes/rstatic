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

#' @title List and filter the links of a STAC document
#'
#' @name list_links
#'
#' @description
#' Returns the links of a STAC document as a plain `list`, optionally keeping
#' only those that satisfy one or more filter expressions. Each expression in
#' `...` is evaluated against a single link, with the link's fields (`rel`,
#' `href`, `type`, `title`) available as names, and the expressions are combined
#' with logical AND. With no expressions, every link is returned.
#'
#' This mirrors the ergonomics of `rstac::links()`: instead of writing
#' `Filter(function(l) l$rel == "child", doc$links)`, you write
#' `list_links(doc, rel == "child")`.
#'
#' A link whose fields make an expression error (for example a link that has no
#' `title`) is treated as not matching, rather than raising an error. Variables
#' from the calling scope may be used in the expressions.
#'
#' @param x   A STAC document (`doc_catalog`, `doc_collection`, or `doc_item`),
#'   or a bare `list` of links.
#' @param ... Optional filter expressions evaluated against each link, e.g.
#'   `rel == "child"`. Combined with logical AND.
#'
#' @return A `list` of links (each element as stored on the document). The list
#'   is empty when nothing matches.
#'
#' @examples
#' catalog <- new_catalog("cat", "Catalog", "Example")
#' catalog <- add_collection(catalog, new_collection("a", "A", "First"))
#' catalog <- add_collection(catalog, new_collection("b", "B", "Second"))
#'
#' # All links
#' list_links(catalog)
#'
#' # Only the child links
#' list_links(catalog, rel == "child")
#'
#' # Combine predicates (logical AND)
#' list_links(catalog, rel == "child", type == "application/json")
#'
#' @export
list_links <- function(x, ...) {
  links <- if (inherits(x, "rstac_doc")) x$links else x
  if (!is.list(links)) {
    stop("`x` must be a STAC document (`doc_catalog`, `doc_collection`, or ",
         "`doc_item`), or a `list` of links.", call. = FALSE)
  }
  links <- unclass(links)
  if (length(links) == 0) {
    return(list())
  }

  exprs <- eval(substitute(alist(...)))
  parent <- parent.frame()
  keep <- rep(TRUE, length(links))
  for (expr in exprs) {
    keep <- keep & vapply(links, function(link) {
      isTRUE(tryCatch(eval(expr, link, enclos = parent),
                      error = function(e) FALSE))
    }, logical(1))
  }
  links[keep]
}
