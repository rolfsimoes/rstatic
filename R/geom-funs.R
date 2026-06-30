#' @title Spatial helpers for STAC documents
#'
#' @name geom_functions
#'
#' @description
#' Helper functions to derive the spatial metadata required by STAC items.
#'
#' \itemize{
#'   \item `extract_bbox()`: reads a raster (local or remote) and returns its
#'     bounding box in WGS84 (`EPSG:4326`). This function requires the optional
#'     \pkg{terra} package. It is generic: pass either a `character` path or URL,
#'     or a `doc_asset` from [new_asset()], in which case the raster is read from
#'     the asset's resolved `local_path` (see [update_root()]) or its `href`.
#'   \item `as_geometry()`: converts a bounding box into a GeoJSON `Polygon`
#'     geometry. This function has no external dependencies.
#' }
#'
#' If \pkg{terra} is not installed, you can still build items by passing a
#' bounding box (a numeric vector `c(xmin, ymin, xmax, ymax)`) directly to
#' [new_item()] and, optionally, a geometry created with `as_geometry()`.
#'
#' @param x    A `character` path or URL to a raster file readable by
#'   \pkg{terra}, or a `doc_asset` from [new_asset()]. Remote `http(s)` URLs are
#'   accessed through GDAL's `/vsicurl/` driver.
#' @param bbox A numeric vector of length 4 with the bounding box coordinates
#'   in the order `c(xmin, ymin, xmax, ymax)`.
#'
#' @return
#' \itemize{
#'   \item `extract_bbox()`: a numeric vector `c(xmin, ymin, xmax, ymax)`, or
#'     `NULL` if the raster could not be read.
#'   \item `as_geometry()`: a `list` representing a GeoJSON `Polygon`
#'     geometry, or `NULL` if `bbox` is `NULL`.
#' }
#'
#' @examples
#' # as_geometry() works without any optional dependency
#' bbox <- c(-50, -10, -49, -9)
#' as_geometry(bbox)
#'
#' # extract_bbox() requires terra
#' if (requireNamespace("terra", quietly = TRUE)) {
#'   f <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.tif",
#'                     package = "rstatic")
#'   if (nzchar(f)) {
#'     # from a path or URL
#'     extract_bbox(f)
#'     # or directly from an asset
#'     extract_bbox(new_asset(f, title = "B04"))
#'   }
#' }
NULL

#' @rdname geom_functions
#' @export
extract_bbox <- function(x) {
  UseMethod("extract_bbox")
}

#' @rdname geom_functions
#' @export
extract_bbox.character <- function(x) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop(
      "Package 'terra' is required by 'extract_bbox()'. ",
      "Install it, or pass the bounding box directly to 'new_item()' via ",
      "the 'bbox' argument.",
      call. = FALSE
    )
  }

  vsi_url <- x
  if (grepl("^http", x) && !grepl("^/vsicurl/", x)) {
    vsi_url <- paste0("/vsicurl/", x)
  }

  tryCatch(
    {
      r <- suppressWarnings(terra::rast(vsi_url))
      ext_poly <- terra::as.polygons(terra::ext(r), crs = terra::crs(r))
      ext_wgs84 <- terra::project(ext_poly, "EPSG:4326")
      bbox <- terra::ext(ext_wgs84)
      c(bbox[1], bbox[3], bbox[2], bbox[4])
    },
    error = function(e) {
      message(glue::glue("Warning: Failed to extract bbox from {x}."))
      NULL
    }
  )
}

#' @rdname geom_functions
#' @export
extract_bbox.doc_asset <- function(x) {
  extract_bbox(.asset_source(x))
}

#' @rdname geom_functions
#' @export
as_geometry <- function(bbox) {
  if (is.null(bbox)) {
    return(NULL)
  }
  geom <- list(
    type = "Polygon",
    coordinates = list(list(
      c(bbox[1], bbox[2]),
      c(bbox[3], bbox[2]),
      c(bbox[3], bbox[4]),
      c(bbox[1], bbox[4]),
      c(bbox[1], bbox[2])
    ))
  )
  class(geom) <- c("doc_geometry", "list")
  geom
}
