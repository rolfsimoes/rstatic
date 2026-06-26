# Generate a thumbnail asset

Renders a PNG thumbnail from a raster and returns a STAC `Asset`
pointing to it. The thumbnail is written under the canonical item
directory
`stac/collections/{collection_id}/items/{item_id}/thumbnail.png`.

This function requires the optional terra package. If terra is not
installed, build the thumbnail asset manually with
[`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md).

## Usage

``` r
new_thumbnail(
  collection_id,
  item_id,
  asset_href,
  width = 800,
  title = "Thumbnail",
  style = NULL,
  root_dir = ".",
  ...
)
```

## Arguments

- collection_id:

  A `character` collection identifier.

- item_id:

  A `character` item identifier.

- asset_href:

  A `character` path or URL to the source raster.

- width:

  An `integer` thumbnail width in pixels. Defaults to `800`.

- title:

  A `character` asset title. Defaults to `"Thumbnail"`.

- style:

  An optional style `list` from
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md)
  or
  [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md).

- root_dir:

  A `character` directory under which the thumbnail is written. Defaults
  to the current working directory.

- ...:

  Additional arguments passed to
  [`terra::plot()`](https://rspatial.github.io/terra/reference/plot.html).

## Value

A `list` describing the thumbnail asset (as from
[`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)).

## Examples

``` r
if (requireNamespace("terra", quietly = TRUE)) {
  f <- system.file("extdata/example.tif", package = "rstatic")
  if (nzchar(f)) {
    dir <- tempfile("stac-")
    new_thumbnail(
      collection_id = "col",
      item_id = "item-1",
      asset_href = f,
      root_dir = dir
    )
  }
}
#> $href
#> [1] "thumbnail.png"
#> 
#> $type
#> [1] "image/png"
#> 
#> $roles
#> $roles[[1]]
#> [1] "thumbnail"
#> 
#> 
#> $title
#> [1] "Thumbnail"
#> 
```
