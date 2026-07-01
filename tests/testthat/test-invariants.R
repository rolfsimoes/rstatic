test_that("chained add_collection calls accumulate child links in memory", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- add_collection(cat, new_collection("col-a", "Collection A", "Desc"))
  cat <- add_collection(cat, new_collection("col-b", "Collection B", "Desc"))

  child_links <- Filter(function(l) l$rel == "child", cat$links)
  expect_length(child_links, 2)
})

test_that("add_collection returns the catalog (parent)", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  result <- add_collection(cat, new_collection("col", "Collection", "Desc"))
  expect_s3_class(result, "doc_catalog")
})

test_that("add_collection does not touch disk", {
  dir <- withr::local_tempdir()
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- add_collection(cat, new_collection("col", "Collection", "Desc"))
  expect_false(file.exists(file.path(dir, "stac", "catalog.json")))
})

test_that("add_items returns the collection (parent)", {
  col <- new_collection("col", "Collection", "Desc")
  item <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  result <- add_items(col, item)
  expect_s3_class(result, "doc_collection")
})

test_that("add_collection is idempotent", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  col <- new_collection("col", "Collection", "Desc")
  cat <- add_collection(cat, col)
  cat <- add_collection(cat, col)

  child_links <- Filter(function(l) l$rel == "child", cat$links)
  expect_length(child_links, 1)
})

test_that("chained add_items calls accumulate item links and extent", {
  col <- new_collection("col", "Collection", "Desc")
  item1 <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  item2 <- new_item(
    "i2", bbox = c(-48, -12, -47, -11),
    properties = new_properties(datetime = "2021-06-01T00:00:00Z")
  )
  col <- add_items(col, item1)
  col <- add_items(col, item2)

  item_links <- Filter(function(l) l$rel == "item", col$links)
  expect_length(item_links, 2)

  bbox <- unlist(col$extent$spatial$bbox[[1]])
  expect_equal(bbox, c(-50, -12, -47, -9))
})

test_that("add_items sets the temporal extent from a start/end range", {
  col <- new_collection("col", "Collection", "Desc")
  item <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(
      start_datetime = "2022-01-05T00:00:00Z",
      end_datetime = "2022-12-23T00:00:00Z"
    )
  )
  col <- add_items(col, item)

  interval <- col$extent$temporal$interval[[1]]
  expect_equal(interval[[1]], "2022-01-05T00:00:00Z")
  expect_equal(interval[[2]], "2022-12-23T00:00:00Z")
})

test_that("add_link appends and dedupes by (rel, href)", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- add_link(cat, "child", "a.json")
  cat <- add_link(cat, "child", "a.json")
  cat <- add_link(cat, "child", "b.json", title = "B")

  expect_length(cat$links, 4) # self, root, a, b
  expect_equal(cat$links[[4]]$title, "B")
})

test_that("add_link distinguishes links that share an href across rels", {
  col <- new_collection("col", "Collection", "Desc")
  # root and parent already share href "../../catalog.json"
  start <- length(col$links)
  col <- add_link(col, "derived_from", "../../catalog.json")
  expect_length(col$links, start + 1)
})

test_that("add_link preserves document class", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  expect_s3_class(add_link(cat, "child", "x.json"), "doc_catalog")

  col <- new_collection("col", "Collection", "Desc")
  expect_s3_class(add_link(col, "item", "x.json"), "doc_collection")

  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_s3_class(add_link(item, "derived_from", "x.json"), "doc_item")
})

test_that("add_link does not touch disk", {
  dir <- withr::local_tempdir()
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- add_link(cat, "child", "x.json")
  expect_false(file.exists(file.path(dir, "stac", "catalog.json")))
})

test_that("add_asset appends and overwrites by key", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  item <- add_asset(item, "data", new_asset("data.tif"))
  expect_equal(item$assets$data$href, "data.tif")

  item <- add_asset(item, "data", new_asset("updated.tif"))
  expect_equal(item$assets$data$href, "updated.tif")
})

test_that("add_asset works on collections", {
  col <- new_collection("col", "Collection", "Desc")
  col <- add_asset(col, "thumbnail",
                   new_asset("thumb.png", roles = list("thumbnail")))
  expect_true("thumbnail" %in% names(col$assets))
})

test_that("add_asset preserves document class", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_s3_class(add_asset(item, "data", new_asset("data.tif")), "doc_item")
})

test_that("add_asset does not touch disk", {
  dir <- withr::local_tempdir()
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  item <- add_asset(item, "data", new_asset("data.tif"))
  expect_false(file.exists(file.path(dir, "stac")))
})
