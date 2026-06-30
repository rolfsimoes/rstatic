#' @title Define a raster style for thumbnail rendering
#'
#' @name stac_style
#'
#' @description
#' `stac_style()` creates a normalized style object used by [new_thumbnail()]
#' to render raster previews. The style describes how raster values are mapped
#' to thumbnail pixels. It does not render the image.
#'
#' Continuous styles use `min`/`max` or `pmin`/`pmax`, optionally with a color
#' ramp supplied by `palette`. RGB rendering is represented by passing three
#' band names to `bands`.
#'
#' Categorical styles use explicit `values` and `colors` mappings. Values do
#' not need to be sequential. Optional `labels` describe the categorical values
#' and may be used to derive legends.
#'
#' `nodata` is applied before any rendering rule and is rendered as transparent.
#'
#' @param bands   Optional band name or vector of three band names. Three bands
#'   indicate RGB rendering.
#' @param min     Minimum value used for continuous stretching. Must have length
#'   one or three. Length three is only allowed when `bands` has length three.
#' @param max     Maximum value used for continuous stretching. Must have length
#'   one or three. Length three is only allowed when `bands` has length three.
#' @param pmin    Lower percentile used to derive the stretch minimum from the
#'   image. Must have length one or three. Length three is only allowed when
#'   `bands` has length three.
#' @param pmax    Upper percentile used to derive the stretch maximum from the
#'   image. Must have length one or three. Length three is only allowed when
#'   `bands` has length three.
#' @param palette Color ramp for continuous single-band rendering. It can be a
#'   known palette name or a vector of colors.
#' @param values  Raster values for categorical rendering.
#' @param colors  Colors associated with `values`.
#' @param labels  Optional labels associated with `values`. Defaults to
#'   `as.character(values)`.
#' @param nodata  Optional value to render as transparent. It is applied before
#'   all other rendering rules.
#' @param opacity Optional global opacity between `0` and `1` for valid pixels.
#' @param gamma   Optional gamma correction for continuous rendering. It must
#'   not be used with categorical styles.
#'
#' @return
#' A normalized `rstatic_style` object. The object also carries a mode-specific
#' subclass: `rstatic_style_categorical`, `rstatic_style_continuous`, or
#' `rstatic_style_rgb`.
#'
#' @examples
#' # Continuous grayscale stretch
#' stac_style(min = 0, max = 0.5, palette = c("black", "white"))
#'
#' # Single-band percentile stretch
#' stac_style(bands = "B04", pmin = 0.02, pmax = 0.98, palette = "viridis")
#'
#' # RGB composite from three bands
#' stac_style(bands = c("B04", "B03", "B02"), pmin = 0.02, pmax = 0.98)
#'
#' # Categorical land-cover mapping
#' stac_style(
#'   values = c(1, 2, 3),
#'   colors = c("#c14d00", "#367906", "#7cc900"),
#'   labels = c("Crop", "Forest", "Grassland"),
#'   nodata = 0
#' )
#'
#' @export
stac_style <- function(bands = NULL,
                       min = NULL,
                       max = NULL,
                       pmin = NULL,
                       pmax = NULL,
                       palette = NULL,
                       values = NULL,
                       colors = NULL,
                       labels = NULL,
                       nodata = NULL,
                       opacity = NULL,
                       gamma = NULL) {
  mode <- style_mode(bands, values, colors, labels)

  validate_style_inputs(
    mode = mode,
    bands = bands,
    min = min,
    max = max,
    pmin = pmin,
    pmax = pmax,
    palette = palette,
    values = values,
    colors = colors,
    labels = labels,
    nodata = nodata,
    opacity = opacity,
    gamma = gamma
  )

  style <- switch(
    mode,
    categorical = new_style_categorical(
      bands = bands,
      values = values,
      colors = colors,
      labels = labels,
      nodata = nodata,
      opacity = opacity
    ),
    rgb = new_style_rgb(
      bands = bands,
      min = min,
      max = max,
      pmin = pmin,
      pmax = pmax,
      nodata = nodata,
      opacity = opacity,
      gamma = gamma
    ),
    continuous = new_style_continuous(
      bands = bands,
      min = min,
      max = max,
      pmin = pmin,
      pmax = pmax,
      palette = palette,
      nodata = nodata,
      opacity = opacity,
      gamma = gamma
    )
  )

  structure(style, class = c("rstatic_style", paste0("rstatic_style_", mode)))
}

#' Infer the rendering mode of a style
#'
#' @keywords internal
#' @noRd
style_mode <- function(bands, values, colors, labels) {
  if (!is.null(values) || !is.null(colors) || !is.null(labels)) {
    "categorical"
  } else if (!is.null(bands) && length(bands) == 3L) {
    "rgb"
  } else {
    "continuous"
  }
}

