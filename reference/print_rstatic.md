# Print STAC documents

Minimalist, `tibble`-inspired S3 print methods for rstatic STAC
documents and their child elements (`doc_link`, `doc_links`, and
`doc_asset`). Output is lightly styled with the cli package and degrades
gracefully when a terminal does not support colors.

A curated set of fields is shown per document. `doc_collection` and
`doc_item` also summarize their spatial and temporal extent: the
collection prints the union `bbox` and `interval` of its extent, and the
item prints its `bbox` and a `datetime` that prefers a
`start_datetime`/`end_datetime` range when present. Both close with a
dimmed, complete list of their field names, so every accessible field is
discoverable without overwhelming the summary.

## Usage

``` r
# S3 method for class 'doc_catalog'
print(x, ...)

# S3 method for class 'doc_collection'
print(x, ...)

# S3 method for class 'doc_item'
print(x, ...)

# S3 method for class 'doc_asset'
print(x, ...)

# S3 method for class 'doc_geometry'
print(x, ...)

# S3 method for class 'doc_link'
print(x, ...)

# S3 method for class 'doc_links'
print(x, n = 10, ...)
```

## Arguments

- x:

  A STAC document or element: `doc_catalog`, `doc_collection`,
  `doc_item`, `doc_asset`, `doc_link`, `doc_links`, or `doc_geometry`.

- ...:

  Additional arguments (currently ignored).

- n:

  Maximum number of entries to print for `doc_links`. Defaults to `10`.

## Value

Invisibly, `x`.

## Examples

``` r
print(new_catalog("c", "Catalog", "An example catalog"))
#> <STAC Catalog: c>
#>   title: Catalog
#>   description: An example catalog
#>   links: 2
print(new_collection("col", "Collection", "An example collection"))
#> <STAC Collection: col>
#>   title: Collection
#>   description: An example collection
#>   license: proprietary
#>   links: 3
#>   fields: description, extent, id, license, links, stac_version, title, type
print(new_asset("data.tif", title = "Data"))
#> <STAC Asset: Data>
#>   href: data.tif
#>   type: image/tiff; application=geotiff
#>   roles: data
```
