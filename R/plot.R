#' @title Plot a STAC asset
#'
#' @name plot_rstatic
#'
#' @description
#' Plot visual assets such as thumbnails, quicklooks, or raster previews.
#' Supported file formats are `png`, `jpeg`, and `tiff`/`tif`. The file is
#' resolved from the asset's `local_path` attribute when present, otherwise from
#' its `href`. Set `local_path` to point the plot method at a rendered file when
#' the asset's `href` is relative (for example a thumbnail written under an item
#' directory by [stac_save()]).
#'
#' @param x   A `doc_asset` object.
#' @param ... Additional arguments passed to the underlying plotting engine
#'   (currently ignored for image formats, passed to [terra::plot()] for
#'   GeoTIFFs).
#'
#' @return Invisibly, `x`.
#'
#' @examples
#' thumb <- new_asset("thumbnail.png", title = "Thumbnail",
#'   roles = list("thumbnail"))
#' attr(thumb, "local_path") <- system.file("extdata/img/logo.png",
#'   package = "rstatic")
#' if (nzchar(attr(thumb, "local_path"))) plot(thumb)
NULL

#' @rdname plot_rstatic
#' @export
plot.doc_asset <- function(x, ...) {
  path <- attr(x, "local_path")
  if (is.null(path) || !file.exists(path)) {
    path <- x$href
    if (is.null(path) || !nzchar(path)) {
      stop("Asset has no resolvable path or href.", call. = FALSE)
    }
    if (grepl("^http", path)) {
      stop(
        "Remote asset plotting is not supported. ",
        "Download the asset first or set its local_path attribute.",
        call. = FALSE
      )
    }
    if (!file.exists(path)) {
      stop(glue::glue("Asset file not found: {path}"), call. = FALSE)
    }
  }

  ext <- tolower(tools::file_ext(path))
  if (ext == "png") {
    if (!requireNamespace("png", quietly = TRUE)) {
      stop("Package 'png' is required to plot PNG assets.", call. = FALSE)
    }
    img <- png::readPNG(path)
  } else if (ext %in% c("jpg", "jpeg")) {
    if (!requireNamespace("jpeg", quietly = TRUE)) {
      stop("Package 'jpeg' is required to plot JPEG assets.", call. = FALSE)
    }
    img <- jpeg::readJPEG(path)
  } else if (ext %in% c("tif", "tiff")) {
    if (!requireNamespace("terra", quietly = TRUE)) {
      stop("Package 'terra' is required to plot GeoTIFF assets.", call. = FALSE)
    }
    terra::plot(terra::rast(path), ...)
    return(invisible(x))
  } else {
    stop(glue::glue("Asset format not supported for plotting: {ext}"), call. = FALSE)
  }

  graphics::plot(1:10, type = "n", axes = FALSE, xlab = "", ylab = "")
  grid::grid.raster(img)

  invisible(x)
}
