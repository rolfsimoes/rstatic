#' @title Create STAC items, properties, and assets
#'
#' @name item_functions
#'
#' @description
#' Functions to build the building blocks of a STAC `Item`.
#'
#' \itemize{
#'   \item `new_properties()`: assembles an item `properties` list.
#'   \item `new_asset()`: creates a single STAC `Asset`.
#'   \item `new_item()`: creates an in-memory `Item` (a GeoJSON `Feature`).
#'   \item `stac_add_items()`: persists one or more items into a collection,
#'     updating the collection links and spatio-temporal extent.
#' }
#'
#' @param description    A `character` description.
#' @param datetime       A `character` RFC 3339 datetime, or `NULL`.
#' @param start_datetime A `character` RFC 3339 start datetime, or `NULL`.
#' @param end_datetime   A `character` RFC 3339 end datetime, or `NULL`.
#' @param start_date     A `character` start date, or `NULL`.
#' @param end_date       A `character` end date, or `NULL`.
#' @param href           A `character` asset target (path or URL).
#' @param title          A `character` title.
#' @param roles          A `list` of asset roles. Defaults to `list("data")`.
#' @param id             A `character` identifier for the item.
#' @param bbox           A numeric vector `c(xmin, ymin, xmax, ymax)`.
#' @param geometry       A GeoJSON geometry `list`. If `NULL`, it is derived
#'   from `bbox` via [as_geometry()].
#' @param properties     A `list` of item properties, e.g. from
#'   `new_properties()`.
#' @param assets         A named `list` of assets, e.g. from `new_asset()`.
#' @param stac_version   A `character` STAC version. Defaults to `"1.0.0"`.
#' @param collection     A `doc_collection` object to add items to.
#' @param root_dir       A `character` directory under which documents are
#'   written. Defaults to the current working directory.
#' @param ...            Additional named fields. See details for each
#'   function.
#'
#' @return
#' \itemize{
#'   \item `new_properties()`: a `list` of properties.
#'   \item `new_asset()`: a `doc_asset` object describing an asset.
#'   \item `new_item()`: a `doc_item` object.
#'   \item `stac_add_items()`: invisibly, the updated `doc_collection`.
#' }
#'
#' @examples
#' props <- new_properties(datetime = "2020-01-01T00:00:00Z")
#' asset <- new_asset("data.tif", title = "Data")
#' item <- new_item(
#'   id = "item-1",
#'   bbox = c(-50, -10, -49, -9),
#'   properties = props,
#'   assets = list(data = asset)
#' )
#' item$type
#'
#' dir <- tempfile("stac-")
#' cat <- stac_init("cat", "Catalog", "Example", root_dir = dir)
#' col <- stac_add_collection(
#'   cat,
#'   collection = new_collection("col", "Collection", "Example"),
#'   root_dir = dir
#' )
#' stac_add_items(col, item, root_dir = dir)
NULL

#' @rdname item_functions
#' @export
new_properties <- function(description = NULL,
                           datetime = NULL,
                           start_datetime = NULL,
                           end_datetime = NULL,
                           start_date = NULL,
                           end_date = NULL,
                           ...) {
  props <- list(...)
  if (!is.null(description)) props$description <- description
  if (!is.null(datetime)) props$datetime <- datetime
  if (!is.null(start_datetime)) props$start_datetime <- start_datetime
  if (!is.null(end_datetime)) props$end_datetime <- end_datetime
  if (!is.null(start_date)) props$start_date <- start_date
  if (!is.null(end_date)) props$end_date <- end_date
  props
}

#' @rdname item_functions
#' @export
new_asset <- function(href,
                      title = NULL,
                      roles = list("data"),
                      ...) {
  asset <- list(
    href = href,
    type = .get_media_type(href),
    roles = roles
  )
  if (!is.null(title)) {
    asset$title <- title
  }
  extras <- list(...)
  for (nm in names(extras)) {
    asset[[nm]] <- extras[[nm]]
  }
  .as_doc_asset(asset)
}

#' @rdname item_functions
#' @export
new_item <- function(id,
                     bbox,
                     geometry = NULL,
                     properties = new_properties(),
                     assets = list(),
                     stac_version = "1.0.0",
                     ...) {
  if (is.null(geometry)) {
    geometry <- as_geometry(bbox)
  }

  extras <- list(...)
  for (nm in names(extras)) {
    properties[[nm]] <- extras[[nm]]
  }

  item_data <- list(
    stac_version = stac_version,
    type = "Feature",
    id = id,
    bbox = bbox,
    geometry = geometry,
    properties = properties,
    assets = assets,
    links = list(
      list(rel = "self", href = "item.json", type = "application/json"),
      list(rel = "root", href = "../../../../catalog.json",
           type = "application/json"),
      list(rel = "parent", href = "../../collection.json",
           type = "application/json"),
      list(rel = "collection", href = "../../collection.json",
           type = "application/json")
    )
  )

  .as_rstac(item_data)
}

