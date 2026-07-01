test_that("stac_save writes documents to canonical paths", {
  dir <- withr::local_tempdir()

  cat <- new_catalog("cat", "Catalog", "A catalog")
  stac_save(catalog = cat, root_dir = dir)
  expect_true(file.exists(file.path(dir, "stac", "catalog.json")))

  col <- new_collection("col", "Collection", "A collection")
  stac_save(collection = col, root_dir = dir)
  expect_true(file.exists(
    file.path(dir, "stac", "collections", "col", "collection.json")
  ))
})

test_that("stac_save stamps items with the collection and writes item.json", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")
  item <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  stac_save(collection = col, items = item, root_dir = dir)

  path <- file.path(dir, "stac", "collections", "col", "items", "i1",
                    "item.json")
  expect_true(file.exists(path))
  expect_equal(stac_read(path)$collection, "col")
})

test_that("a ranged item is written with an explicit null datetime", {
  dir <- withr::local_tempdir()
  col <- new_collection("col", "Collection", "Desc")
  item <- new_item(
    "i1", bbox = c(-50, -10, -49, -9),
    properties = new_properties(
      start_datetime = "2022-01-05T00:00:00Z",
      end_datetime = "2022-12-23T00:00:00Z"
    )
  )
  stac_save(collection = col, items = item, root_dir = dir)

  raw <- jsonlite::fromJSON(
    file.path(dir, "stac", "collections", "col", "items", "i1", "item.json"),
    simplifyVector = FALSE
  )
  expect_true("datetime" %in% names(raw$properties))
  expect_null(raw$properties$datetime)
  expect_equal(raw$properties$start_datetime, "2022-01-05T00:00:00Z")
  expect_equal(raw$properties$end_datetime, "2022-12-23T00:00:00Z")
})

test_that("stac_save warns and keeps the item's collection on a mismatch", {
  dir <- withr::local_tempdir()
  col <- new_collection("b", "B", "Desc")
  item <- new_item("i1", bbox = c(-50, -10, -49, -9), collection = "a")

  expect_warning(
    stac_save(collection = col, items = item, root_dir = dir),
    "differs"
  )

  # The item is written under its own collection ("a"), not the argument ("b").
  path <- file.path(dir, "stac", "collections", "a", "items", "i1", "item.json")
  expect_true(file.exists(path))
  expect_equal(stac_read(path)$collection, "a")
})

test_that("stac_save does not warn when collections agree", {
  dir <- withr::local_tempdir()
  col <- new_collection("a", "A", "Desc")
  item <- new_item("i1", bbox = c(-50, -10, -49, -9), collection = "a")
  expect_no_warning(stac_save(collection = col, items = item, root_dir = dir))
})

test_that("stac_save errors when an item has no collection context", {
  dir <- withr::local_tempdir()
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_error(stac_save(items = item, root_dir = dir), "collection")
})

test_that("stac_save overwrites and does not implicitly merge", {
  dir <- withr::local_tempdir()
  cat <- add_collection(new_catalog("cat", "Catalog", "Desc"),
                        new_collection("a", "A", "Desc"))
  stac_save(catalog = cat, root_dir = dir)

  # Saving a fresh catalog (no read) overwrites: the old child is gone.
  cat2 <- add_collection(new_catalog("cat", "Catalog", "Desc"),
                         new_collection("b", "B", "Desc"))
  stac_save(catalog = cat2, root_dir = dir)

  disk <- stac_read(file.path(dir, "stac", "catalog.json"))
  hrefs <- vapply(Filter(function(l) l$rel == "child", disk$links),
                  function(l) l$href, character(1))
  expect_equal(hrefs, "collections/b/collection.json")
})

test_that("read-modify-write accumulates children across runs", {
  dir <- withr::local_tempdir()

  # Run A: save collection A registered in the catalog
  item_a <- new_item(
    "ia", bbox = c(-50, -10, -49, -9),
    properties = new_properties(datetime = "2020-01-01T00:00:00Z")
  )
  col_a <- add_items(new_collection("a", "A", "Desc"), item_a)
  cat_a <- add_collection(new_catalog("cat", "Catalog", "Desc"), col_a)
  stac_save(catalog = cat_a, collection = col_a, items = item_a,
            root_dir = dir)

  # Run B: read existing catalog, add a second collection, save
  cat <- stac_read(file.path(dir, "stac", "catalog.json"),
                   default = new_catalog("cat", "Catalog", "Desc"))
  col_b <- new_collection("b", "B", "Desc")
  cat <- add_collection(cat, col_b)
  stac_save(catalog = cat, collection = col_b, root_dir = dir)

  disk <- stac_read(file.path(dir, "stac", "catalog.json"))
  hrefs <- vapply(Filter(function(l) l$rel == "child", disk$links),
                  function(l) l$href, character(1))
  expect_setequal(hrefs, c("collections/a/collection.json",
                           "collections/b/collection.json"))
})

test_that("stac_read errors on a missing file without a default", {
  dir <- withr::local_tempdir()
  expect_error(
    stac_read(file.path(dir, "stac", "catalog.json")),
    "not found"
  )
})

test_that("stac_read returns the default for a missing file", {
  dir <- withr::local_tempdir()
  fallback <- new_catalog("fallback", "Fallback", "Desc")
  out <- stac_read(file.path(dir, "missing.json"), default = fallback)
  expect_s3_class(out, "doc_catalog")
  expect_equal(out$id, "fallback")
})

test_that("stac_read round-trips a saved document with classes", {
  dir <- withr::local_tempdir()
  stac_save(catalog = new_catalog("cat", "Catalog", "Desc"), root_dir = dir)
  out <- stac_read(file.path(dir, "stac", "catalog.json"))
  expect_s3_class(out, "doc_catalog")
  expect_equal(out$id, "cat")
})
