# rstatic

Build browsable, server-less **static** SpatioTemporal Asset Catalogs
(STAC) from R.

`rstatic` turns a folder of geospatial assets into a valid
[STAC](https://stacspec.org/) catalog you can publish anywhere static
files are served — GitHub Pages, an S3 bucket, or a plain web server. No
database and no running service are required.

It does this through small, composable **primitives** for catalogs,
collections, items, assets, and links. Each one is a pure builder or an
explicit write to disk, so you stay in control of what gets created and
where. This makes `rstatic` equally useful on its own and as a
foundation for higher-level tools such as STAC generators and experiment
catalog builders. It implements STAC specification version 1.0.0.

## Features

- Build catalogs, collections, items, assets, and links with simple
  constructor functions.
- Serialize any document to its canonical static-catalog path on disk.
- Track spatial and temporal extents automatically as items are added.
- Optionally extract bounding boxes from rasters, render PNG thumbnail
  assets, and import QGIS layer styles.

The optional helpers activate automatically when their supporting
packages are installed; otherwise you can still build complete catalogs
by supplying bounding boxes, geometries, and styles yourself.

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

# 1. Build the documents in memory (pure -- nothing is written yet)
catalog <- new_catalog(
  id = "example",
  title = "Example Catalog",
  description = "A minimal static STAC catalog"
)

collection <- new_collection(
  id = "land-cover",
  title = "Land Cover",
  description = "Example land cover collection"
)

item <- new_item(
  id = "land-cover-2020",
  bbox = c(-50, -10, -49, -9),
  properties = new_properties(datetime = "2020-01-01T00:00:00Z"),
  assets = list(
    data = new_asset("land-cover-2020.tif", title = "Land Cover 2020")
  )
)

# 2. Link them with the pure add_*() builders
collection <- add_items(collection, item)
catalog <- add_collection(catalog, collection)

# 3. Persist -- stac_save() is the only writer
stac_save(catalog = catalog, collection = collection, items = item,
          root_dir = root)
```

The resulting directory follows the canonical static catalog layout,
with the collection linking to its item:

``` r

list.files(file.path(root, "stac"), recursive = TRUE)
#> [1] "catalog.json"                                          
#> [2] "collections/land-cover/collection.json"                
#> [3] "collections/land-cover/items/land-cover-2020/item.json"
```

Each file is a self-contained STAC document. To extend a catalog that is
already on disk, read it back with
[`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md),
add to it, and save again – saving is a pure overwrite, so reading first
is what preserves the existing children.

## Core primitives

| Function | Purpose |
|:---|:---|
| [`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md), [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md) | Build catalogs and collections in memory |
| [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md), [`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md), [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md) | Build items, properties and assets |
| [`add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md) / [`add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md) | Attach a collection/items to a parent, return it |
| [`add_link()`](https://rolfsimoes.github.io/rstatic/reference/add_link.md) / [`add_asset()`](https://rolfsimoes.github.io/rstatic/reference/add_asset.md) | Attach links and assets |
| [`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md) | Read a document from disk (load-or-create with `default`) |
| [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md) | Write documents to their canonical paths (the only writer) |
| [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md) / [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md) | Spatial metadata helpers |
| [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md) / [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md) | Thumbnail style objects |
| [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md) | Describe a PNG thumbnail asset (rendered on save) |

`new_*()` constructors and `add_*()` builders are pure and never touch
disk;
[`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md)
and
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
are the only functions that do.

## Documentation

- Full function reference and articles:
  <https://rolfsimoes.github.io/rstatic/>
- Get started:
  [`vignette("rstatic")`](https://rolfsimoes.github.io/rstatic/articles/rstatic.md)
- Per-function help,
  e.g. [`?stac_save`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)

## Getting help

Found a bug or have a feature request? Please open an issue at
<https://github.com/rolfsimoes/rstatic/issues>.

## Related work

`rstatic` focuses on *writing* static catalogs from primitives. If you
instead need to *query* remote STAC APIs from R, see
[`rstac`](https://github.com/brazil-data-cube/rstac).

## License

GPL (\>= 3). See
[LICENSE.md](https://rolfsimoes.github.io/rstatic/LICENSE.md).
