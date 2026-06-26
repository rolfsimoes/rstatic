test_that(".add_link avoids duplicates", {
  links <- list()
  links <- rstatic:::.add_link(links, "child", "a.json")
  links <- rstatic:::.add_link(links, "child", "a.json")
  expect_length(links, 1)
  links <- rstatic:::.add_link(links, "child", "b.json", title = "B")
  expect_length(links, 2)
  expect_equal(links[[2]]$title, "B")
})

test_that(".ensure_rfc3339 coerces dates and datetimes", {
  expect_equal(rstatic:::.ensure_rfc3339("2020-01-01"),
               "2020-01-01T00:00:00Z")
  expect_equal(rstatic:::.ensure_rfc3339("2020-01-01T12:00:00"),
               "2020-01-01T12:00:00Z")
  expect_equal(rstatic:::.ensure_rfc3339("2020-01-01T12:00:00Z"),
               "2020-01-01T12:00:00Z")
  expect_null(rstatic:::.ensure_rfc3339(NULL))
})

test_that(".get_media_type handles common extensions", {
  expect_equal(rstatic:::.get_media_type("a.json"), "application/json")
  expect_equal(rstatic:::.get_media_type("a.png"), "image/png")
  expect_equal(rstatic:::.get_media_type("a.zip"), "application/zip")
})

test_that("as_geometry returns NULL for NULL bbox", {
  expect_null(as_geometry(NULL))
})

test_that("as_geometry builds a closed polygon ring", {
  geom <- as_geometry(c(0, 0, 1, 1))
  ring <- geom$coordinates[[1]]
  expect_length(ring, 5)
  expect_equal(ring[[1]], ring[[5]])
})
