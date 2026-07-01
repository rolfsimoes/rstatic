test_that("new_asset returns a doc_asset object", {
  asset <- new_asset("data.tif", title = "Data")
  expect_s3_class(asset, "doc_asset")
})

test_that("item links are classed as doc_links and each link as doc_link", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_s3_class(item$links, "doc_links")
  expect_true(all(vapply(
    item$links,
    function(l) inherits(l, "doc_link"),
    logical(1)
  )))
})

test_that("item assets are classed as doc_asset", {
  item <- new_item(
    "i",
    bbox = c(0, 0, 1, 1),
    assets = list(data = new_asset("data.tif"))
  )
  expect_s3_class(item$assets$data, "doc_asset")
})

test_that("add_asset keeps assets classed as doc_asset", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  item <- add_asset(item, "data", new_asset("data.tif"))
  expect_s3_class(item$assets$data, "doc_asset")
})

test_that("add_link keeps links classed as doc_links/doc_link", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- add_link(cat, "child", "x.json")
  expect_s3_class(cat$links, "doc_links")
  expect_s3_class(cat$links[[length(cat$links)]], "doc_link")
})

test_that("print methods dispatch and return their input invisibly", {
  withr::local_options(cli.num_colors = 1)

  asset <- new_asset("data.tif", title = "Data")
  expect_output(print(asset), "STAC Asset")
  # Suppress output to check visibility
  invisible(capture.output(
    result <- withVisible(print(asset))
  ))
  expect_identical(result$visible, FALSE)

  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_output(print(item$links), "STAC Links")
  expect_output(print(item$links[[1]]), "STAC Link")
})

test_that("print.doc_item shows a datetime, preferring a start/end range", {
  withr::local_options(cli.num_colors = 1)

  single <- new_item(
    "i", bbox = c(0, 0, 1, 1),
    properties = new_properties(datetime = "2022-07-16T00:00:00Z")
  )
  expect_output(print(single), "datetime: 2022-07-16T00:00:00Z")

  # A start/end range is shown, and takes precedence when datetime is also set.
  ranged <- new_item(
    "i", bbox = c(0, 0, 1, 1),
    properties = new_properties(
      datetime = "2022-07-16T00:00:00Z",
      start_datetime = "2022-01-05T00:00:00Z",
      end_datetime = "2022-12-23T00:00:00Z"
    )
  )
  expect_output(
    print(ranged),
    "datetime: 2022-01-05T00:00:00Z / 2022-12-23T00:00:00Z",
    fixed = TRUE
  )
})

test_that("print.doc_item lists all field names", {
  withr::local_options(cli.num_colors = 1)
  item <- new_item("i", bbox = c(0, 0, 1, 1), collection = "c")
  expect_output(print(item), "fields:.*collection.*geometry.*properties")
})

test_that("print.doc_collection summarizes the spatial and temporal extent", {
  withr::local_options(cli.num_colors = 1)

  col <- new_collection("col", "Collection", "Desc")
  item <- new_item(
    "i", bbox = c(-50, -10, -49, -9),
    properties = new_properties(
      start_datetime = "2022-01-05T00:00:00Z",
      end_datetime = "2022-12-23T00:00:00Z"
    )
  )
  col <- add_items(col, item)

  expect_output(print(col), "bbox: -50, -10, -49, -9", fixed = TRUE)
  expect_output(
    print(col),
    "interval: 2022-01-05T00:00:00Z / 2022-12-23T00:00:00Z",
    fixed = TRUE
  )
  expect_output(print(col), "fields:.*extent")
})

test_that("print.doc_collection omits an empty extent", {
  withr::local_options(cli.num_colors = 1)
  out <- capture.output(print(new_collection("col", "Collection", "Desc")))
  expect_false(any(grepl("bbox|interval", out)))
})
