# Render a thumbnail of the given style by saving an item that carries it,
# and return the path to the rendered PNG.
render_thumb <- function(style, item_id, root, href = NULL) {
  if (is.null(href)) {
    href <- system.file("extdata/S2_20LMR_B04_20220630.tif", package = "rstatic")
  }
  item <- new_item(item_id, bbox = c(-50, -10, -49, -9))
  item <- add_asset(item, "thumbnail",
                    new_thumbnail(asset_href = href, width = 40, style = style))
  stac_save(collection = new_collection("col", "Collection", "Desc"),
            items = item, root_dir = root)
  file.path(root, "stac", "collections", "col", "items", item_id,
            "thumbnail.png")
}

test_that("new_thumbnail rejects a non-style object", {
  expect_error(
    new_thumbnail(asset_href = "x.tif", style = list(min = 0)),
    "rstatic_style"
  )
})

test_that("stac_save renders a continuous style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(min = 0, max = 0.5, palette = c("black", "white"))
  expect_true(file.exists(render_thumb(style, "con", root)))
})

test_that("stac_save renders a continuous style with percentile stretch", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(bands = "B04", pmin = 0.02, pmax = 0.98,
                      palette = "viridis", gamma = 1.5, opacity = 0.8)
  expect_true(file.exists(render_thumb(style, "pct", root)))
})

test_that("stac_save renders a categorical style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(
    values = c(0, 1),
    colors = c("#000000", "#ff0000"),
    nodata = 0
  )
  expect_true(file.exists(render_thumb(style, "cat", root)))
})

test_that("stac_save renders an RGB style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()

  rgb_path <- withr::local_tempfile(fileext = ".tif")
  r <- terra::rast(nrows = 20, ncols = 20, nlyr = 3)
  names(r) <- c("R", "G", "B")
  terra::values(r) <- stats::runif(20 * 20 * 3)
  terra::writeRaster(r, rgb_path, overwrite = TRUE)

  style <- stac_style(bands = c("R", "G", "B"), pmin = 0.02, pmax = 0.98,
                      gamma = 1.1)
  expect_true(file.exists(render_thumb(style, "rgb", root, href = rgb_path)))
})

test_that("stac_save errors when an RGB style lacks three bands", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(bands = c("B04", "missing2", "missing3"))
  expect_error(render_thumb(style, "rgb-bad", root), "not found")
})

test_that("stac_save renders a style produced from QML", {
  skip_if_not_installed("terra")
  skip_if_not_installed("xml2")
  root <- withr::local_tempdir()
  qml <- system.file("extdata/example.qml", package = "rstatic")
  skip_if(!nzchar(qml))
  expect_true(file.exists(render_thumb(qml_to_style(qml), "qml", root)))
})
