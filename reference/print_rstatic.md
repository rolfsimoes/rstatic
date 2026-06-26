# Print STAC documents

Compact S3 print methods for rstatic STAC documents.

## Usage

``` r
# S3 method for class 'doc_catalog'
print(x, ...)

# S3 method for class 'doc_collection'
print(x, ...)

# S3 method for class 'doc_item'
print(x, ...)
```

## Arguments

- x:

  A `doc_catalog`, `doc_collection`, or `doc_item` object.

- ...:

  Additional arguments (currently ignored).

## Value

Invisibly, `x`.

## Examples

``` r
print(new_catalog("c", "Catalog", "An example catalog"))
#> <STAC Catalog>
#>   id:    c
#>   title: Catalog
#>   links: 2
print(new_collection("col", "Collection", "An example collection"))
#> <STAC Collection>
#>   id:    col
#>   title: Collection
#>   links: 3
```
