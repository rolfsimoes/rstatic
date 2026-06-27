# rstatic ![](inst/extdata/img/logo.png)

Primitives to generate **static** SpatioTemporal Asset Catalogs (STAC).

STAC is a specification of files and web services used to describe
geospatial information assets. The specification can be consulted at
<https://stacspec.org/>.

`rstatic` provides small, composable **primitives** to build and
serialize static STAC documents (catalogs, collections, items, assets,
and links). It is designed to be a reusable foundation that other
packages (e.g. STAC generators, experiment catalog builders) can rely
on. It implements the STAC specification version 1.0.0.

Optional features rely on suggested packages and degrade gracefully when
they are not installed:

- **`terra`** — bounding-box extraction
  ([`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md))
  and thumbnail rendering
  ([`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)).
- **`xml2`** — QGIS style parsing
  ([`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md)).

If these packages are unavailable, you can still build documents by
supplying bounding boxes, geometries, and styles manually.

## Installation

You can install the development version of `rstatic` from GitHub with:

``` r

# install.packages("remotes")
remotes::install_github("rolfsimoes/rstatic")
```

## Usage

The example below builds a minimal static catalog with one collection
and one item, writing the JSON tree under a temporary directory.

``` r

library(rstatic)

root <- tempfile("stac-")

# 1. Initialize the root catalog
catalog <- stac_init(
  id = "example",
  title = "Example Catalog",
  description = "A minimal static STAC catalog",
  root_dir = root
)
#> Catalog example initialized/updated at /tmp/RtmpGSJL3d/stac-40dac6ac2aaab/stac/catalog.json

# 2. Add a collection
collection <- new_collection(
  id = "land-cover",
  title = "Land Cover",
  description = "Example land cover collection"
)
catalog <- stac_add_collection(catalog, collection = collection, root_dir = root)
#> Collection land-cover added to Catalog.

# 3. Build and add an item
item <- new_item(
  id = "land-cover-2020",
  bbox = c(-50, -10, -49, -9),
  properties = new_properties(datetime = "2020-01-01T00:00:00Z"),
  assets = list(
    data = new_asset("land-cover-2020.tif", title = "Land Cover 2020")
  )
)

collection <- stac_add_items(collection, item, root_dir = root)
#> Added 1 item(s) to collection land-cover.
```

The resulting directory follows the canonical static catalog layout:

``` r

list.files(file.path(root, "stac"), recursive = TRUE)
#> [1] "catalog.json"                                          
#> [2] "collections/land-cover/collection.json"                
#> [3] "collections/land-cover/items/land-cover-2020/item.json"
```

## Core primitives

| Function | Purpose |
|:---|:---|
| [`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md) / [`stac_init()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md) | Create / write a root catalog |
| [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md) / [`stac_add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md) | Create / register a collection |
| [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md), [`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md), [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md) | Build items, properties and assets |
| [`stac_add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md) / [`stac_add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md) | Register collections/items and return the parent |
| [`stac_add_link()`](https://rolfsimoes.github.io/rstatic/reference/stac_add_link.md) / [`stac_add_asset()`](https://rolfsimoes.github.io/rstatic/reference/stac_add_asset.md) | Pure builders for links and assets |
| [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md) | Write any document to its canonical path |
| [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md) / [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md) | Spatial metadata helpers |
| [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md) / [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md) | Thumbnail style objects |
| [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md) | Render a PNG thumbnail asset |

## License

GPL (\>= 3)
