#' @title Generate a thumbnail asset
#'
#' @name new_thumbnail
#'
#' @description
#' Renders a PNG thumbnail from a raster and returns a STAC `Asset` pointing to
#' it. The thumbnail is written under the canonical item directory
#' `stac/collections/{collection_id}/items/{item_id}/thumbnail.png`.
#'
#' The optional `style` argument controls how raster values are mapped to
#' pixels. Build it with [stac_style()] or [qml_to_style()]. Without a style,
#' the raster is rendered with `terra`'s default settings.
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
#' @param style         An optional `rstatic_style` object from [stac_style()]
#'   or [qml_to_style()].
#' @param root_dir      A `character` directory under which the thumbnail is
#'   written. Defaults to the current working directory.
#' @param ...           Additional arguments passed to the underlying `terra`
#'   plotting function.
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
#'       style = stac_style(min = 0, max = 0.5, palette = c("black", "white")),
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

  if (!is.null(style) && !inherits(style, "rstatic_style")) {
    stop("`style` must be an `rstatic_style` object from `stac_style()` ",
         "or `qml_to_style()`.", call. = FALSE)
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

  if (is.null(style)) {
    render_default(r, ...)
  } else {
    render_style(style, r, ...)
  }

  asset <- new_asset("thumbnail.png", title = title, roles = list("thumbnail"))
  attr(asset, "local_path") <- output_path
  asset
}

#' Render a raster without an explicit style
#'
#' @keywords internal
#' @noRd
render_default <- function(r, ...) {
  do.call(terra::plot, c(
    list(r, axes = FALSE, legend = FALSE, box = FALSE, mar = c(0, 0, 0, 0)),
    list(...)
  ))
}

#' Render a raster according to a normalized style
#'
#' Dispatches on the style subclass. Each method applies the nodata mask,
#' selects bands, stretches or maps values, applies colors and opacity, and
#' draws onto the active device.
#'
#' @keywords internal
#' @noRd
render_style <- function(style, r, ...) {
  UseMethod("render_style")
}

#' @exportS3Method
#' @keywords internal
#' @noRd
render_style.rstatic_style_categorical <- function(style, r, ...) {
  r <- select_band(r, style$bands)
  r <- mask_nodata(r, style$nodata)

  rgb <- grDevices::col2rgb(style$categories$color, alpha = TRUE)
  alpha <- rgb[4, ]
  if (!is.null(style$opacity)) {
    alpha <- round(alpha * style$opacity)
  }

  coltab <- data.frame(
    value = style$categories$value,
    red = rgb[1, ],
    green = rgb[2, ],
    blue = rgb[3, ],
    alpha = alpha
  )
  terra::coltab(r) <- coltab

  do.call(terra::plot, c(
    list(r, axes = FALSE, legend = FALSE, box = FALSE, mar = c(0, 0, 0, 0)),
    list(...)
  ))
  invisible(NULL)
}

#' @exportS3Method
#' @keywords internal
#' @noRd
render_style.rstatic_style_continuous <- function(style, r, ...) {
  r <- select_band(r, style$bands)
  r <- mask_nodata(r, style$nodata)

  limits <- layer_limits(r, style$min, style$max, style$pmin, style$pmax)
  cols <- style_colors(style$palette, gamma = style$gamma,
                       opacity = style$opacity)

  plot_args <- list(
    r, col = cols, axes = FALSE, legend = FALSE, box = FALSE,
    mar = c(0, 0, 0, 0)
  )
  if (!is.null(limits)) {
    plot_args$range <- limits
  }

  do.call(terra::plot, c(plot_args, list(...)))
  invisible(NULL)
}

