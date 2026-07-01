# Plot a STAC asset

Plot visual assets such as thumbnails, quicklooks, or raster previews.
Supported file formats are `png`, `jpeg`, and `tiff`/`tif`. The file is
resolved from the asset's `local_path` attribute when present, otherwise
from its `href`. Set `local_path` to point the plot method at a rendered
file when the asset's `href` is relative (for example a thumbnail
written under an item directory by
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)).

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
