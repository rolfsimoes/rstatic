#' @title Describe a thumbnail asset
#'
#' @name new_thumbnail
#'
#' @description
#' Pure builder that returns a STAC `Asset` describing a PNG thumbnail to be
#' rendered from a raster. No raster is read and no file is written here: the
#' render *intent* (source raster, width, and style) is carried on the asset and
#' materialized later, when the owning item is written with [stac_save()].
#'
#' `new_thumbnail()` is generic. Pass the source either as a `character` path or
#' URL, or as a `doc_asset` from [new_asset()] -- typically the item's data
#' asset -- in which case the raster is taken from the asset's resolved
#' `local_path` (see [update_root()]) or its `href`.
#'
#' The optional `style` argument controls how raster values are mapped to
#' pixels. Build it with [stac_style()] or [qml_to_style()]. Without a style,
#' the raster is rendered with `terra`'s default settings.
#'
#' Rendering happens at save time and requires the optional \pkg{terra}
#' package. If \pkg{terra} is not available, build the asset manually with
#' [new_asset()] instead.
#'
#' @param x      A `character` path or URL to the source raster, or a `doc_asset`
#'   from [new_asset()] pointing at it.
#' @param width  An `integer` thumbnail width in pixels. Defaults to `800`.
#' @param title  A `character` asset title. Defaults to `"Thumbnail"`.
#' @param style  An optional `rstatic_style` object from [stac_style()]
#'   or [qml_to_style()].
#' @param ...    Additional arguments passed to the underlying `terra`
#'   plotting function at render time.
#'
#' @return A `doc_asset` with `href` `"thumbnail.png"` and roles `"thumbnail"`,
#'   carrying the render intent so [stac_save()] can produce the PNG.
#'
#' @examples
#' f <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.tif",
#'     package = "rstatic"
#' )
#' style <- stac_style(min = 192, max = 1371, palette = c("black", "white"))
#'
#' # Build an item with a data asset, then derive the thumbnail from that asset.
#' item <- new_item(
#'     "item-1",
#'     bbox = c(-50, -10, -49, -9),
#'     assets = list(data = new_asset(f, title = "B04"))
#' )
#' thumb <- new_thumbnail(item$assets$data, style = style)
#' item <- add_asset(item, "thumbnail", thumb)
#'
#' # A plain path or URL works too.
#' new_thumbnail(f, style = style)$roles
#'
#' @export
new_thumbnail <- function(x, ...) {
    UseMethod("new_thumbnail")
}

#' @rdname new_thumbnail
#' @export
new_thumbnail.character <- function(x,
                                    width = 800,
                                    title = "Thumbnail",
                                    style = NULL,
                                    ...) {
    if (!is.null(style) && !inherits(style, "rstatic_style")) {
        stop("`style` must be an `rstatic_style` object from `stac_style()` ",
            "or `qml_to_style()`.",
            call. = FALSE
        )
    }

    asset <- new_asset("thumbnail.png", title = title, roles = list("thumbnail"))
    attr(asset, "thumbnail_spec") <- list(
        source = x,
        width = width,
        style = style,
        args = list(...)
    )
    asset
}

#' @rdname new_thumbnail
#' @export
new_thumbnail.doc_asset <- function(x,
                                    width = 800,
                                    title = "Thumbnail",
                                    style = NULL,
                                    ...) {
    new_thumbnail(.asset_source(x),
        width = width, title = title, style = style,
        ...
    )
}

#' Render a thumbnail intent to a PNG file
#'
#' Materializes the render spec produced by [new_thumbnail()]. Called by
#' [stac_save()] when writing an item; requires \pkg{terra}.
#'
#' @keywords internal
#' @noRd
.render_thumbnail <- function(spec, output_path) {
    if (!requireNamespace("terra", quietly = TRUE)) {
        stop(
            "Package 'terra' is required to render thumbnail assets at save time. ",
            "Install it, or build the asset manually with 'new_asset()'.",
            call. = FALSE
        )
    }

    url <- spec$source
    vsi_url <- url
    if (grepl("^http", url) && !grepl("^/vsicurl/", url)) {
        vsi_url <- paste0("/vsicurl/", url)
    }

    dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)

    r <- suppressWarnings(terra::rast(vsi_url))
    ex <- terra::ext(r)
    aspect_ratio <- (ex[4] - ex[3]) / (ex[2] - ex[1])
    width <- spec$width
    height <- round(width * aspect_ratio)

    if (height > 2000) {
        height <- 2000
        width <- round(height / aspect_ratio)
    }

    grDevices::png(output_path,
        width = width, height = height,
        bg = "transparent"
    )
    on.exit(grDevices::dev.off(), add = TRUE)
    graphics::par(mar = c(0, 0, 0, 0), oma = c(0, 0, 0, 0))

    args <- utils::modifyList(list(fill_range = TRUE), spec$args)
    if (is.null(spec$style)) {
        do.call(.render_default, c(list(r), args))
    } else {
        do.call(render_style, c(list(spec$style, r), args))
    }
    invisible(output_path)
}

#' Render a raster without an explicit style
#'
#' @keywords internal
#' @noRd
.render_default <- function(r, ...) {
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
    r <- .select_band(r, style$bands)
    r <- .mask_nodata(r, style$nodata)

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
    r <- .select_band(r, style$bands)
    r <- .mask_nodata(r, style$nodata)

    limits <- .layer_limits(r, style$min, style$max, style$pmin, style$pmax)
    cols <- .style_colors(style$palette,
        gamma = style$gamma,
        opacity = style$opacity
    )

    plot_args <- list(
        r,
        col = cols, axes = FALSE, legend = FALSE, box = FALSE,
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
    r <- .select_band(r, style$bands)
    if (terra::nlyr(r) != 3L) {
        stop("RGB styles require a raster with three selected bands.",
            call. = FALSE
        )
    }
    r <- .mask_nodata(r, style$nodata)

    gamma <- style$gamma %||% 1
    scaled <- lapply(seq_len(3L), function(i) {
        layer <- r[[i]]
        lim <- .layer_limits(
            layer,
            .pick_band(style$min, i),
            .pick_band(style$max, i),
            .pick_band(style$pmin, i),
            .pick_band(style$pmax, i)
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
        rgb,
        r = 1, g = 2, b = 3, scale = 255, stretch = NULL,
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
.select_band <- function(r, bands) {
    if (!is.null(bands)) {
        missing <- setdiff(bands[is.character(bands)], names(r))
        if (length(missing)) {
            stop(sprintf(
                "Band(s) not found in raster: %s",
                paste(missing, collapse = ", ")
            ), call. = FALSE)
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
.mask_nodata <- function(r, nodata) {
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
.layer_limits <- function(r, min, max, pmin, pmax) {
    lo <- min
    hi <- max
    if (is.null(lo) && !is.null(pmin)) {
        lo <- as.numeric(terra::global(r, stats::quantile,
            probs = pmin,
            na.rm = TRUE
        ))
    }
    if (is.null(hi) && !is.null(pmax)) {
        hi <- as.numeric(terra::global(r, stats::quantile,
            probs = pmax,
            na.rm = TRUE
        ))
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
.pick_band <- function(x, i) {
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
.style_colors <- function(palette, n = 256L, gamma = NULL, opacity = NULL) {
    anchors <- .resolve_palette(palette)
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
.resolve_palette <- function(palette) {
    if (is.null(palette)) {
        palette <- c("black", "white")
    }
    if (length(palette) == 1L && !.is_color(palette)) {
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
.is_color <- function(x) {
    tryCatch(
        {
            grDevices::col2rgb(x)
            TRUE
        },
        error = function(e) FALSE
    )
}