#' @rdname item_functions
#' @export
stac_add_items <- function(collection, ..., root_dir = ".") {
  items <- list(...)
  if (length(items) == 0) {
    return(invisible(collection))
  }

  col_id <- collection$id

  for (item in items) {
    item$collection <- col_id
    item <- .as_rstac(item)
    stac_save(item, root_dir = root_dir)

    collection <- stac_add_link(
      collection,
      "item",
      glue::glue("items/{item$id}/item.json"),
      title = item$id
    )

    collection <- .update_spatial_extent(collection, item$bbox)
    collection <- .update_temporal_extent(collection, item$properties)
    collection <- .propagate_thumbnail(collection, item)
  }

  stac_save(collection, root_dir = root_dir)

  message(glue::glue("Added {length(items)} item(s) to collection {col_id}."))
  invisible(collection)
}

#' @title Add an asset to a STAC document
#'
#' @name stac_add_asset
#'
#' @description
#' Pure builder that attaches an asset to a STAC `Item` or `Collection`.
#' Assets set at creation time via [new_item()] can be complemented or
#' overwritten later with this function. No disk I/O is performed.
#'
#' @param doc   A STAC document (`doc_item` or `doc_collection`).
#' @param key   A `character` name for the asset in the document's `assets`
#'   map.
#' @param asset A `list` describing the asset, as from [new_asset()].
#'
#' @return The updated STAC document, with `asset` stored under
#'   `doc$assets[[key]]` and the appropriate class preserved.
#'
#' @examples
#' item <- new_item("i", bbox = c(0, 0, 1, 1))
#' item <- stac_add_asset(item, "data", new_asset("data.tif"))
#'
#' @export
stac_add_asset <- function(doc, key, asset) {
  if (is.null(doc$assets)) {
    doc$assets <- list()
  }
  doc$assets[[key]] <- asset
  .as_rstac(doc)
}

#' Update a collection spatial extent with an item bbox
#'
#' @keywords internal
#' @noRd
.update_spatial_extent <- function(collection, item_bbox) {
  if (is.null(item_bbox)) {
    return(collection)
  }
  col_bbox <- unlist(collection$extent$spatial$bbox[[1]])
  if (all(is.na(col_bbox))) {
    collection$extent$spatial$bbox[[1]] <- item_bbox
  } else {
    collection$extent$spatial$bbox[[1]] <- c(
      min(col_bbox[1], item_bbox[1], na.rm = TRUE),
      min(col_bbox[2], item_bbox[2], na.rm = TRUE),
      max(col_bbox[3], item_bbox[3], na.rm = TRUE),
      max(col_bbox[4], item_bbox[4], na.rm = TRUE)
    )
  }
  collection
}

#' Update a collection temporal extent with item properties
#'
#' @keywords internal
#' @noRd
.update_temporal_extent <- function(collection, properties) {
  item_dt <- properties$datetime
  item_start <- properties$start_datetime %||%
    properties$start_date %||% item_dt
  item_end <- properties$end_datetime %||%
    properties$end_date %||% item_dt

  item_start <- .ensure_rfc3339(item_start)
  item_end <- .ensure_rfc3339(item_end)

  if (is.null(item_start) && is.null(item_end)) {
    return(collection)
  }

  col_interval <- collection$extent$temporal$interval[[1]]
  curr_start <- if (is.null(col_interval[[1]])) NA else col_interval[[1]]
  curr_end <- if (is.null(col_interval[[2]])) NA else col_interval[[2]]

  new_start <- if (is.na(curr_start)) {
    item_start
  } else {
    min(curr_start, item_start, na.rm = TRUE)
  }
  new_end <- if (is.na(curr_end)) {
    item_end
  } else {
    max(curr_end, item_end, na.rm = TRUE)
  }

  collection$extent$temporal$interval[[1]] <- list(new_start, new_end)
  collection
}

#' Propagate the first item thumbnail to the collection assets
#'
#' @keywords internal
#' @noRd
.propagate_thumbnail <- function(collection, item) {
  if (!is.null(collection$assets$thumbnail) ||
        is.null(item$assets$thumbnail)) {
    return(collection)
  }
  if (is.null(collection$assets)) {
    collection$assets <- list()
  }
  thumb_asset <- item$assets$thumbnail
  if (!grepl("^http", thumb_asset$href)) {
    thumb_asset$href <- glue::glue("./items/{item$id}/{thumb_asset$href}")
  }
  collection$assets$thumbnail <- thumb_asset
  collection
}
