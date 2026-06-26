#' @title Generate a thumbnail asset
#'
#' @name new_thumbnail
#'
#' @description
#' Renders a PNG thumbnail from a raster and returns a STAC `Asset` pointing to
#' it. The thumbnail is written under the canonical item directory
#' `stac/collections/{collection_id}/items/{item_id}/thumbnail.png`.
#'
#' This function requires the optional \pkg{terra} package. If \pkg{terra} is
#' not installed, build the thumbnail asset manually with [new_asset()].
#'
#' @param collection_id A `character` collection identifier.
#' @param item_id       A `character` item identifier.
#' @param asset_href    A `character` path or URL to the source raster.
#' @param width         An `integer` thumbnail width in pixels. Defaults to
#'   `800`.
#' @param title         A `character` asset title. Defaults to `"Thumbnail"`.
#' @param style         An optional style `list` from [stac_style()] or
#'   [qml_to_style()].
#' @param root_dir      A `character` directory under which the thumbnail is
#'   written. Defaults to the current working directory.
#' @param ...           Additional arguments passed to [terra::plot()].
#'
#' @return A `list` describing the thumbnail asset (as from [new_asset()]).
#'
#' @examples
#' if (requireNamespace("terra", quietly = TRUE)) {
#'   f <- system.file("extdata/example.tif", package = "rstatic")
#'   if (nzchar(f)) {
#'     dir <- tempfile("stac-")
#'     new_thumbnail(
#'       collection_id = "col",
#'       item_id = "item-1",
#'       asset_href = f,
#'       root_dir = dir
#'     )
#'   }
#' }
#'
#' @export
new_thumbnail <- function(collection_id,
                          item_id,
                          asset_href,
                          width = 800,
                          title = "Thumbnail",
                          style = NULL,
                          root_dir = ".",
                          ...) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop(
      "Package 'terra' is required by 'new_thumbnail()'. ",
      "Install it, or build the thumbnail asset manually with 'new_asset()'.",
      call. = FALSE
    )
  }

  url <- asset_href
  vsi_url <- url
  if (grepl("^http", url) && !grepl("^/vsicurl/", url)) {
    vsi_url <- paste0("/vsicurl/", url)
  }

  item_dir <- file.path(
    root_dir, "stac", "collections", collection_id, "items", item_id
  )
  output_path <- file.path(item_dir, "thumbnail.png")
  dir.create(item_dir, showWarnings = FALSE, recursive = TRUE)

  r <- suppressWarnings(terra::rast(vsi_url))
  ex <- terra::ext(r)
  aspect_ratio <- (ex[4] - ex[3]) / (ex[2] - ex[1])
  height <- round(width * aspect_ratio)

  if (height > 2000) {
    height <- 2000
    width <- round(height / aspect_ratio)
  }

  grDevices::png(output_path, width = width, height = height,
                 bg = "transparent")
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))

  plot_args <- list(
    r,
    axes = FALSE,
    legend = FALSE,
    box = FALSE,
    mar = c(0, 0, 0, 0)
  )

  if (!is.null(style)) {
    if (!is.null(style$legend)) {
      legend <- style$legend
      if (is.data.frame(legend) && "color" %in% names(legend)) {
        rgb <- t(grDevices::col2rgb(legend$color, alpha = TRUE))
        legend <- data.frame(
          value = legend$value,
          red = rgb[, 1],
          green = rgb[, 2],
          blue = rgb[, 3],
          alpha = rgb[, 4]
        )
      }
      terra::coltab(r) <- legend
      plot_args[[1]] <- r
    } else {
      range_vals <- c(style$min, style$max)
      if (!is.null(style$pmin) || !is.null(style$pmax)) {
        probs <- c(style$pmin %||% 0, style$pmax %||% 1)
        q <- terra::global(r, "quantile", probs = probs, na.rm = TRUE)
        range_vals <- as.numeric(q)
      }
      if (any(!is.na(range_vals))) {
        plot_args$range <- range_vals
      }
      if (!is.null(style$palette)) {
        plot_args$col <- style$palette
      }
    }
  }

  dots <- list(...)
  for (nm in names(dots)) {
    plot_args[[nm]] <- dots[[nm]]
  }

  do.call(terra::plot, plot_args)

  new_asset("thumbnail.png", title = title, roles = list("thumbnail"))
}
