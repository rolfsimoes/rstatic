#' @title STAC style objects for thumbnails
#'
#' @name style_functions
#'
#' @description
#' Helpers to describe how a raster should be rendered into a thumbnail.
#'
#' \itemize{
#'   \item `stac_style()`: builds a style object from explicit parameters.
#'     This function has no external dependencies.
#'   \item `qml_to_style()`: parses a QGIS Layer Style file (`.qml`) into a
#'     style object. This function requires the optional \pkg{xml2} package.
#' }
#'
#' If \pkg{xml2} is not installed, build the style manually with `stac_style()`
#' instead of reading a `.qml` file.
#'
#' @param min     Minimum value for stretching or color mapping.
#' @param max     Maximum value for stretching or color mapping.
#' @param pmin    Percentile minimum for stretching (e.g. `0.02`).
#' @param pmax    Percentile maximum for stretching (e.g. `0.98`).
#' @param palette Color palette name or a vector of colors.
#' @param legend  A `data.frame` with `value` and `color` columns for
#'   categorical data.
#' @param qml_path A `character` path or URL to a QGIS `.qml` style file.
#'
#' @return A `list` with style parameters: a `categorical`, `continuous`, or
#'   `simple` style depending on the inputs.
#'
#' @examples
#' # Build a style directly (no optional dependency required)
#' stac_style(min = 0, max = 255, palette = c("black", "white"))
#'
#' # Parse a QML file (requires xml2)
#' if (requireNamespace("xml2", quietly = TRUE)) {
#'   qml <- system.file("extdata/example.qml", package = "rstatic")
#'   if (nzchar(qml)) {
#'     qml_to_style(qml)
#'   }
#' }
NULL

#' @rdname style_functions
#' @export
stac_style <- function(min = NULL,
                       max = NULL,
                       pmin = NULL,
                       pmax = NULL,
                       palette = NULL,
                       legend = NULL) {
  if (!is.null(legend)) {
    return(list(type = "categorical", legend = legend))
  }

  if (!is.null(pmin) || !is.null(pmax)) {
    return(list(
      type = "continuous",
      min = min,
      max = max,
      pmin = pmin,
      pmax = pmax,
      palette = palette
    ))
  }

  list(type = "simple", min = min, max = max, palette = palette)
}

#' @rdname style_functions
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

  doc <- xml2::read_xml(qml_path)

  min_val <- as.numeric(xml2::xml_text(
    xml2::xml_find_first(doc, "//minMaxOrigin/min")
  ))
  max_val <- as.numeric(xml2::xml_text(
    xml2::xml_find_first(doc, "//minMaxOrigin/max")
  ))

  pmin <- as.numeric(xml2::xml_text(
    xml2::xml_find_first(doc, "//cumulativeCutLower")
  ))
  pmax <- as.numeric(xml2::xml_text(
    xml2::xml_find_first(doc, "//cumulativeCutUpper")
  ))

  palette_entries <- xml2::xml_find_all(doc, "//paletteEntry")
  legend <- NULL

  if (length(palette_entries) > 0) {
    values <- as.numeric(xml2::xml_attr(palette_entries, "value"))
    colors <- xml2::xml_attr(palette_entries, "color")
    alphas <- as.numeric(xml2::xml_attr(palette_entries, "alpha"))

    if (!all(is.na(alphas))) {
      alphas[is.na(alphas)] <- 255
      colors <- paste0(colors, sprintf("%02X", alphas))
    }

    legend <- data.frame(value = values, color = colors)
  }

  stac_style(
    min = min_val,
    max = max_val,
    pmin = pmin,
    pmax = pmax,
    legend = legend
  )
}
