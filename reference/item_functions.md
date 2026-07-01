# Create STAC items, properties, and assets

Pure builders for the building blocks of a STAC `Item`. None touch disk;
use
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
to persist.

- `new_properties()`: assembles an item `properties` list.

- `new_asset()`: creates a single STAC `Asset`.

- `new_item()`: creates an in-memory `Item` (a GeoJSON `Feature`).

- `add_items()`: links one or more items into a collection, updating the
  collection links and spatio-temporal extent, and returns the
  collection.

STAC requires every item to carry a `datetime`. When you describe a time
range instead of a single instant, supply `start_datetime` and
`end_datetime` and omit `datetime`; `new_properties()` then records
`datetime` as `null`, as the specification mandates. `add_items()`
derives the collection's temporal extent from the range (or from
`datetime` when only that is given).

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
  collection = NULL,
  stac_version = "1.0.0",
  ...
)

add_items(collection, items)
```

## Arguments

- description:

  A `character` description.

- datetime:

  A `character` RFC 3339 datetime, or `NULL`. Recorded as `null` when
  omitted alongside a `start_datetime`/`end_datetime` range.

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

- collection:

  For `add_items()`, the `doc_collection` to link items into. For
  `new_item()`, an optional `doc_collection` or `character` collection
  id recorded as the item's top-level `collection` field. STAC requires
  this field whenever the item carries a `collection` link (as items
  built here always do); when omitted,
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  stamps it from the `collection` it is given.

- stac_version:

  A `character` STAC version. Defaults to `"1.0.0"`.

- items:

  A single `doc_item`, or a `list` of `doc_item` objects, to link into
  the collection.

## Value

- `new_properties()`: a `list` of properties.

- `new_asset()`: a `doc_asset` object describing an asset.

- `new_item()`: a `doc_item` object.

- `add_items()`: the updated `doc_collection`.

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

col <- new_collection("col", "Collection", "Example")
col <- add_items(col, item)
col$extent$spatial$bbox[[1]]
#> [1] -50 -10 -49  -9
```
