# Plot a STAC asset

Plot visual assets such as thumbnails, quicklooks, or raster previews.
Supported file formats are `png`, `jpeg`, and `tiff`/`tif`. When a
thumbnail is generated with
[`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md),
the full path is stored as an internal attribute so that the plot method
can locate the file even when the asset's `href` is relative.

## Usage

``` r
# S3 method for class 'doc_asset'
plot(x, ...)
```

## Arguments

- x:

  A `doc_asset` object.

- ...:

  Additional arguments passed to the underlying plotting engine
  (currently ignored for image formats, passed to
  [`terra::plot()`](https://rspatial.github.io/terra/reference/plot.html)
  for GeoTIFFs).

## Value

Invisibly, `x`.

## Examples

``` r
thumb <- new_asset("thumbnail.png", title = "Thumbnail",
  roles = list("thumbnail"))
attr(thumb, "local_path") <- system.file("extdata/img/logo.png",
  package = "rstatic")
if (nzchar(attr(thumb, "local_path"))) plot(thumb)
```
