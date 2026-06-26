# Generating a static STAC catalog with rstatic

``` r

library(rstatic)
```

## Overview

`rstatic` provides composable primitives to build and serialize
**static** SpatioTemporal Asset Catalog (STAC) documents. A static
catalog is a tree of plain JSON files linked to one another, following
the [STAC specification](https://github.com/radiantearth/stac-spec)
version 1.0.0:

    stac/
      catalog.json
      collections/
        {collection}/
          collection.json
          items/
            {item}/
              item.json

This vignette walks through building such a tree from scratch. All
output is written under a temporary directory so the vignette is fully
self-contained.

``` r

root <- tempfile("stac-")
```

## 1. Initialize the root catalog

[`stac_init()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md)
creates (or updates) the root `catalog.json`. It preserves any existing
`child` links, so it is safe to call repeatedly.

``` r

catalog <- stac_init(
  id = "restore-plus",
  title = "Restore+ Catalog",
  description = "An example static STAC catalog built with rstatic",
  root_dir = root
)
#> Catalog restore-plus initialized/updated at /tmp/RtmpKNxIUB/stac-1e7a787f00a6/stac/catalog.json
catalog
#> <STAC Catalog>
#>   id:    restore-plus
#>   title: Restore+ Catalog
#>   links: 2
```

## 2. Create and register a collection

Collections group related items.
[`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
builds the document in memory and
[`stac_add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
persists it and links it to the catalog. Any extra named arguments
(e.g. `citation`, `doi`) are stored as additional collection fields.

``` r

collection <- stac_add_collection(
  catalog,
  collection = new_collection(
    id = "land-cover",
    title = "Example Land Cover",
    description = "Annual land cover maps (example data)",
    license = "CC-BY-4.0"
  ),
  root_dir = root
)
#> Collection land-cover added to Catalog.
collection
#> <STAC Collection>
#>   id:    land-cover
#>   title: Example Land Cover
#>   links: 3
```

## 3. Spatial metadata

If [terra](https://rspatial.github.io/terra/) is installed,
[`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
reads a raster and returns its bounding box in WGS84. A small Sentinel-2
subset ships with the package for demonstration.

``` r

tif <- system.file("extdata/example.tif", package = "rstatic")
bbox <- extract_bbox(tif)
bbox
#>       xmin       ymin       xmax       ymax 
#> -63.636579  -8.630220 -63.450282  -8.491029
```

When `terra` is not available, you can pass a bounding box directly. The
[`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
helper turns a bounding box into a GeoJSON polygon and has no external
dependencies:

``` r

bbox <- c(-50, -10, -49, -9)
geometry <- as_geometry(bbox)
str(geometry, max.level = 2)
#> List of 2
#>  $ type       : chr "Polygon"
#>  $ coordinates:List of 1
#>   ..$ :List of 5
```

## 4. Build items

Items are GeoJSON `Feature`s. Build their `properties` with
[`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
and `assets` with
[`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md);
the asset media type is deduced from the file extension.

``` r

item <- new_item(
  id = "land-cover-2020",
  bbox = bbox,
  geometry = geometry,
  properties = new_properties(
    datetime = "2020-01-01T00:00:00Z",
    description = "Example land cover map for 2020"
  ),
  assets = list(
    data = new_asset("land-cover-2020.tif", title = "Land Cover 2020")
  )
)
item
#> <STAC Item>
#>   id:     land-cover-2020
#>   assets: 1
#>   links:  4
```

## 5. Add items to the collection

[`stac_add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
writes each item, links it from the collection, and updates the
collection’s spatial and temporal extent automatically.

``` r

collection <- stac_add_items(collection, item, root_dir = root)
#> Added 1 item(s) to collection land-cover.
collection$extent$spatial$bbox[[1]]
#> [1] -50 -10 -49  -9
collection$extent$temporal$interval[[1]]
#> [[1]]
#> [1] "2020-01-01T00:00:00Z"
#> 
#> [[2]]
#> [1] "2020-01-01T00:00:00Z"
```

## 6. Thumbnails and styles (optional)

With `terra`,
[`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
renders a PNG preview. Styles can be built explicitly with
[`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md)
or parsed from a QGIS `.qml` file with
[`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md)
(requires `xml2`).

``` r

style <- stac_style(min = 0, max = 255, palette = c("black", "white"))
style$type
#> [1] "simple"
```

``` r

thumb <- new_thumbnail(
  collection_id = "land-cover",
  item_id = "land-cover-2020",
  asset_href = system.file("extdata/example.tif", package = "rstatic"),
  width = 200,
  root_dir = root
)
thumb$roles
#> [[1]]
#> [1] "thumbnail"
```

## Resulting catalog

The final directory tree contains the linked JSON documents:

``` r

list.files(file.path(root, "stac"), recursive = TRUE)
#> [1] "catalog.json"                                              
#> [2] "collections/land-cover/collection.json"                    
#> [3] "collections/land-cover/items/land-cover-2020/item.json"    
#> [4] "collections/land-cover/items/land-cover-2020/thumbnail.png"
```
