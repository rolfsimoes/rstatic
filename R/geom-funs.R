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
#'     \pkg{terra} package.
#'   \item `as_geometry()`: converts a bounding box into a GeoJSON `Polygon`
#'     geometry. This function has no external dependencies.
#' }
#'
#' If \pkg{terra} is not installed, you can still build items by passing a
#' bounding box (a numeric vector `c(xmin, ymin, xmax, ymax)`) directly to
#' [new_item()] and, optionally, a geometry created with `as_geometry()`.
#'
#' @param url  A `character` path or URL to a raster file readable by
#'   \pkg{terra}. Remote `http(s)` URLs are accessed through GDAL's
#'   `/vsicurl/` driver.
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
#'   f <- system.file("extdata/example.tif", package = "rstatic")
#'   if (nzchar(f)) {
#'     extract_bbox(f)
#'   }
#' }
NULL

#' @rdname geom_functions
#' @export
extract_bbox <- function(url) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop(
      "Package 'terra' is required by 'extract_bbox()'. ",
      "Install it, or pass the bounding box directly to 'new_item()' via ",
      "the 'bbox' argument.",
      call. = FALSE
    )
  }

  vsi_url <- url
  if (grepl("^http", url) && !grepl("^/vsicurl/", url)) {
    vsi_url <- paste0("/vsicurl/", url)
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
      message(glue::glue("Warning: Failed to extract bbox from {url}."))
      NULL
    }
  )
}

#' @rdname geom_functions
#' @export
as_geometry <- function(bbox) {
  if (is.null(bbox)) {
    return(NULL)
  }
  list(
    type = "Polygon",
    coordinates = list(list(
      c(bbox[1], bbox[2]),
      c(bbox[3], bbox[2]),
      c(bbox[3], bbox[4]),
      c(bbox[1], bbox[4]),
      c(bbox[1], bbox[2])
    ))
  )
}
