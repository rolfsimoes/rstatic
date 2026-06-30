#' @title Resolve an item's asset paths under a local root
#'
#' @name update_root
#'
#' @description
#' Returns a copy of an in-memory `doc_item` whose assets point at their
#' on-disk locations under a local `root_dir`, following the canonical static
#' catalog layout used by [stac_save()]. For every asset with a relative
#' `href`, the `local_path` attribute is set to
#' `root_dir/stac/collections/<collection>/items/<id>/<href>`. Assets whose
#' `href` is already an absolute path or a URL are returned unchanged.
#'
#' `update_root()` is a pure helper: it reads no raster and writes no file. Its
#' purpose is to make files produced by [stac_save()] -- such as a thumbnail PNG
#' rendered into the item directory -- resolvable by [plot()] and other local
#' readers, which consult an asset's `local_path` attribute before falling back
#' to its `href`.
#'
#' The `collection` is supplied explicitly because an in-memory item does not
#' record the collection it belongs to; that field is stamped onto the written
#' copy by [stac_save()], not onto the item in hand.
#'
#' @param item       A `doc_item` from [new_item()].
#' @param root_dir   A `character` directory under which the `stac/` tree was
#'   written by [stac_save()].
#' @param collection A `doc_collection` from [new_collection()], or a
#'   `character` collection id. Supplies the collection segment of the item's
#'   on-disk path.
#'
#' @return The `doc_item`, with the `local_path` attribute set on each asset
#'   that has a relative `href`.
#'
#' @examples
#' root <- tempfile("stac-")
#' col <- new_collection("land-cover", "Land Cover", "Example collection")
#' item <- new_item(
#'   "land-cover-2022",
#'   bbox = c(-50, -10, -49, -9),
#'   assets = list(data = new_asset("data.tif", title = "Data"))
#' )
#' stac_save(collection = col, items = item, root_dir = root)
#'
#' item <- update_root(item, root, col)
#' attr(item$assets$data, "local_path")
#'
#' @export
update_root <- function(item, root_dir, collection) {
  if (!inherits(item, "doc_item")) {
    stop("`item` must be a `doc_item` object from `new_item()`.",
         call. = FALSE)
  }
  if (!is.character(root_dir) || length(root_dir) != 1L) {
    stop("`root_dir` must be a single character string.", call. = FALSE)
  }
  col_id <- if (inherits(collection, "doc_collection")) {
    collection$id
  } else {
    collection
  }
  if (!is.character(col_id) || length(col_id) != 1L) {
    stop("`collection` must be a `doc_collection` object from ",
         "`new_collection()`, or a single character collection id.",
         call. = FALSE)
  }

  item_dir <- file.path(
    root_dir, "stac", "collections", col_id, "items", item$id
  )

  for (key in names(item$assets)) {
    asset <- item$assets[[key]]
    href <- asset$href
    if (!is.null(href) && !.is_remote_href(href) && !.is_absolute_href(href)) {
      attr(asset, "local_path") <- file.path(item_dir, href)
      item$assets[[key]] <- asset
    }
  }

  .as_rstac(item)
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
