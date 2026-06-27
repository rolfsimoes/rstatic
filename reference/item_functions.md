# Create STAC items, properties, and assets

Functions to build the building blocks of a STAC `Item`.

- `new_properties()`: assembles an item `properties` list.

- `new_asset()`: creates a single STAC `Asset`.

- `new_item()`: creates an in-memory `Item` (a GeoJSON `Feature`).

- `stac_add_items()`: persists one or more items into a collection,
  updating the collection links and spatio-temporal extent.

## Usage

``` r
new_properties(
  description = NULL,
  datetime = NULL,
  start_datetime = NULL,
  end_datetime = NULL,
  start_date = NULL,
  end_date = NULL,
  ...
)

new_asset(href, title = NULL, roles = list("data"), ...)

new_item(
  id,
  bbox,
  geometry = NULL,
  properties = new_properties(),
  assets = list(),
  stac_version = "1.0.0",
  ...
)

stac_add_items(collection, ..., root_dir = ".")
```

## Arguments

- description:

  A `character` description.

- datetime:

  A `character` RFC 3339 datetime, or `NULL`.

- start_datetime:

  A `character` RFC 3339 start datetime, or `NULL`.

- end_datetime:

  A `character` RFC 3339 end datetime, or `NULL`.

- start_date:

  A `character` start date, or `NULL`.

- end_date:

  A `character` end date, or `NULL`.

- ...:

  Additional named fields. See details for each function.

- href:

  A `character` asset target (path or URL).

- title:

  A `character` title.

- roles:

  A `list` of asset roles. Defaults to `list("data")`.

- id:

  A `character` identifier for the item.

- bbox:

  A numeric vector `c(xmin, ymin, xmax, ymax)`.

- geometry:

  A GeoJSON geometry `list`. If `NULL`, it is derived from `bbox` via
  [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md).

- properties:

  A `list` of item properties, e.g. from `new_properties()`.

- assets:

  A named `list` of assets, e.g. from `new_asset()`.

- stac_version:

  A `character` STAC version. Defaults to `"1.0.0"`.

- collection:

  A `doc_collection` object to add items to.

- root_dir:

  A `character` directory under which documents are written. Defaults to
  the current working directory.

## Value

- `new_properties()`: a `list` of properties.

- `new_asset()`: a `doc_asset` object describing an asset.

- `new_item()`: a `doc_item` object.

- `stac_add_items()`: invisibly, the updated `doc_collection`.

## Examples

``` r
props <- new_properties(datetime = "2020-01-01T00:00:00Z")
asset <- new_asset("data.tif", title = "Data")
item <- new_item(
  id = "item-1",
  bbox = c(-50, -10, -49, -9),
  properties = props,
  assets = list(data = asset)
)
item$type
#> [1] "Feature"

dir <- tempfile("stac-")
cat <- stac_init("cat", "Catalog", "Example", root_dir = dir)
#> Catalog cat initialized/updated at /tmp/RtmpHpTfbU/stac-1cc53b2518a4/stac/catalog.json
col <- stac_add_collection(
  cat,
  collection = new_collection("col", "Collection", "Example"),
  root_dir = dir
)
#> Collection col added to Catalog.
stac_add_items(col, item, root_dir = dir)
#> Added 1 item(s) to collection cat.
```
