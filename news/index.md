# Changelog

## rstatic 0.1.0.9000

### New features

- STAC links and assets now receive their own S3 classes (`doc_link`,
  `doc_links`, `doc_asset`), and child elements are classed recursively
  so that [`print()`](https://rdrr.io/r/base/print.html) and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) dispatch
  correctly on nested objects.
- Added [`print()`](https://rdrr.io/r/base/print.html) methods for
  `doc_catalog`, `doc_collection`, `doc_item`, `doc_asset`, `doc_link`,
  and `doc_links` with a minimalist, tibble-inspired style using `cli`.
- Added
  [`plot.doc_asset()`](https://rolfsimoes.github.io/rstatic/reference/plot_rstatic.md)
  to render PNG, JPEG, and GeoTIFF assets.
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  now stores the generated PNG path in a `local_path` attribute so
  thumbnails can be plotted from their relative `href`.

### Documentation

- The package vignette now calls `plot(thumb)` to display the rendered
  thumbnail image.
- Updated `_pkgdown.yml` with missing reference topics (`plot_rstatic`,
  `stac_add_asset`, `stac_add_link`).
- The thumbnail style created in the vignette is now passed to
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md).

## rstatic 0.0.0.9000

### Main features

- Primitives to build and serialize static STAC 1.0.0 documents:
  [`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md),
  [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md),
  [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  and link helpers.
- Persistence helpers to write JSON documents and update parent links
  ([`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md),
  [`stac_init()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md),
  [`stac_add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md),
  [`stac_add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  [`stac_add_asset()`](https://rolfsimoes.github.io/rstatic/reference/stac_add_asset.md),
  [`stac_add_link()`](https://rolfsimoes.github.io/rstatic/reference/stac_add_link.md)).
- Spatial helpers
  [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  and
  [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  for bounding boxes and GeoJSON geometries (optional `terra` support).
- Thumbnail and style helpers:
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md),
  [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/style_functions.md)
  (optional `xml2` support), and
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  (optional `terra` support).
- Package documentation, README, vignette, pkgdown site, and GitHub
  Actions CI workflows.
