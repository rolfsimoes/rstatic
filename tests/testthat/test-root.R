test_that("update_root resolves item asset paths from the item's collection", {
  root <- withr::local_tempdir()
  col <- new_collection("land-cover", "Land Cover", "Desc")
  item <- new_item(
    "land-cover-2022",
    bbox = c(-50, -10, -49, -9),
    collection = col,
    assets = list(thumbnail = new_asset("thumbnail.png", title = "Thumb"))
  )

  item <- update_root(item, root)
  expect_equal(
    attr(item$assets$thumbnail, "local_path"),
    file.path(root, "stac", "collections", "land-cover", "items",
              "land-cover-2022", "thumbnail.png")
  )
  # The doc classes survive.
  expect_s3_class(item, "doc_item")
  expect_s3_class(item$assets$thumbnail, "doc_asset")
})

test_that("update_root errors on an item without a collection", {
  root <- withr::local_tempdir()
  item <- new_item("i", bbox = c(0, 0, 1, 1),
                   assets = list(thumbnail = new_asset("thumbnail.png")))
  expect_error(update_root(item, root), "collection")
})

test_that("update_root leaves absolute and remote hrefs untouched", {
  root <- withr::local_tempdir()
  item <- new_item(
    "i", bbox = c(0, 0, 1, 1), collection = "col",
    assets = list(
      data = new_asset("/data/red.tif", title = "Absolute"),
      remote = new_asset("https://example.org/red.tif", title = "Remote")
    )
  )
  item <- update_root(item, root)
  expect_null(attr(item$assets$data, "local_path"))
  expect_null(attr(item$assets$remote, "local_path"))
})

test_that("update_root resolves a collection's own asset paths", {
  root <- withr::local_tempdir()
  col <- new_collection("land-cover", "Land Cover", "Desc")
  # A propagated thumbnail lives under the collection, pointing into an item.
  col <- add_asset(
    col, "thumbnail",
    new_asset("./items/land-cover-2022/thumbnail.png", title = "Thumb")
  )

  col <- update_root(col, root)
  expect_equal(
    attr(col$assets$thumbnail, "local_path"),
    file.path(root, "stac", "collections", "land-cover",
              "./items/land-cover-2022/thumbnail.png")
  )
})

test_that("update_root validates root_dir", {
  item <- new_item("i", bbox = c(0, 0, 1, 1), collection = "col")
  expect_error(update_root(item, c("a", "b")), "root_dir")
})
