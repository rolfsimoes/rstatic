test_that("extract_bbox returns a WGS84 bounding box", {
  skip_if_not_installed("terra")
  f <- system.file("extdata/S2_20LMR_B04_20220630.tif", package = "rstatic")
  skip_if(!nzchar(f))
  bbox <- extract_bbox(f)
  expect_length(bbox, 4)
  expect_true(bbox[1] < bbox[3])
  expect_true(bbox[2] < bbox[4])
})

test_that("new_thumbnail returns a pure asset carrying a render intent", {
  f <- system.file("extdata/S2_20LMR_B04_20220630.tif", package = "rstatic")
  asset <- new_thumbnail(asset_href = f, width = 100)

  expect_s3_class(asset, "doc_asset")
  expect_equal(asset$href, "thumbnail.png")
  expect_equal(asset$roles, list("thumbnail"))

  spec <- attr(asset, "thumbnail_spec")
  expect_false(is.null(spec))
  expect_equal(spec$source, f)
  expect_equal(spec$width, 100)
})

test_that("stac_save renders a thumbnail intent into the item directory", {
  skip_if_not_installed("terra")
  f <- system.file("extdata/S2_20LMR_B04_20220630.tif", package = "rstatic")
  skip_if(!nzchar(f))
  dir <- withr::local_tempdir()

  item <- new_item("i1", bbox = c(-50, -10, -49, -9))
  item <- add_asset(item, "thumbnail", new_thumbnail(asset_href = f,
                                                     width = 100))
  col <- new_collection("col", "Collection", "Desc")
  stac_save(collection = col, items = item, root_dir = dir)

  expect_true(file.exists(
    file.path(dir, "stac", "collections", "col", "items", "i1",
              "thumbnail.png")
  ))
})

test_that("the thumbnail render intent does not leak into item.json", {
  skip_if_not_installed("terra")
  f <- system.file("extdata/S2_20LMR_B04_20220630.tif", package = "rstatic")
  skip_if(!nzchar(f))
  dir <- withr::local_tempdir()

  item <- new_item("i1", bbox = c(-50, -10, -49, -9))
  item <- add_asset(item, "thumbnail", new_thumbnail(asset_href = f,
                                                     width = 100))
  stac_save(collection = new_collection("col", "C", "D"), items = item,
            root_dir = dir)

  raw <- jsonlite::fromJSON(
    file.path(dir, "stac", "collections", "col", "items", "i1", "item.json"),
    simplifyVector = FALSE
  )
  expect_setequal(names(raw$assets$thumbnail),
                  c("href", "type", "roles", "title"))
})
