test_that("plot.doc_asset() renders a local PNG asset", {
  skip_if_not_installed("png")

  temp_png <- withr::local_tempfile(fileext = ".png")
  png::writePNG(array(0, dim = c(10, 10, 3)), temp_png)

  asset <- new_asset("thumb.png", title = "thumb", roles = list("thumbnail"))
  attr(asset, "local_path") <- temp_png

  expect_invisible(plot(asset))
})

test_that("new_thumbnail() attaches a local_path attribute", {
  skip_if_not_installed("terra")

  root <- withr::local_tempdir()
  thumb <- new_thumbnail(
    collection_id = "col",
    item_id = "item",
    asset_href = system.file("extdata/example.tif", package = "rstatic"),
    width = 20,
    root_dir = root
  )

  expect_true(inherits(thumb, "doc_asset"))
  expect_true(file.exists(attr(thumb, "local_path")))
  expect_equal(basename(attr(thumb, "local_path")), "thumbnail.png")
})
