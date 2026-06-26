test_that("new_catalog builds a valid catalog", {
  cat <- new_catalog("c", "Catalog", "A catalog")
  expect_s3_class(cat, "doc_catalog")
  expect_equal(cat$type, "Catalog")
  expect_equal(cat$id, "c")
  expect_equal(cat$stac_version, "1.0.0")
  expect_true(any(vapply(cat$links, function(l) l$rel == "self", logical(1))))
})

test_that("new_catalog accepts extra fields", {
  cat <- new_catalog("c", "Catalog", "A catalog", keywords = list("a", "b"))
  expect_equal(cat$keywords, list("a", "b"))
})

test_that("new_collection builds a valid collection with default extent", {
  col <- new_collection("col", "Collection", "A collection")
  expect_s3_class(col, "doc_collection")
  expect_equal(col$type, "Collection")
  expect_equal(col$license, "proprietary")
  expect_true(all(is.na(unlist(col$extent$spatial$bbox[[1]]))))
})

test_that("new_asset deduces media type from extension", {
  expect_equal(
    new_asset("data.tif")$type,
    "image/tiff; application=geotiff"
  )
  expect_equal(new_asset("style.qml")$type,
               "application/x-qgis-layer-settings")
  expect_equal(new_asset("x.unknown")$type, "application/octet-stream")
})

test_that("new_properties only keeps provided values", {
  p <- new_properties(datetime = "2020-01-01T00:00:00Z")
  expect_equal(p$datetime, "2020-01-01T00:00:00Z")
  expect_null(p$start_datetime)
})

test_that("new_item builds a Feature and derives geometry from bbox", {
  item <- new_item("i", bbox = c(-50, -10, -49, -9))
  expect_s3_class(item, "doc_item")
  expect_equal(item$type, "Feature")
  expect_equal(item$geometry$type, "Polygon")
})

test_that("new_item merges dots into properties", {
  item <- new_item("i", bbox = c(0, 0, 1, 1), source = "test")
  expect_equal(item$properties$source, "test")
})
