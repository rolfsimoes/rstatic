#' @title Save STAC documents to their canonical paths
#'
#' @name stac_save
#'
#' @description
#' Writes a STAC `Catalog`, `Collection`, and/or `Item` documents to disk
#' following the canonical static catalog layout:
#' \itemize{
#'   \item `Catalog`    -> `stac/catalog.json`
#'   \item `Collection` -> `stac/collections/{id}/collection.json`
#'   \item `Item`       -> `stac/collections/{collection}/items/{id}/item.json`
#' }
#'
#' `stac_save()` is the only writer in the package, and it is a **pure
#' overwrite**: it writes exactly the documents it is given, with no disk reads
#' and no implicit merging. To accumulate state across runs (for example a
#' catalog populated by several scripts), read the existing document first with
#' [stac_read()], add to it with the `add_*()` builders, then save the result.
#'
#' Documents are written children-first (items, then collection, then catalog)
#' so a reader following a parent's links always finds the child already on
#' disk. Items are stamped with the `collection` field from the `collection`
#' argument when they do not already carry one; an item that already records a
#' `collection` keeps its own value, and a warning is emitted if that value
#' differs from the `collection` argument. Any asset built with
#' [new_thumbnail()] is rendered to a PNG at this point (requires \pkg{terra}).
#'
#' @param catalog    An optional `doc_catalog` from [new_catalog()].
#' @param collection An optional `doc_collection` from [new_collection()]. When
#'   `items` are given, supplies their `collection` field.
#' @param items      An optional `doc_item`, or a `list` of `doc_item` objects.
#' @param root_dir   A `character` directory under which the `stac/` tree is
#'   written. Defaults to the current working directory.
#'
#' @return Invisibly, `NULL`.
#'
#' @examples
#' dir <- tempfile("stac-")
#' cat <- new_catalog("c", "Catalog", "An example catalog")
#' col <- new_collection("col", "Collection", "An example collection")
#' item <- new_item("item-1", bbox = c(-50, -10, -49, -9))
#'
#' col <- add_items(col, item)
#' cat <- add_collection(cat, col)
#' stac_save(catalog = cat, collection = col, items = item, root_dir = dir)
#'
#' @export
stac_save <- function(catalog = NULL,
                      collection = NULL,
                      items = NULL,
                      root_dir = ".") {
  if (inherits(items, "doc_item")) {
    items <- list(items)
  }

  col_id <- if (!is.null(collection)) collection$id else NULL

  if (!is.null(items) && length(items) > 0) {
    if (!all(vapply(items, inherits, logical(1), "doc_item"))) {
      stop("`items` must be a `doc_item` object, or a list of `doc_item` ",
           "objects, from `new_item()`.", call. = FALSE)
    }
    for (item in items) {
      if (is.null(item$collection)) {
        if (is.null(col_id)) {
          stop("Items need a collection to be saved: pass `collection`, or ",
               "set the item's `collection` field.", call. = FALSE)
        }
        item$collection <- col_id
      } else if (!is.null(col_id) && !identical(item$collection, col_id)) {
        warning(sprintf(
          paste0("Item '%s' has collection '%s', which differs from the ",
                 "`collection` argument ('%s'); keeping the item's own value."),
          item$id, item$collection, col_id
        ), call. = FALSE)
      }
      .save_item(.as_rstac(item), root_dir)
    }
  }

  if (!is.null(collection)) {
    if (!inherits(collection, "doc_collection")) {
      stop("`collection` must be a `doc_collection` object from ",
           "`new_collection()`.", call. = FALSE)
    }
    path <- file.path(
      root_dir, "stac", "collections", collection$id, "collection.json"
    )
    .write_json(collection, path)
  }

  if (!is.null(catalog)) {
    if (!inherits(catalog, "doc_catalog")) {
      stop("`catalog` must be a `doc_catalog` object from `new_catalog()`.",
           call. = FALSE)
    }
    .write_json(catalog, file.path(root_dir, "stac", "catalog.json"))
  }

  invisible(NULL)
}

#' Write an item, rendering any thumbnail intent into its directory first
#'
#' @keywords internal
#' @noRd
.save_item <- function(item, root_dir) {
  item_dir <- file.path(
    root_dir, "stac", "collections", item$collection, "items", item$id
  )
  if (!is.null(item$assets)) {
    for (key in names(item$assets)) {
      spec <- attr(item$assets[[key]], "thumbnail_spec")
      if (!is.null(spec)) {
        .render_thumbnail(spec, file.path(item_dir, item$assets[[key]]$href))
      }
    }
  }
  .write_json(item, file.path(item_dir, "item.json"))
}