#' @exportS3Method
#' @keywords internal
#' @noRd
render_style.rstatic_style_rgb <- function(style, r, ...) {
  r <- select_band(r, style$bands)
  if (terra::nlyr(r) != 3L) {
    stop("RGB styles require a raster with three selected bands.",
         call. = FALSE)
  }
  r <- mask_nodata(r, style$nodata)

  gamma <- style$gamma %||% 1
  scaled <- lapply(seq_len(3L), function(i) {
    layer <- r[[i]]
    lim <- layer_limits(
      layer,
      pick_band(style$min, i),
      pick_band(style$max, i),
      pick_band(style$pmin, i),
      pick_band(style$pmax, i)
    )
    if (is.null(lim)) {
      lim <- as.numeric(terra::global(layer, range, na.rm = TRUE))
    }
    lo <- lim[1]
    hi <- lim[2]
    norm <- (layer - lo) / (hi - lo)
    norm <- terra::clamp(norm, lower = 0, upper = 1, values = TRUE)
    (norm^(1 / gamma)) * 255
  })
  rgb <- terra::rast(scaled)

  rgb_args <- list(
    rgb, r = 1, g = 2, b = 3, scale = 255, stretch = NULL,
    colNA = "transparent", axes = FALSE, mar = c(0, 0, 0, 0)
  )
  if (!is.null(style$opacity)) {
    rgb_args$alpha <- style$opacity
  }
  do.call(terra::plotRGB, c(rgb_args, list(...)))
  invisible(NULL)
}

#' Select one or more bands from a raster by name or index
#'
#' @keywords internal
#' @noRd
select_band <- function(r, bands) {
  if (!is.null(bands)) {
    missing <- setdiff(bands[is.character(bands)], names(r))
    if (length(missing)) {
      stop(sprintf("Band(s) not found in raster: %s",
                   paste(missing, collapse = ", ")), call. = FALSE)
    }
    return(r[[bands]])
  }
  if (terra::nlyr(r) > 1L) {
    return(r[[1]])
  }
  r
}

#' Set nodata pixels to NA so they render as transparent
#'
#' @keywords internal
#' @noRd
mask_nodata <- function(r, nodata) {
  if (is.null(nodata)) {
    return(r)
  }
  terra::subst(r, nodata, NA)
}

#' Resolve the stretch limits for a single layer
#'
#' Returns `c(lo, hi)`, or `NULL` when neither bound can be determined. `min`
#' and `max` take precedence over the percentile bounds `pmin` and `pmax`.
#'
#' @keywords internal
#' @noRd
layer_limits <- function(r, min, max, pmin, pmax) {
  lo <- min
  hi <- max
  if (is.null(lo) && !is.null(pmin)) {
    lo <- as.numeric(terra::global(r, stats::quantile, probs = pmin,
                                   na.rm = TRUE))
  }
  if (is.null(hi) && !is.null(pmax)) {
    hi <- as.numeric(terra::global(r, stats::quantile, probs = pmax,
                                   na.rm = TRUE))
  }
  if (is.null(lo) || is.null(hi)) {
    return(NULL)
  }
  c(lo, hi)
}

#' Pick the band-specific element of a scalar or length-three parameter
#'
#' @keywords internal
#' @noRd
pick_band <- function(x, i) {
  if (is.null(x)) {
    return(NULL)
  }
  if (length(x) == 1L) x else x[i]
}

#' Build a vector of colors for a continuous color ramp
#'
#' Applies an optional gamma correction by sampling the ramp at gamma-spaced
#' positions, and an optional global opacity.
#'
#' @keywords internal
#' @noRd
style_colors <- function(palette, n = 256L, gamma = NULL, opacity = NULL) {
  anchors <- resolve_palette(palette)
  ramp <- grDevices::colorRamp(anchors, space = "Lab")
  p <- seq(0, 1, length.out = n)
  if (!is.null(gamma)) {
    p <- p^(1 / gamma)
  }
  m <- ramp(p)
  alpha <- if (!is.null(opacity)) round(opacity * 255) else 255
  grDevices::rgb(m[, 1], m[, 2], m[, 3], alpha = alpha, maxColorValue = 255)
}

#' Resolve a palette specification into a vector of color anchors
#'
#' A single non-color string is treated as a named palette. Two or more colors
#' are used as ramp anchors. A single color is duplicated into a constant ramp.
#'
#' @keywords internal
#' @noRd
resolve_palette <- function(palette) {
  if (is.null(palette)) {
    palette <- c("black", "white")
  }
  if (length(palette) == 1L && !is_color(palette)) {
    palette <- grDevices::hcl.colors(256L, palette)
  }
  if (length(palette) == 1L) {
    palette <- c(palette, palette)
  }
  palette
}

#' Test whether a string is a valid R color
#'
#' @keywords internal
#' @noRd
is_color <- function(x) {
  tryCatch({
    grDevices::col2rgb(x)
    TRUE
  }, error = function(e) FALSE)
}
