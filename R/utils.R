#' Read a JSON file as a list
#'
#' @param file_path Path to a JSON file.
#'
#' @return A `list` with the parsed JSON content, or an empty `list` if the
#'   file does not exist.
#'
#' @keywords internal
#' @noRd
.read_json <- function(file_path) {
  if (file.exists(file_path)) {
    return(jsonlite::fromJSON(file_path, simplifyVector = FALSE))
  }
  list()
}

#' Write a list as a pretty JSON file
#'
#' @param data      A `list` to serialize.
#' @param file_path Destination path. Parent directories are created.
#'
#' @return Invisibly returns `file_path`.
#'
#' @keywords internal
#' @noRd
.write_json <- function(data, file_path) {
  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(
    data,
    file_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  invisible(file_path)
}

#' Add a link to a list of links, avoiding duplicates
#'
#' @param links A `list` of link entries, or `NULL`.
#' @param rel   The relation type of the link.
#' @param href  The link target.
#' @param type  The media type of the link.
#' @param title An optional title for the link.
#'
#' @return The updated `list` of links.
#'
#' @keywords internal
#' @noRd
.add_link <- function(links,
                      rel,
                      href,
                      type = "application/json",
                      title = NULL) {
  if (is.null(links)) {
    links <- list()
  }
  exists <- vapply(
    links,
    function(l) isTRUE(l$rel == rel) && isTRUE(l$href == href),
    logical(1)
  )
  if (any(exists)) {
    return(links)
  }
  new_link <- list(rel = rel, href = href, type = type)
  if (!is.null(title)) {
    new_link$title <- title
  }
  c(links, list(new_link))
}

#' Deduce a media (MIME) type from a file extension
#'
#' @param url A file path or URL.
#'
#' @return A `character` media type string.
#'
#' @keywords internal
#' @noRd
.get_media_type <- function(url) {
  ext <- tools::file_ext(url)
  switch(
    tolower(ext),
    tif = "image/tiff; application=geotiff",
    tiff = "image/tiff; application=geotiff",
    zip = "application/zip",
    vrt = "application/xml",
    rds = "application/octet-stream",
    qml = "application/x-qgis-layer-settings",
    json = "application/json",
    png = "image/png",
    "application/octet-stream"
  )
}

#' Ensure a datetime string follows RFC 3339
#'
#' @param dt A datetime `character` value, `NA`, or `NULL`.
#'
#' @return The datetime coerced to an RFC 3339 string, or the input unchanged
#'   when it is `NULL`/`NA`.
#'
#' @keywords internal
#' @noRd
.ensure_rfc3339 <- function(dt) {
  if (is.null(dt) || is.na(dt)) {
    return(dt)
  }
  if (!grepl("Z$|\\+\\d{2}:\\d{2}$", dt)) {
    if (!grepl("T", dt)) {
      dt <- paste0(dt, "T00:00:00Z")
    } else {
      dt <- paste0(dt, "Z")
    }
  }
  dt
}

#' Assign rstatic/rstac document classes to a STAC object
#'
#' Classes are assigned to the parent document *and* to its child documents
#' (each `link` and each `asset`), so that S3 dispatch (e.g. `print()`) works
#' on nested elements such as `doc$links` or `doc$assets[[key]]`.
#'
#' @param x A STAC object (`list`) with a `type` key.
#'
#' @return The object `x` with appropriate S3 classes assigned.
#'
#' @keywords internal
#' @noRd
.as_rstac <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (!is.null(x$links)) {
    x$links <- .as_doc_links(x$links)
  }
  if (!is.null(x$assets)) {
    x$assets <- lapply(x$assets, .as_doc_asset)
  }
  if (!is.null(x$geometry)) {
    class(x$geometry) <- c("doc_geometry", "list")
  }
  type <- x$type
  if (is.null(type)) {
    return(x)
  }
  doc_class <- switch(
    tolower(type),
    catalog = "doc_catalog",
    collection = "doc_collection",
    feature = "doc_item",
    NULL
  )
  if (!is.null(doc_class)) {
    class(x) <- c(doc_class, "rstac_doc", "list")
  }
  x
}

#' Class a single link as a `doc_link`
#'
#' @keywords internal
#' @noRd
.as_doc_link <- function(x) {
  class(x) <- c("doc_link", "list")
  x
}

#' Class a list of links as `doc_links`, classing each element as `doc_link`
#'
#' @keywords internal
#' @noRd
.as_doc_links <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  x <- lapply(x, .as_doc_link)
  class(x) <- c("doc_links", "list")
  x
}

#' Class a single asset as a `doc_asset`
#'
#' @keywords internal
#' @noRd
.as_doc_asset <- function(x) {
  class(x) <- c("doc_asset", "list")
  x
}
