# Add an asset to a STAC document

Pure builder that attaches an asset to a STAC `Item` or `Collection`.
Assets set at creation time via
[`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
can be complemented or overwritten later with this function. No disk I/O
is performed.

## Usage

``` r
add_asset(doc, key, asset)
```

## Arguments

- doc:

  A STAC document (`doc_item` or `doc_collection`).

- key:

  A `character` name for the asset in the document's `assets` map.

- asset:

  A `list` describing the asset, as from
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md).

## Value

The updated STAC document, with `asset` stored under `doc$assets[[key]]`
and the appropriate class preserved.

## Examples

``` r
item <- new_item("i", bbox = c(0, 0, 1, 1))
item <- add_asset(item, "data", new_asset("data.tif"))
```
