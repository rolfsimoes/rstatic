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
  # No temporal field at all: datetime stays absent, not null.
  expect_false("datetime" %in% names(new_properties(description = "x")))
})

test_that("new_properties records a null datetime for a start/end range", {
  p <- new_properties(
    start_datetime = "2022-01-05T00:00:00Z",
    end_datetime = "2022-12-23T00:00:00Z"
  )
  # STAC requires `datetime` to be present, even as null, for ranged items.
  expect_true("datetime" %in% names(p))
  expect_null(p$datetime)
  expect_equal(p$start_datetime, "2022-01-05T00:00:00Z")
  expect_equal(p$end_datetime, "2022-12-23T00:00:00Z")
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

test_that("new_item records the collection id from an id or a doc_collection", {
  # No collection: the field is absent.
  bare <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_null(bare$collection)

  # From a character id.
  from_id <- new_item("i", bbox = c(0, 0, 1, 1), collection = "land-cover")
  expect_equal(from_id$collection, "land-cover")

  # From a doc_collection object.
  col <- new_collection("land-cover", "Land Cover", "Desc")
  from_obj <- new_item("i", bbox = c(0, 0, 1, 1), collection = col)
  expect_equal(from_obj$collection, "land-cover")
})

test_that("new_item rejects an invalid collection", {
  expect_error(
    new_item("i", bbox = c(0, 0, 1, 1), collection = c("a", "b")),
    "collection"
  )
})
