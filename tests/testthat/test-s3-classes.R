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
