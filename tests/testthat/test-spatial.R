test_that("extract_bbox returns a WGS84 bounding box", {
  skip_if_not_installed("terra")
  f <- system.file("extdata/example.tif", package = "rstatic")
  skip_if(!nzchar(f))
  bbox <- extract_bbox(f)
  expect_length(bbox, 4)
  expect_true(bbox[1] < bbox[3])
  expect_true(bbox[2] < bbox[4])
})

test_that("new_thumbnail writes a PNG and returns a thumbnail asset", {
  skip_if_not_installed("terra")
  f <- system.file("extdata/example.tif", package = "rstatic")
  skip_if(!nzchar(f))
  dir <- withr::local_tempdir()
  asset <- new_thumbnail(
    collection_id = "col",
    item_id = "i1",
    asset_href = f,
    width = 100,
    root_dir = dir
  )
  expect_equal(asset$roles, list("thumbnail"))
  expect_true(file.exists(
    file.path(dir, "stac", "collections", "col", "items", "i1",
              "thumbnail.png")
  ))
})
