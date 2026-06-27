# Add a link to a STAC document

Pure builder that appends a link to a STAC document's `links` list. The
document is returned unchanged if a link with the same `href` already
exists. No disk I/O is performed.

## Usage

``` r
stac_add_link(doc, rel, href, type = "application/json", title = NULL)
```

## Arguments

- doc:

  A STAC document (`doc_catalog`, `doc_collection`, or `doc_item`).

- rel:

  A `character` link relation (`self`, `root`, `parent`, `child`,
  `item`, `collection`, etc.).

- href:

  A `character` link target (path or URL). Relative paths are
  recommended for static catalogs.

- type:

  A `character` media type. Defaults to `"application/json"`.

- title:

  An optional `character` human-readable title for the link.

## Value

The updated STAC document, with the new link appended and the
appropriate `doc_*` class preserved.

## Examples

``` r
cat <- new_catalog("cat", "Catalog", "Example")
cat <- stac_add_link(cat, "child", "collections/col/collection.json",
                     title = "My Collection")

item <- new_item("i", bbox = c(0, 0, 1, 1))
item <- stac_add_link(item, "derived_from", "source.json")
```
