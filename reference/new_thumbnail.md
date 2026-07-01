# Describe a thumbnail asset

Pure builder that returns a STAC `Asset` describing a PNG thumbnail to
be rendered from a raster. No raster is read and no file is written
here: the render *intent* (source raster, width, and style) is carried
on the asset and materialized later, when the owning item is written
with
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md).

`new_thumbnail()` is generic. Pass the source either as a `character`
path or URL, or as a `doc_asset` from
[`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
– typically the item's data asset – in which case the raster is taken
from the asset's resolved `local_path` (see
[`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md))
or its `href`.

The optional `style` argument controls how raster values are mapped to
pixels. Build it with
[`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md)
or
[`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md).
Without a style, the raster is rendered with `terra`'s default settings.

Rendering happens at save time and requires the optional terra package.
If terra is not available, build the asset manually with
[`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
instead.

## Usage

``` r
new_thumbnail(x, ...)

# S3 method for class 'character'
new_thumbnail(x, width = 800, title = "Thumbnail", style = NULL, ...)

# S3 method for class 'doc_asset'
new_thumbnail(x, width = 800, title = "Thumbnail", style = NULL, ...)
```

## Arguments

- x:

  A `character` path or URL to the source raster, or a `doc_asset` from
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  pointing at it.

- ...:

  Additional arguments passed to the underlying `terra` plotting
  function at render time.

- width:

  An `integer` thumbnail width in pixels. Defaults to `800`.

- title:

  A `character` asset title. Defaults to `"Thumbnail"`.

- style:

  An optional `rstatic_style` object from
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md)
  or
  [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md).

## Value

A `doc_asset` with `href` `"thumbnail.png"` and roles `"thumbnail"`,
carrying the render intent so
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
can produce the PNG.

## Examples

``` r
f <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.tif",
    package = "rstatic"
)
style <- stac_style(min = 192, max = 1371, palette = c("black", "white"))

# Build an item with a data asset, then derive the thumbnail from that asset.
item <- new_item(
    "item-1",
    bbox = c(-50, -10, -49, -9),
    assets = list(data = new_asset(f, title = "B04"))
)
thumb <- new_thumbnail(item$assets$data, style = style)
item <- add_asset(item, "thumbnail", thumb)

# A plain path or URL works too.
new_thumbnail(f, style = style)$roles
#> [[1]]
#> [1] "thumbnail"
#> 
```
