# Read a STAC document from disk

Reads a STAC `Catalog`, `Collection`, or `Item` JSON file from disk and
returns it as an in-memory `doc_*` object. This is the only reader in
the package; together with
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
it forms the effectful boundary around the pure constructors (`new_*`)
and builders (`add_*`).

When the file does not exist, `stac_read()` returns `default` if one is
supplied (e.g. a freshly built
[`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md)),
otherwise it errors. This supports the load-or-create pattern without
ever writing to disk:

    catalog <- stac_read(
      file.path(root, "stac", "catalog.json"),
      default = new_catalog("my-catalog", "My Catalog", "...")
    )

## Usage

``` r
stac_read(path, default = NULL)
```

## Arguments

- path:

  A `character` path to a STAC JSON file.

- default:

  An optional in-memory `doc_*` object returned when `path` does not
  exist. If `NULL` (the default), a missing file is an error.

## Value

A `doc_catalog`, `doc_collection`, or `doc_item` object.

## Examples

``` r
dir <- tempfile("stac-")
cat <- new_catalog("c", "Catalog", "An example catalog")
stac_save(catalog = cat, root_dir = dir)

# Read it back
path <- file.path(dir, "stac", "catalog.json")
stac_read(path)$id
#> [1] "c"

# Missing file with a default returns the default, without writing
stac_read(file.path(dir, "missing.json"),
          default = new_catalog("fallback", "Fallback", "..."))$id
#> [1] "fallback"
```
