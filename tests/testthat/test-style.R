test_that("stac_style infers categorical, continuous, and RGB modes", {
  s_cat <- stac_style(
    values = c(1, 2, 3),
    colors = c("#c14d00", "#367906", "#7cc900"),
    labels = c("Crop", "Forest", "Grass")
  )
  expect_s3_class(s_cat, "rstatic_style")
  expect_s3_class(s_cat, "rstatic_style_categorical")
  expect_equal(s_cat$mode, "categorical")
  expect_equal(nrow(s_cat$categories), 3)
  expect_equal(s_cat$categories$value, c(1, 2, 3))

  s_con <- stac_style(min = 0, max = 0.5, palette = c("black", "white"))
  expect_s3_class(s_con, "rstatic_style_continuous")
  expect_equal(s_con$mode, "continuous")

  s_rgb <- stac_style(bands = c("B4", "B3", "B2"), pmin = 0.02, pmax = 0.98)
  expect_s3_class(s_rgb, "rstatic_style_rgb")
  expect_equal(s_rgb$mode, "rgb")
})

test_that("categorical labels default to the character form of values", {
  s <- stac_style(values = c(10, 20), colors = c("#000000", "#ffffff"))
  expect_equal(s$categories$label, c("10", "20"))
})

test_that("stac_style validates parameter combinations", {
  expect_error(
    stac_style(values = 1:2, colors = "red"),
    "same length"
  )
  expect_error(
    stac_style(values = 1, colors = "red", min = 0),
    "must not be used with"
  )
  expect_error(
    stac_style(values = 1, colors = "red", palette = "viridis"),
    "palette"
  )
  expect_error(
    stac_style(values = 1, colors = "red", gamma = 2),
    "gamma"
  )
  expect_error(
    stac_style(colors = "red"),
    "supplied together"
  )
  expect_error(
    stac_style(min = c(0, 0, 0)),
    "length three"
  )
  expect_error(
    stac_style(bands = c("a", "b")),
    "length one, or length three"
  )
  expect_error(
    stac_style(opacity = 2),
    "between 0 and 1"
  )
})

test_that("length-three stretch is allowed only with three bands", {
  expect_s3_class(
    stac_style(bands = c("a", "b", "c"), min = c(0, 0, 0), max = c(1, 1, 1)),
    "rstatic_style_rgb"
  )
  expect_error(
    stac_style(bands = "a", min = c(0, 0, 0)),
    "length three"
  )
})

test_that("print.rstatic_style summarizes the style", {
  expect_output(
    print(stac_style(min = 0, max = 1, palette = c("black", "white"))),
    "continuous"
  )
  expect_output(
    print(stac_style(values = 1, colors = "red")),
    "categorical"
  )
})

test_that("qml_to_style errors clearly when xml2 is missing", {
  testthat::skip_if(requireNamespace("xml2", quietly = TRUE))
  expect_error(qml_to_style("x.qml"), "xml2")
})

test_that("qml_to_style converts singlebandpseudocolor to a continuous style", {
  skip_if_not_installed("xml2")
  qml <- system.file("extdata/example.qml", package = "rstatic")
  skip_if(!nzchar(qml))

  style <- qml_to_style(qml)
  expect_s3_class(style, "rstatic_style_continuous")
  expect_equal(style$min, 0.012)
  expect_equal(style$max, 0.296)
  expect_type(style$palette, "character")
  expect_true(length(style$palette) > 0)
  expect_match(style$palette[1], "^#")
})

test_that("qml_to_style converts a paletted renderer to a categorical style", {
  skip_if_not_installed("xml2")
  path <- withr::local_tempfile(fileext = ".qml")
  writeLines(
    c(
      "<qgis>",
      "  <pipe>",
      "    <rasterrenderer type='paletted' band='1'>",
      "      <colorPalette>",
      "        <paletteEntry value='1' color='#c14d00' label='Crop' alpha='255'/>",
      "        <paletteEntry value='2' color='#367906' label='Forest' alpha='255'/>",
      "      </colorPalette>",
      "    </rasterrenderer>",
      "  </pipe>",
      "</qgis>"
    ),
    path
  )

  style <- qml_to_style(path)
  expect_s3_class(style, "rstatic_style_categorical")
  expect_equal(style$categories$value, c(1, 2))
  expect_equal(style$categories$color, c("#c14d00", "#367906"))
  expect_equal(style$categories$label, c("Crop", "Forest"))
})

test_that("qml_to_style rejects paletted styles with per-class alpha", {
  skip_if_not_installed("xml2")
  path <- withr::local_tempfile(fileext = ".qml")
  writeLines(
    c(
      "<qgis><pipe><rasterrenderer type='paletted' band='1'>",
      "<paletteEntry value='1' color='#c14d00' label='Crop' alpha='128'/>",
      "</rasterrenderer></pipe></qgis>"
    ),
    path
  )
  expect_error(qml_to_style(path), "per-class alpha")
})

test_that("qml_to_style rejects discrete pseudocolor interpolation", {
  skip_if_not_installed("xml2")
  path <- withr::local_tempfile(fileext = ".qml")
  writeLines(
    c(
      "<qgis><pipe>",
      "<rasterrenderer type='singlebandpseudocolor' band='1'",
      "  classificationMin='0' classificationMax='1'>",
      "  <rastershader><colorrampshader colorRampType='DISCRETE'>",
      "    <item value='0' color='#000000'/>",
      "    <item value='1' color='#ffffff'/>",
      "  </colorrampshader></rastershader>",
      "</rasterrenderer></pipe></qgis>"
    ),
    path
  )
  expect_error(qml_to_style(path), "discrete interpolation")
})

test_that("qml_to_style converts singlebandgray to a grayscale continuous style", {
  skip_if_not_installed("xml2")
  path <- withr::local_tempfile(fileext = ".qml")
  writeLines(
    c(
      "<qgis><pipe>",
      "<rasterrenderer type='singlebandgray' band='1' gradient='BlackToWhite'>",
      "  <contrastEnhancement><minValue>0</minValue><maxValue>255</maxValue>",
      "  </contrastEnhancement>",
      "</rasterrenderer>",
      "<brightnesscontrast gamma='1'/>",
      "</pipe></qgis>"
    ),
    path
  )
  style <- qml_to_style(path)
  expect_s3_class(style, "rstatic_style_continuous")
  expect_equal(style$min, 0)
  expect_equal(style$max, 255)
  expect_equal(style$palette, c("black", "white"))
  expect_null(style$gamma)
})

test_that("qml_to_style rejects unsupported renderers", {
  skip_if_not_installed("xml2")
  path <- withr::local_tempfile(fileext = ".qml")
  writeLines(
    "<qgis><pipe><rasterrenderer type='multibandcolor'/></pipe></qgis>",
    path
  )
  expect_error(qml_to_style(path), "Unsupported QML raster renderer")
})
