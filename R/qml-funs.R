#' @title Convert a QGIS QML raster style to a thumbnail style
#'
#' @name qml_to_style
#'
#' @description
#' `qml_to_style()` reads a supported QGIS `.qml` raster style and converts it
#' to the same normalized style object produced by [stac_style()].
#'
#' This function supports a limited subset of QGIS raster renderers: paletted,
#' single-band gray, and single-band pseudocolor. Other renderers are rejected
#' with a clear error.
#'
#' The function is a converter, not a general QML parser. QGIS-specific details
#' are normalized to the `rstatic` style model. It requires the optional
#' \pkg{xml2} package; if \pkg{xml2} is not installed, build the style manually
#' with [stac_style()].
#'
#' @param qml_path A `character` path or URL to a QGIS `.qml` file.
#'
#' @return
#' A normalized `rstatic_style` object, as produced by [stac_style()].
#'
#' @examples
#' if (requireNamespace("xml2", quietly = TRUE)) {
#'   qml <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.qml",
#'                       package = "rstatic")
#'   if (nzchar(qml)) {
#'     qml_to_style(qml)
#'   }
#' }
#'
#' @export
qml_to_style <- function(qml_path) {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop(
      "Package 'xml2' is required by 'qml_to_style()'. ",
      "Install it, or build the style manually with 'stac_style()'.",
      call. = FALSE
    )
  }

  is_url <- grepl("^http", qml_path)
  if (!is_url && !file.exists(qml_path)) {
    stop(glue::glue("QML file not found: {qml_path}"), call. = FALSE)
  }

  qml <- xml2::read_xml(qml_path)
  renderer <- qml_renderer_type(qml)

  switch(
    renderer,
    paletted = qml_paletted_to_style(qml),
    singlebandgray = qml_gray_to_style(qml),
    singlebandpseudocolor = qml_pseudocolor_to_style(qml),
    stop("Unsupported QML raster renderer: ", renderer, call. = FALSE)
  )
}

#' Detect the raster renderer type of a QML document
#'
#' @keywords internal
#' @noRd
qml_renderer_type <- function(qml) {
  renderer <- xml2::xml_find_first(qml, "//rasterrenderer")
  if (inherits(renderer, "xml_missing")) {
    stop("No raster renderer found in QML file.", call. = FALSE)
  }
  xml2::xml_attr(renderer, "type")
}

#' Extract a single nodata value from a QML document
#'
#' Supports only a single fully transparent pixel value. Multiple transparent
#' values, value ranges, and partial alpha fail clearly.
#'
#' @keywords internal
#' @noRd
qml_nodata <- function(qml) {
  entries <- xml2::xml_find_all(qml, "//rastertransparency//pixelListEntry")
  if (length(entries) == 0L) {
    return(NULL)
  }
  if (length(entries) > 1L) {
    stop(
      "QML transparency rules are not supported except for a single ",
      "nodata value.",
      call. = FALSE
    )
  }

  min_val <- as.numeric(xml2::xml_attr(entries, "min"))
  max_val <- as.numeric(xml2::xml_attr(entries, "max"))
  pct <- as.numeric(xml2::xml_attr(entries, "percentTransparent"))

  if (!is.na(min_val) && !is.na(max_val) && min_val != max_val) {
    stop(
      "QML transparency rules are not supported except for a single ",
      "nodata value.",
      call. = FALSE
    )
  }
  if (!is.na(pct) && pct != 100) {
    stop(
      "QML transparency rules are not supported except for a single ",
      "nodata value.",
      call. = FALSE
    )
  }

  min_val
}

#' Convert a QML paletted renderer to a categorical style
#'
#' @keywords internal
#' @noRd
qml_paletted_to_style <- function(qml) {
  entries <- xml2::xml_find_all(qml, "//paletteEntry")
  if (length(entries) == 0L) {
    stop("QML paletted renderer has no palette entries.", call. = FALSE)
  }

  values <- as.numeric(xml2::xml_attr(entries, "value"))
  colors <- xml2::xml_attr(entries, "color")
  labels <- xml2::xml_attr(entries, "label")
  alphas <- as.numeric(xml2::xml_attr(entries, "alpha"))

  if (any(!is.na(alphas) & alphas < 255)) {
    stop("QML palette entries with per-class alpha are not supported.",
         call. = FALSE)
  }

  if (all(is.na(labels) | !nzchar(labels))) {
    labels <- NULL
  }

  stac_style(
    values = values,
    colors = colors,
    labels = labels,
    nodata = qml_nodata(qml)
  )
}

#' Convert a QML single-band gray renderer to a continuous style
#'
#' @keywords internal
#' @noRd
qml_gray_to_style <- function(qml) {
  renderer <- xml2::xml_find_first(qml, "//rasterrenderer")

  min_val <- qml_numeric(qml, "//rasterrenderer/contrastEnhancement/minValue")
  max_val <- qml_numeric(qml, "//rasterrenderer/contrastEnhancement/maxValue")

  gradient <- xml2::xml_attr(renderer, "gradient")
  palette <- if (identical(gradient, "WhiteToBlack")) {
    c("white", "black")
  } else {
    c("black", "white")
  }

  stac_style(
    min = min_val,
    max = max_val,
    palette = palette,
    nodata = qml_nodata(qml),
    gamma = qml_gamma(qml)
  )
}

#' Convert a QML single-band pseudocolor renderer to a continuous style
#'
#' @keywords internal
#' @noRd
qml_pseudocolor_to_style <- function(qml) {
  renderer <- xml2::xml_find_first(qml, "//rasterrenderer")
  shader <- xml2::xml_find_first(qml, "//colorrampshader")

  ramp_type <- xml2::xml_attr(shader, "colorRampType")
  if (!is.na(ramp_type) && toupper(ramp_type) == "DISCRETE") {
    stop(
      "QML pseudocolor styles with discrete interpolation are not supported.",
      call. = FALSE
    )
  }

  items <- xml2::xml_find_all(qml, "//colorrampshader/item")
  if (length(items) == 0L) {
    stop("QML pseudocolor renderer has no color ramp items.", call. = FALSE)
  }

  values <- as.numeric(xml2::xml_attr(items, "value"))
  colors <- xml2::xml_attr(items, "color")
  palette <- colors[order(values)]

  min_val <- as.numeric(xml2::xml_attr(renderer, "classificationMin"))
  max_val <- as.numeric(xml2::xml_attr(renderer, "classificationMax"))
  if (is.na(min_val)) min_val <- min(values)
  if (is.na(max_val)) max_val <- max(values)

  stac_style(
    min = min_val,
    max = max_val,
    palette = palette,
    nodata = qml_nodata(qml)
  )
}

#' Read a single numeric value from a QML node, returning NULL when absent
#'
#' @keywords internal
#' @noRd
qml_numeric <- function(qml, xpath) {
  node <- xml2::xml_find_first(qml, xpath)
  if (inherits(node, "xml_missing")) {
    return(NULL)
  }
  value <- suppressWarnings(as.numeric(xml2::xml_text(node)))
  if (is.na(value)) NULL else value
}

#' Read the gamma value from a QML brightness/contrast block
#'
#' Returns NULL when gamma is absent or equal to 1 (no correction).
#'
#' @keywords internal
#' @noRd
qml_gamma <- function(qml) {
  node <- xml2::xml_find_first(qml, "//brightnesscontrast")
  if (inherits(node, "xml_missing")) {
    return(NULL)
  }
  gamma <- suppressWarnings(as.numeric(xml2::xml_attr(node, "gamma")))
  if (is.na(gamma) || gamma == 1) NULL else gamma
}
