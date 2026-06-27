test_that("chained stac_add_collection calls accumulate child links", {
  dir <- withr::local_tempdir()
  col_a <- new_collection("col-a", "Collection A", "Desc")
  col_b <- new_collection("col-b", "Collection B", "Desc")

  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  cat <- stac_add_collection(cat, collection = col_a, root_dir = dir)
  cat <- stac_add_collection(cat, collection = col_b, root_dir = dir)

  # In-memory catalog has two child links
  child_links <- Filter(function(l) l$rel == "child", cat$links)
  expect_length(child_links, 2)

  # Persisted catalog also has two child links
  persisted <- rstatic:::.read_json(file.path(dir, "stac", "catalog.json"))
  persisted_child <- Filter(function(l) l$rel == "child", persisted$links)
  expect_length(persisted_child, 2)
})

test_that("stac_add_collection returns the catalog (parent)", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")
  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  result <- stac_add_collection(cat, collection = col, root_dir = dir)

  expect_s3_class(result, "doc_catalog")
})

test_that("stac_add_items returns the collection (parent)", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")
  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  cat <- stac_add_collection(cat, collection = col, root_dir = dir)

  item <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  result <- stac_add_items(col, item, root_dir = dir)

  expect_s3_class(result, "doc_collection")
})

test_that("stac_add_collection is idempotent", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")

  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  cat <- stac_add_collection(cat, collection = col, root_dir = dir)
  cat <- stac_add_collection(cat, collection = col, root_dir = dir)

  child_links <- Filter(function(l) l$rel == "child", cat$links)
  expect_length(child_links, 1)
})

test_that("chained stac_add_items calls accumulate item links", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")
  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  cat <- stac_add_collection(cat, collection = col, root_dir = dir)

  item1 <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  item2 <- new_item(
    "i2", bbox = c(-48, -12, -47, -11),
    properties = new_properties(datetime = "2021-06-01T00:00:00Z")
  )
  col <- stac_add_items(col, item1, root_dir = dir)
  col <- stac_add_items(col, item2, root_dir = dir)

  # In-memory collection has two item links
  item_links <- Filter(function(l) l$rel == "item", col$links)
  expect_length(item_links, 2)

  # Persisted collection also has two item links
  persisted <- rstatic:::.read_json(
    file.path(dir, "stac", "collections", "col", "collection.json")
  )
  persisted_item <- Filter(function(l) l$rel == "item", persisted$links)
  expect_length(persisted_item, 2)

  # Extent spans both items
  bbox <- unlist(col$extent$spatial$bbox[[1]])
  expect_equal(bbox, c(-50, -12, -47, -9))
})

test_that("stac_add_link appends and dedupes links", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- stac_add_link(cat, "child", "a.json")
  cat <- stac_add_link(cat, "child", "a.json")
  cat <- stac_add_link(cat, "child", "b.json", title = "B")

  expect_length(cat$links, 4) # self, root, a, b
  expect_equal(cat$links[[4]]$title, "B")
})

test_that("stac_add_link preserves document class", {
  cat <- new_catalog("cat", "Catalog", "Desc")
  result <- stac_add_link(cat, "child", "x.json")
  expect_s3_class(result, "doc_catalog")

  col <- new_collection("col", "Collection", "Desc")
  result <- stac_add_link(col, "item", "x.json")
  expect_s3_class(result, "doc_collection")

  item <- new_item("i", bbox = c(0, 0, 1, 1))
  result <- stac_add_link(item, "derived_from", "x.json")
  expect_s3_class(result, "doc_item")
})

test_that("stac_add_link does not touch disk", {
  dir <- withr::local_tempdir()
  cat <- new_catalog("cat", "Catalog", "Desc")
  cat <- stac_add_link(cat, "child", "x.json")

  expect_false(file.exists(file.path(dir, "stac", "catalog.json")))
})

test_that("stac_add_asset appends and overwrites by key", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  item <- stac_add_asset(item, "data", new_asset("data.tif"))
  expect_true("data" %in% names(item$assets))
  expect_equal(item$assets$data$href, "data.tif")

  item <- stac_add_asset(item, "data", new_asset("updated.tif"))
  expect_equal(item$assets$data$href, "updated.tif")
})

test_that("stac_add_asset works on collections", {
  col <- new_collection("col", "Collection", "Desc")
  col <- stac_add_asset(col, "thumbnail", new_asset("thumb.png", roles = list("thumbnail")))
  expect_true("thumbnail" %in% names(col$assets))
})

test_that("stac_add_asset preserves document class", {
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  result <- stac_add_asset(item, "data", new_asset("data.tif"))
  expect_s3_class(result, "doc_item")
})

test_that("stac_add_asset does not touch disk", {
  dir <- withr::local_tempdir()
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  item <- stac_add_asset(item, "data", new_asset("data.tif"))

  expect_false(file.exists(file.path(dir, "stac")))
})
