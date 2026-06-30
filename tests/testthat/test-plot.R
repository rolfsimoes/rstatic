test_that("plot.doc_asset() renders a local PNG asset", {
  skip_if_not_installed("png")

  temp_png <- withr::local_tempfile(fileext = ".png")
  png::writePNG(array(0, dim = c(10, 10, 3)), temp_png)

  asset <- new_asset("thumb.png", title = "thumb", roles = list("thumbnail"))
  attr(asset, "local_path") <- temp_png

  expect_invisible(plot(asset))
})

test_that("a saved thumbnail PNG can be plotted via its path", {
  skip_if_not_installed("terra")
  skip_if_not_installed("png")

  root <- withr::local_tempdir()
  f <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.tif", package = "rstatic")
  skip_if(!nzchar(f))

  item <- new_item("item", bbox = c(-50, -10, -49, -9))
  item <- add_asset(item, "thumbnail", new_thumbnail(f,
                                                     width = 20))
  stac_save(collection = new_collection("col", "C", "D"), items = item,
            root_dir = root)

  png_path <- file.path(root, "stac", "collections", "col", "items", "item",
                        "thumbnail.png")
  expect_true(file.exists(png_path))

  asset <- new_asset(png_path, title = "thumb", roles = list("thumbnail"))
  expect_invisible(plot(asset))
})
