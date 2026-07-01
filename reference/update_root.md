# Resolve a document's asset paths under a local root

Returns a copy of an in-memory STAC document whose assets point at their
on-disk locations under a local `root_dir`, following the canonical
static catalog layout used by
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md).
For every asset with a relative `href`, the `local_path` attribute is
set to the file's location under `root_dir`; assets whose `href` is
already an absolute path or a URL are returned unchanged.

`update_root()` is generic and dispatches on the document class:

- `doc_item`: assets resolve under
  `root_dir/stac/collections/<collection>/items/<id>/`. The collection
  is read from the item's own `collection` field, so build the item with
  `new_item(collection = ...)` (or save it first, which stamps the
  field).

- `doc_collection`: assets resolve under
  `root_dir/stac/collections/<id>/`, which covers a collection-level
  thumbnail propagated from its items.

It is a pure helper: it reads no raster and writes no file. Its purpose
is to make files produced by
[`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
– such as a thumbnail PNG rendered into the item directory – resolvable
by [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and other
local readers, which consult an asset's `local_path` attribute before
falling back to its `href`.

## Usage

``` r
update_root(x, root_dir)

# S3 method for class 'doc_item'
update_root(x, root_dir)

# S3 method for class 'doc_collection'
update_root(x, root_dir)
```

## Arguments

- x:

  A `doc_item` from
  [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  or a `doc_collection` from
  [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md).

- root_dir:

  A `character` directory under which the `stac/` tree was written by
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md).

## Value

The document `x`, with the `local_path` attribute set on each asset that
has a relative `href`.

## Examples

``` r
root <- tempfile("stac-")
col <- new_collection("land-cover", "Land Cover", "Example collection")
item <- new_item(
  "land-cover-2022",
  bbox = c(-50, -10, -49, -9),
  collection = col,
  assets = list(data = new_asset("data.tif", title = "Data"))
)
stac_save(collection = col, items = item, root_dir = root)

item <- update_root(item, root)
attr(item$assets$data, "local_path")
#> [1] "/tmp/Rtmplox5oF/stac-1d2ba69ac53/stac/collections/land-cover/items/land-cover-2022/data.tif"
```
