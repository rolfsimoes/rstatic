#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x
