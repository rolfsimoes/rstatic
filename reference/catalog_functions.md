# Create STAC catalogs

Pure builder for a STAC `Catalog` document. It does not touch disk; use
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
to persist and
[`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md)
to load an existing catalog.

## Usage

``` r
new_catalog(id, title, description, stac_version = "1.0.0", ...)
```

## Arguments

- id:

  A `character` identifier for the catalog.

- title:

  A `character` human-readable title.

- description:

  A `character` description of the catalog.

- stac_version:

  A `character` STAC specification version. Defaults to `"1.0.0"`.

- ...:

  Additional named fields to add to the catalog document.

## Value

A `doc_catalog` object.

## Examples

``` r
cat <- new_catalog(
  id = "my-catalog",
  title = "My Catalog",
  description = "An example STAC catalog"
)
cat$type
#> [1] "Catalog"

# Write a root catalog to a temporary directory
dir <- tempfile("stac-")
stac_save(catalog = cat, root_dir = dir)
```
