make_catalog <- function() {
  catalog <- new_catalog("cat", "Catalog", "Example")
  catalog <- add_collection(catalog, new_collection("a", "A", "First"))
  add_collection(catalog, new_collection("b", "B", "Second"))
}

test_that("list_links returns all links as a plain list", {
  catalog <- make_catalog()
  res <- list_links(catalog)

  expect_type(res, "list")
  expect_false(inherits(res, "doc_links"))
  expect_length(res, length(catalog$links))
  # Elements are the individual links.
  expect_true(all(vapply(res, function(l) !is.null(l$rel), logical(1))))
})

test_that("list_links filters by a single expression", {
  catalog <- make_catalog()
  children <- list_links(catalog, rel == "child")

  expect_type(children, "list")
  expect_length(children, 2)
  expect_true(all(vapply(children, function(l) l$rel == "child", logical(1))))
})

test_that("list_links combines expressions with logical AND", {
  catalog <- make_catalog()
  res <- list_links(catalog, rel == "child", type == "application/json")
  expect_length(res, 2)

  none <- list_links(catalog, rel == "child", type == "text/html")
  expect_length(none, 0)
})

test_that("list_links resolves variables from the calling scope", {
  catalog <- make_catalog()
  wanted <- "child"
  res <- list_links(catalog, rel == wanted)
  expect_length(res, 2)
})

test_that("list_links excludes links whose fields make an expression error", {
  catalog <- make_catalog()
  # Child links carry a title; the self/root links do not. Filtering on `title`
  # must not error, only exclude the non-matching links.
  res <- expect_no_error(list_links(catalog, title == "A"))
  expect_length(res, 1)
  expect_equal(res[[1]]$title, "A")
})

test_that("list_links returns an empty list when nothing matches", {
  catalog <- make_catalog()
  res <- list_links(catalog, rel == "does-not-exist")
  expect_type(res, "list")
  expect_length(res, 0)
})

test_that("list_links accepts a bare list of links", {
  catalog <- make_catalog()
  expect_equal(
    list_links(catalog$links, rel == "child"),
    list_links(catalog, rel == "child")
  )
})

test_that("list_links errors on non-document, non-list input", {
  expect_error(list_links("not-a-doc"), "STAC document")
})
