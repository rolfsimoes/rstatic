# List and filter the links of a STAC document

Returns the links of a STAC document as a plain `list`, optionally
keeping only those that satisfy one or more filter expressions. Each
expression in `...` is evaluated against a single link, with the link's
fields (`rel`, `href`, `type`, `title`) available as names, and the
expressions are combined with logical AND. With no expressions, every
link is returned.

This mirrors the ergonomics of `rstac::links()`: instead of writing
`Filter(function(l) l$rel == "child", doc$links)`, you write
`list_links(doc, rel == "child")`.

A link whose fields make an expression error (for example a link that
has no `title`) is treated as not matching, rather than raising an
error. Variables from the calling scope may be used in the expressions.

## Usage

``` r
list_links(x, ...)
```

## Arguments

- x:

  A STAC document (`doc_catalog`, `doc_collection`, or `doc_item`), or a
  bare `list` of links.

- ...:

  Optional filter expressions evaluated against each link, e.g.
  `rel == "child"`. Combined with logical AND.

## Value

A `list` of links (each element as stored on the document). The list is
empty when nothing matches.

## Examples

``` r
catalog <- new_catalog("cat", "Catalog", "Example")
catalog <- add_collection(catalog, new_collection("a", "A", "First"))
catalog <- add_collection(catalog, new_collection("b", "B", "Second"))

# All links
list_links(catalog)
#> [[1]]
#> <STAC Link: self>
#>   href: catalog.json
#>   type: application/json
#> 
#> [[2]]
#> <STAC Link: root>
#>   href: catalog.json
#>   type: application/json
#> 
#> [[3]]
#> <STAC Link: child>
#>   href: collections/a/collection.json
#>   type: application/json
#>   title: A
#> 
#> [[4]]
#> <STAC Link: child>
#>   href: collections/b/collection.json
#>   type: application/json
#>   title: B
#> 

# Only the child links
list_links(catalog, rel == "child")
#> [[1]]
#> <STAC Link: child>
#>   href: collections/a/collection.json
#>   type: application/json
#>   title: A
#> 
#> [[2]]
#> <STAC Link: child>
#>   href: collections/b/collection.json
#>   type: application/json
#>   title: B
#> 

# Combine predicates (logical AND)
list_links(catalog, rel == "child", type == "application/json")
#> [[1]]
#> <STAC Link: child>
#>   href: collections/a/collection.json
#>   type: application/json
#>   title: A
#> 
#> [[2]]
#> <STAC Link: child>
#>   href: collections/b/collection.json
#>   type: application/json
#>   title: B
#> 
```
