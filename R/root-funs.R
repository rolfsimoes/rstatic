#' @title Resolve a document's asset paths under a local root
#'
#' @name update_root
#'
#' @description
#' Returns a copy of an in-memory STAC document whose assets point at their
#' on-disk locations under a local `root_dir`, following the canonical static
#' catalog layout used by [stac_save()]. For every asset with a relative `href`,
#' the `local_path` attribute is set to the file's location under `root_dir`;
#' assets whose `href` is already an absolute path or a URL are returned
#' unchanged.
#'
#' `update_root()` is generic and dispatches on the document class:
#' \itemize{
#'   \item `doc_item`: assets resolve under
#'     `root_dir/stac/collections/<collection>/items/<id>/`. The collection is
#'     read from the item's own `collection` field, so build the item with
#'     `new_item(collection = ...)` (or save it first, which stamps the field).
#'   \item `doc_collection`: assets resolve under
#'     `root_dir/stac/collections/<id>/`, which covers a collection-level
#'     thumbnail propagated from its items.
#' }
#'
#' It is a pure helper: it reads no raster and writes no file. Its purpose is to
#' make files produced by [stac_save()] -- such as a thumbnail PNG rendered into
#' the item directory -- resolvable by [plot()] and other local readers, which
#' consult an asset's `local_path` attribute before falling back to its `href`.
#'
#' @param x        A `doc_item` from [new_item()] or a `doc_collection` from
#'   [new_collection()].
#' @param root_dir A `character` directory under which the `stac/` tree was
#'   written by [stac_save()].
#'
#' @return The document `x`, with the `local_path` attribute set on each asset
#'   that has a relative `href`.
#'
#' @examples
#' root <- tempfile("stac-")
#' col <- new_collection("land-cover", "Land Cover", "Example collection")
#' item <- new_item(
#'   "land-cover-2022",
#'   bbox = c(-50, -10, -49, -9),
#'   collection = col,
#'   assets = list(data = new_asset("data.tif", title = "Data"))
#' )
#' stac_save(collection = col, items = item, root_dir = root)
#'
#' item <- update_root(item, root)
#' attr(item$assets$data, "local_path")
#'
#' @export
update_root <- function(x, root_dir) {
  UseMethod("update_root")
}

#' @rdname update_root
#' @export
update_root.doc_item <- function(x, root_dir) {
  .check_root_dir(root_dir)
  if (is.null(x$collection) || !nzchar(x$collection)) {
    stop("`x` has no `collection` field, so its on-disk path cannot be ",
         "resolved. Build the item with `new_item(collection = ...)`, or pass ",
         "it through `stac_save()` first.", call. = FALSE)
  }
  base_dir <- file.path(
    root_dir, "stac", "collections", x$collection, "items", x$id
  )
  .resolve_asset_paths(x, base_dir)
}

#' @rdname update_root
#' @export
update_root.doc_collection <- function(x, root_dir) {
  .check_root_dir(root_dir)
  base_dir <- file.path(root_dir, "stac", "collections", x$id)
  .resolve_asset_paths(x, base_dir)
}

#' Set each asset's local_path relative to a base directory
#'
#' Assets with a remote or absolute `href` are left untouched.
#'
#' @keywords internal
#' @noRd
.resolve_asset_paths <- function(doc, base_dir) {
  for (key in names(doc$assets)) {
    asset <- doc$assets[[key]]
    href <- asset$href
    if (!is.null(href) && !.is_remote_href(href) && !.is_absolute_href(href)) {
      attr(asset, "local_path") <- file.path(base_dir, href)
      doc$assets[[key]] <- asset
    }
  }
  .as_rstac(doc)
}

#' Validate the `root_dir` argument
#'
#' @keywords internal
#' @noRd
.check_root_dir <- function(root_dir) {
  if (!is.character(root_dir) || length(root_dir) != 1L) {
    stop("`root_dir` must be a single character string.", call. = FALSE)
  }
  invisible(root_dir)
}

#' Test whether an href is a remote URL
#'
#' @keywords internal
#' @noRd
.is_remote_href <- function(href) {
  grepl("^[a-z][a-z0-9+.-]*://", href, ignore.case = TRUE)
}

#' Test whether an href is an absolute filesystem path
#'
#' @keywords internal
#' @noRd
.is_absolute_href <- function(href) {
  grepl("^(/|~|[A-Za-z]:[\\\\/])", href)
}
