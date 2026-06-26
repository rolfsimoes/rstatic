# Save a STAC document to its canonical path

Writes a STAC `Catalog`, `Collection`, or `Item` to disk following the
canonical static catalog layout:

- `Catalog` -\> `stac/catalog.json`

- `Collection` -\> `stac/collections/{id}/collection.json`

- `Item` -\> `stac/collections/{collection}/items/{id}/item.json`

Items must carry a `collection` field so their path can be resolved.

## Usage

``` r
stac_save(obj, root_dir = ".")
```

## Arguments

- obj:

  A `doc_catalog`, `doc_collection`, or `doc_item` object.

- root_dir:

  A `character` directory under which the `stac/` tree is written.
  Defaults to the current working directory.

## Value

Invisibly, the saved object (re-classed as an rstatic document).

## Examples

``` r
dir <- tempfile("stac-")
cat <- new_catalog("c", "Catalog", "An example catalog")
stac_save(cat, root_dir = dir)
```
