# Save STAC documents to their canonical paths

Writes a STAC `Catalog`, `Collection`, and/or `Item` documents to disk
following the canonical static catalog layout:

- `Catalog` -\> `stac/catalog.json`

- `Collection` -\> `stac/collections/{id}/collection.json`

- `Item` -\> `stac/collections/{collection}/items/{id}/item.json`

`stac_save()` is the only writer in the package, and it is a **pure
overwrite**: it writes exactly the documents it is given, with no disk
reads and no implicit merging. To accumulate state across runs (for
example a catalog populated by several scripts), read the existing
document first with
[`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md),
add to it with the `add_*()` builders, then save the result.

Documents are written children-first (items, then collection, then
catalog) so a reader following a parent's links always finds the child
already on disk. Items are stamped with the `collection` field from the
`collection` argument when they do not already carry one; an item that
already records a `collection` keeps its own value, and a warning is
emitted if that value differs from the `collection` argument. Any asset
built with
[`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
is rendered to a PNG at this point (requires terra).

## Usage

``` r
stac_save(catalog = NULL, collection = NULL, items = NULL, root_dir = ".")
```

## Arguments

- catalog:

  An optional `doc_catalog` from
  [`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md).

- collection:

  An optional `doc_collection` from
  [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md).
  When `items` are given, supplies their `collection` field.

- items:

  An optional `doc_item`, or a `list` of `doc_item` objects.

- root_dir:

  A `character` directory under which the `stac/` tree is written.
  Defaults to the current working directory.

## Value

Invisibly, `NULL`.

## Examples

``` r
dir <- tempfile("stac-")
cat <- new_catalog("c", "Catalog", "An example catalog")
col <- new_collection("col", "Collection", "An example collection")
item <- new_item("item-1", bbox = c(-50, -10, -49, -9))

col <- add_items(col, item)
cat <- add_collection(cat, col)
stac_save(catalog = cat, collection = col, items = item, root_dir = dir)
```