#' Validate the parameter combination supplied to `stac_style()`
#'
#' @keywords internal
#' @noRd
validate_style_inputs <- function(mode, bands, min, max, pmin, pmax, palette,
                                  values, colors, labels, nodata, opacity,
                                  gamma) {
  if (!is.null(bands) && !length(bands) %in% c(1L, 3L)) {
    stop("`bands` must be NULL, length one, or length three.", call. = FALSE)
  }

  stretch <- list(min = min, max = max, pmin = pmin, pmax = pmax)
  for (nm in names(stretch)) {
    v <- stretch[[nm]]
    if (is.null(v)) next
    if (!length(v) %in% c(1L, 3L)) {
      stop(sprintf("`%s` must be NULL, length one, or length three.", nm),
           call. = FALSE)
    }
    if (length(v) == 3L && (is.null(bands) || length(bands) != 3L)) {
      stop(sprintf(
        "`%s` may have length three only when `bands` has length three.", nm),
        call. = FALSE)
    }
  }

  if (!is.null(opacity)) {
    if (length(opacity) != 1L || !is.numeric(opacity) ||
        opacity < 0 || opacity > 1) {
      stop("`opacity` must be a single numeric value between 0 and 1.",
           call. = FALSE)
    }
  }

  if (mode == "categorical") {
    if (!is.null(min) || !is.null(max) || !is.null(pmin) || !is.null(pmax)) {
      stop("`min`, `max`, `pmin`, and `pmax` must not be used with `values`.",
           call. = FALSE)
    }
    if (!is.null(palette)) {
      stop("`palette` must not be used with `values`. ",
           "Use `colors` for categorical rendering.", call. = FALSE)
    }
    if (!is.null(gamma)) {
      stop("`gamma` must not be used with categorical styles.", call. = FALSE)
    }
    if (is.null(values) || is.null(colors)) {
      stop("`values` and `colors` must be supplied together.", call. = FALSE)
    }
    if (length(values) != length(colors)) {
      stop("`values` and `colors` must have the same length.", call. = FALSE)
    }
    if (!is.null(labels) && length(labels) != length(values)) {
      stop("`labels` must have the same length as `values`.", call. = FALSE)
    }
  }

  invisible(TRUE)
}

#' Build the categorical style representation
#'
#' @keywords internal
#' @noRd
new_style_categorical <- function(bands, values, colors, labels, nodata,
                                  opacity) {
  if (is.null(labels)) {
    labels <- as.character(values)
  }
  list(
    mode = "categorical",
    bands = bands,
    categories = data.frame(
      value = values,
      color = colors,
      label = labels,
      stringsAsFactors = FALSE
    ),
    nodata = nodata,
    opacity = opacity
  )
}

#' Build the continuous single-band style representation
#'
#' @keywords internal
#' @noRd
new_style_continuous <- function(bands, min, max, pmin, pmax, palette, nodata,
                                 opacity, gamma) {
  list(
    mode = "continuous",
    bands = bands,
    min = min,
    max = max,
    pmin = pmin,
    pmax = pmax,
    palette = palette,
    nodata = nodata,
    opacity = opacity,
    gamma = gamma
  )
}

#' Build the RGB style representation
#'
#' @keywords internal
#' @noRd
new_style_rgb <- function(bands, min, max, pmin, pmax, nodata, opacity, gamma) {
  list(
    mode = "rgb",
    bands = bands,
    min = min,
    max = max,
    pmin = pmin,
    pmax = pmax,
    nodata = nodata,
    opacity = opacity,
    gamma = gamma
  )
}

#' @title Print a raster style object
#'
#' @description
#' Prints a compact summary of an `rstatic_style` object, including its
#' rendering mode and the parameters relevant to that mode.
#'
#' @param x   An `rstatic_style` object from [stac_style()] or [qml_to_style()].
#' @param ... Ignored.
#'
#' @return Invisibly, `x`.
#'
#' @examples
#' print(stac_style(min = 0, max = 1, palette = c("black", "white")))
#'
#' @export
print.rstatic_style <- function(x, ...) {
  .print_header("Style", x$mode)
  fields <- list(bands = x$bands)
  if (identical(x$mode, "categorical")) {
    labs <- x$categories$label
    if (is.null(labs) || all(is.na(labs))) {
      labs <- x$categories$value
    }
    joined <- paste(labs, collapse = ", ")
    if (nchar(joined) > 70L) {
      joined <- sprintf(
        "%s... (%d)",
        sub(",?\\s*$", "", substr(joined, 1L, 70L)),
        length(labs)
      )
    }
    fields$labels <- joined
  } else {
    stretch <- c(
      if (!is.null(x$min)) sprintf("min=%s", format(x$min)),
      if (!is.null(x$max)) sprintf("max=%s", format(x$max)),
      if (!is.null(x$pmin)) sprintf("pmin=%s", format(x$pmin)),
      if (!is.null(x$pmax)) sprintf("pmax=%s", format(x$pmax))
    )
    fields$stretch <- if (length(stretch)) paste(stretch, collapse = ", ")
    if (!is.null(x$palette)) {
      fields$palette <- if (length(x$palette) > 6L) {
        sprintf("%s, ... (%d colors)",
                paste(utils::head(x$palette, 4L), collapse = ", "),
                length(x$palette))
      } else {
        paste(x$palette, collapse = ", ")
      }
    }
    fields$gamma <- x$gamma
  }
  fields$nodata <- x$nodata
  fields$opacity <- x$opacity
  .print_fields(fields)
  invisible(x)
}
