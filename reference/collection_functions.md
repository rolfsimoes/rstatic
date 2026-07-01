# Create and attach STAC collections

Pure builders for a STAC `Collection` document. Neither function touches
disk; use
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
to persist.

- `new_collection()`: creates an in-memory `Collection` object.

- `add_collection()`: registers a collection as a `child` of a catalog
  and returns the updated catalog.

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

add_collection(catalog, collection)
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
  [`add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md).

- stac_version:

  A `character` STAC specification version. Defaults to `"1.0.0"`.

- ...:

  Additional named fields added to the collection document.

- catalog:

  A `doc_catalog` object the collection is attached to.

- collection:

  A `doc_collection` object to register.

## Value

- `new_collection()`: a `doc_collection` object.

- `add_collection()`: the updated `doc_catalog` (the parent), so it can
  be chained with another call.

## Examples

``` r
col <- new_collection(
  id = "my-collection",
  title = "My Collection",
  description = "An example collection"
)
col$type
#> [1] "Collection"

cat <- new_catalog("cat", "Catalog", "Example")
cat <- add_collection(cat, col)
```
