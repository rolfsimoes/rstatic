#' @title Create STAC items, properties, and assets
#'
#' @name item_functions
#'
#' @description
#' Pure builders for the building blocks of a STAC `Item`. None touch disk; use
#' [stac_save()] to persist.
#'
#' \itemize{
#'   \item `new_properties()`: assembles an item `properties` list.
#'   \item `new_asset()`: creates a single STAC `Asset`.
#'   \item `new_item()`: creates an in-memory `Item` (a GeoJSON `Feature`).
#'   \item `add_items()`: links one or more items into a collection, updating
#'     the collection links and spatio-temporal extent, and returns the
#'     collection.
#' }
#'
#' STAC requires every item to carry a `datetime`. When you describe a time
#' range instead of a single instant, supply `start_datetime` and `end_datetime`
#' and omit `datetime`; `new_properties()` then records `datetime` as `null`, as
#' the specification mandates. `add_items()` derives the collection's temporal
#' extent from the range (or from `datetime` when only that is given).
#'
#' @param description    A `character` description.
#' @param datetime       A `character` RFC 3339 datetime, or `NULL`. Recorded as
#'   `null` when omitted alongside a `start_datetime`/`end_datetime` range.
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
#' @param collection     For `add_items()`, the `doc_collection` to link items
#'   into. For `new_item()`, an optional `doc_collection` or `character`
#'   collection id recorded as the item's top-level `collection` field. STAC
#'   requires this field whenever the item carries a `collection` link (as items
#'   built here always do); when omitted, [stac_save()] stamps it from the
#'   `collection` it is given.
#' @param items          A single `doc_item`, or a `list` of `doc_item`
#'   objects, to link into the collection.
#' @param ...            Additional named fields. See details for each
#'   function.
#'
#' @return
#' \itemize{
#'   \item `new_properties()`: a `list` of properties.
#'   \item `new_asset()`: a `doc_asset` object describing an asset.
#'   \item `new_item()`: a `doc_item` object.
#'   \item `add_items()`: the updated `doc_collection`.
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
#' col <- new_collection("col", "Collection", "Example")
#' col <- add_items(col, item)
#' col$extent$spatial$bbox[[1]]
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
  if (!is.null(datetime)) {
    props$datetime <- datetime
  } else if (!is.null(start_datetime) || !is.null(end_datetime) ||
             !is.null(start_date) || !is.null(end_date)) {
    # STAC requires `datetime` to be present; it may be null only when a
    # start/end range is given. `props["datetime"] <- list(NULL)` keeps the
    # key with a null value (`props$datetime <- NULL` would drop it).
    props["datetime"] <- list(NULL)
  }
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
                     collection = NULL,
                     stac_version = "1.0.0",
                     ...) {
  if (is.null(geometry)) {
    geometry <- as_geometry(bbox)
  }

  col_id <- NULL
  if (!is.null(collection)) {
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

  # STAC requires the `collection` field whenever a `collection` link is
  # present (as it always is here). Place it right after `id` when known.
  if (!is.null(col_id)) {
    item_data <- append(item_data, list(collection = col_id),
                        after = which(names(item_data) == "id"))
  }

  .as_rstac(item_data)
}

#' @rdname item_functions
#' @export
add_items <- function(collection, items) {
  if (!inherits(collection, "doc_collection")) {
    stop("`collection` must be a `doc_collection` object from ",
         "`new_collection()`.", call. = FALSE)
  }
  if (inherits(items, "doc_item")) {
    items <- list(items)
  }
  if (length(items) == 0) {
    return(collection)
  }
  if (!all(vapply(items, inherits, logical(1), "doc_item"))) {
    stop("`items` must be a `doc_item` object, or a list of `doc_item` ",
         "objects, from `new_item()`.", call. = FALSE)
  }

  for (item in items) {
    collection <- add_link(
      collection,
      "item",
      glue::glue("items/{item$id}/item.json"),
      title = item$id
    )

    collection <- .update_spatial_extent(collection, item$bbox)
    collection <- .update_temporal_extent(collection, item$properties)
    collection <- .propagate_thumbnail(collection, item)
  }

  collection
}

#' @title Add an asset to a STAC document
#'
#' @name add_asset
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
#' item <- add_asset(item, "data", new_asset("data.tif"))
#'
#' @export
add_asset <- function(doc, key, asset) {
  if (!inherits(doc, "doc_item") && !inherits(doc, "doc_collection")) {
    stop("`doc` must be a `doc_item` or `doc_collection` object.",
         call. = FALSE)
  }
  if (!is.character(key) || length(key) != 1L) {
    stop("`key` must be a single character string.", call. = FALSE)
  }
  if (!inherits(asset, "doc_asset")) {
    stop("`asset` must be a `doc_asset` object from `new_asset()`.",
         call. = FALSE)
  }
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
