test_that("stac_style builds simple, continuous, and categorical styles", {
  s1 <- stac_style(min = 0, max = 255)
  expect_equal(s1$type, "simple")

  s2 <- stac_style(pmin = 0.02, pmax = 0.98)
  expect_equal(s2$type, "continuous")

  legend <- data.frame(value = 1:2, color = c("#000000", "#ffffff"))
  s3 <- stac_style(legend = legend)
  expect_equal(s3$type, "categorical")
  expect_equal(s3$legend, legend)
})

test_that("qml_to_style errors clearly when xml2 is missing", {
  testthat::skip_if(requireNamespace("xml2", quietly = TRUE))
  expect_error(qml_to_style("x.qml"), "xml2")
})

test_that("qml_to_style parses a paletted QML into a categorical style", {
  skip_if_not_installed("xml2")
  qml <- system.file("extdata/example.qml", package = "rstatic")
  skip_if(!nzchar(qml))
  style <- qml_to_style(qml)
  expect_equal(style$type, "categorical")
  expect_s3_class(style$legend, "data.frame")
  expect_equal(nrow(style$legend), 3)
})
