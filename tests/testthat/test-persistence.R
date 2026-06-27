test_that("stac_save writes documents to canonical paths", {
  dir <- withr::local_tempdir()

  cat <- new_catalog("cat", "Catalog", "A catalog")
  stac_save(cat, root_dir = dir)
  expect_true(file.exists(file.path(dir, "stac", "catalog.json")))

  col <- new_collection("col", "Collection", "A collection")
  stac_save(col, root_dir = dir)
  expect_true(file.exists(
    file.path(dir, "stac", "collections", "col", "collection.json")
  ))
})

test_that("stac_save requires a collection field on items", {
  dir <- withr::local_tempdir()
  item <- new_item("i", bbox = c(0, 0, 1, 1))
  expect_error(stac_save(item, root_dir = dir), "collection")
})

test_that("stac_init preserves existing child links", {
  dir <- withr::local_tempdir()
  cat <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  cat <- stac_add_collection(
    cat,
    collection = new_collection("col", "Collection", "Desc"),
    root_dir = dir
  )
  # Re-init should keep the child link
  cat2 <- stac_init("cat", "Catalog", "Desc", root_dir = dir)
  rels <- vapply(cat2$links, function(l) l$rel, character(1))
  expect_true("child" %in% rels)
})

test_that("stac_add_items updates extent and links", {
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
  col <- stac_add_items(col, item1, item2, root_dir = dir)

  bbox <- unlist(col$extent$spatial$bbox[[1]])
  expect_equal(bbox, c(-50, -12, -47, -9))

  interval <- col$extent$temporal$interval[[1]]
  expect_equal(interval[[1]], "2020-01-01T00:00:00Z")
  expect_equal(interval[[2]], "2021-06-01T00:00:00Z")

  item_links <- Filter(function(l) l$rel == "item", col$links)
  expect_length(item_links, 2)

  expect_true(file.exists(
    file.path(dir, "stac", "collections", "col", "items", "i1", "item.json")
  ))
})
