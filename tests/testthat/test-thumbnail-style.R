make_thumb <- function(style, item_id, root, href = NULL) {
  if (is.null(href)) {
    href <- system.file("extdata/example.tif", package = "rstatic")
  }
  new_thumbnail(
    collection_id = "col",
    item_id = item_id,
    asset_href = href,
    width = 40,
    style = style,
    root_dir = root
  )
}

test_that("new_thumbnail rejects a non-style object", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  expect_error(
    new_thumbnail("col", "item", asset_href = "x.tif",
                  style = list(min = 0), root_dir = root),
    "rstatic_style"
  )
})

test_that("new_thumbnail renders a continuous style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(min = 0, max = 0.5, palette = c("black", "white"))
  thumb <- make_thumb(style, "con", root)
  expect_true(file.exists(attr(thumb, "local_path")))
})

test_that("new_thumbnail renders a continuous style with percentile stretch", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(bands = "B04", pmin = 0.02, pmax = 0.98,
                      palette = "viridis", gamma = 1.5, opacity = 0.8)
  thumb <- make_thumb(style, "pct", root)
  expect_true(file.exists(attr(thumb, "local_path")))
})

test_that("new_thumbnail renders a categorical style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(
    values = c(0, 1),
    colors = c("#000000", "#ff0000"),
    nodata = 0
  )
  thumb <- make_thumb(style, "cat", root)
  expect_true(file.exists(attr(thumb, "local_path")))
})

test_that("new_thumbnail renders an RGB style", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()

  rgb_path <- withr::local_tempfile(fileext = ".tif")
  r <- terra::rast(nrows = 20, ncols = 20, nlyr = 3)
  names(r) <- c("R", "G", "B")
  terra::values(r) <- stats::runif(20 * 20 * 3)
  terra::writeRaster(r, rgb_path, overwrite = TRUE)

  style <- stac_style(bands = c("R", "G", "B"), pmin = 0.02, pmax = 0.98,
                      gamma = 1.1)
  thumb <- make_thumb(style, "rgb", root, href = rgb_path)
  expect_true(file.exists(attr(thumb, "local_path")))
})

test_that("new_thumbnail errors when an RGB style lacks three bands", {
  skip_if_not_installed("terra")
  root <- withr::local_tempdir()
  style <- stac_style(bands = c("B04", "missing2", "missing3"))
  expect_error(make_thumb(style, "rgb-bad", root), "not found")
})

test_that("new_thumbnail renders a style produced from QML", {
  skip_if_not_installed("terra")
  skip_if_not_installed("xml2")
  root <- withr::local_tempdir()
  qml <- system.file("extdata/example.qml", package = "rstatic")
  skip_if(!nzchar(qml))
  thumb <- make_thumb(qml_to_style(qml), "qml", root)
  expect_true(file.exists(attr(thumb, "local_path")))
})
