# Create and register STAC collections

Functions to build and attach a STAC `Collection` document.

- `new_collection()`: creates an in-memory `Collection` object.

- `stac_add_collection()`: persists a collection and registers it as a
  `child` of a catalog, then saves the updated catalog.

## Usage

``` r
new_collection(
  id,
  title,
  description,
  license = "proprietary",
  extent = NULL,
  stac_version = "1.0.0",
  ...
)

stac_add_collection(catalog, collection = NULL, ..., root_dir = ".")
```

## Arguments

- id:

  A `character` identifier for the collection.

- title:

  A `character` human-readable title.

- description:

  A `character` description of the collection.

- license:

  A `character` license identifier or URL. Defaults to `"proprietary"`.

- extent:

  A `list` with the collection `spatial` and `temporal` extent. If
  `NULL`, an empty extent is created and later updated by
  [`stac_add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md).

- stac_version:

  A `character` STAC specification version. Defaults to `"1.0.0"`.

- ...:

  Additional named fields. For `new_collection()`, these are added to
  the collection document. For `stac_add_collection()`, these are passed
  to `new_collection()` when `collection` is `NULL`.

- catalog:

  A `doc_catalog` object the collection is attached to.

- collection:

  A `doc_collection` object to register. If `NULL`, one is created from
  `...`.

- root_dir:

  A `character` directory under which documents are written. Defaults to
  the current working directory.

## Value

- `new_collection()`: a `doc_collection` object.

- `stac_add_collection()`: invisibly, the updated `doc_catalog` (the
  parent), so it can be chained with another call.

## Examples

``` r
col <- new_collection(
  id = "my-collection",
  title = "My Collection",
  description = "An example collection"
)
col$type
#> [1] "Collection"

dir <- tempfile("stac-")
cat <- stac_init("cat", "Catalog", "Example", root_dir = dir)
#> Catalog cat initialized/updated at /tmp/RtmpHpTfbU/stac-1cc5159f76d9/stac/catalog.json
cat <- stac_add_collection(cat, collection = col, root_dir = dir)
#> Collection my-collection added to Catalog.
```
