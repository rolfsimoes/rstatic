# Print STAC documents

Minimalist, `tibble`-inspired S3 print methods for rstatic STAC
documents and their child elements (`doc_link`, `doc_links`, and
`doc_asset`). Output is lightly styled with the cli package and degrades
gracefully when a terminal does not support colors.

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

# S3 method for class 'doc_link'
print(x, ...)

# S3 method for class 'doc_links'
print(x, n = 10, ...)
```

## Arguments

- x:

  A STAC document or element: `doc_catalog`, `doc_collection`,
  `doc_item`, `doc_asset`, `doc_link`, or `doc_links`.

- ...:

  Additional arguments (currently ignored).

- n:

  Maximum number of entries to print for `doc_links`. Defaults to `10`.

## Value

Invisibly, `x`.

## Examples

``` r
print(new_catalog("c", "Catalog", "An example catalog"))
#> # STAC Catalog c
#>   title        Catalog
#>   description  An example catalog
#>   links        2
print(new_collection("col", "Collection", "An example collection"))
#> # STAC Collection col
#>   title        Collection
#>   description  An example collection
#>   license      proprietary
#>   links        3
print(new_asset("data.tif", title = "Data"))
#> # STAC Asset Data
#>   href   data.tif
#>   type   image/tiff; application=geotiff
#>   roles  data
```
