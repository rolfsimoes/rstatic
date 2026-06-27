# Create and initialize STAC catalogs

Functions to build a STAC `Catalog` document.

- `new_catalog()`: creates an in-memory `Catalog` object.

- `stac_init()`: creates (or updates) the root catalog on disk under a
  `stac/` directory, preserving any existing child links.

## Usage

``` r
new_catalog(id, title, description, stac_version = "1.0.0", ...)

stac_init(id, title, description, root_dir = ".")
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

- root_dir:

  A `character` directory under which the catalog is written. Defaults
  to the current working directory.

## Value

- `new_catalog()`: a `doc_catalog` object.

- `stac_init()`: invisibly, the saved `doc_catalog` object.

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
stac_init(
  id = "my-catalog",
  title = "My Catalog",
  description = "An example STAC catalog",
  root_dir = dir
)
#> Catalog my-catalog initialized/updated at /tmp/RtmpHpTfbU/stac-1cc59a89860/stac/catalog.json
```
