# rstatic 0.1.0.9000

## Breaking changes

- `stac_style()` was redesigned around an explicit, backend-independent style object. The `type` and `legend` arguments were removed. The rendering mode (categorical, continuous, or RGB) is now inferred from the parameters: supply `values`/`colors`/`labels` for categorical styles, `min`/`max` or `pmin`/`pmax` (with an optional `palette`) for continuous styles, and three `bands` for RGB. New `bands`, `values`, `colors`, `labels`, `nodata`, `opacity`, and `gamma` arguments were added. The function now returns a classed `rstatic_style` object instead of a plain list.
- `qml_to_style()` is now a thin converter that detects the QGIS raster renderer and delegates to `stac_style()`. It supports the `paletted`, `singlebandgray`, and `singlebandpseudocolor` renderers and fails clearly on anything else, including per-class alpha, discrete pseudocolor interpolation, and unsupported transparency rules.

## New features

- `new_thumbnail()` applies an `rstatic_style` object with a defined rendering order (nodata mask, band selection, stretch or value mapping, palette/colors, opacity), with support for `gamma` correction and RGB composites.
- Added a `print()` method for `rstatic_style` objects.
- STAC links and assets now receive their own S3 classes (`doc_link`, `doc_links`, `doc_asset`), and child elements are classed recursively so that `print()` and `plot()` dispatch correctly on nested objects.
- Added `print()` methods for `doc_catalog`, `doc_collection`, `doc_item`, `doc_asset`, `doc_link`, and `doc_links` with a minimalist, tibble-inspired style using `cli`.
- Added `plot.doc_asset()` to render PNG, JPEG, and GeoTIFF assets. `new_thumbnail()` now stores the generated PNG path in a `local_path` attribute so thumbnails can be plotted from their relative `href`.

## Documentation

- The package vignette now calls `plot(thumb)` to display the rendered thumbnail image.
- Updated `_pkgdown.yml` with missing reference topics (`plot_rstatic`, `stac_add_asset`, `stac_add_link`).
- The thumbnail style created in the vignette is now passed to `new_thumbnail()`.

# rstatic 0.0.0.9000

## Main features

- Primitives to build and serialize static STAC 1.0.0 documents: `new_catalog()`, `new_collection()`, `new_item()`, `new_asset()`, and link helpers.
- Persistence helpers to write JSON documents and update parent links (`stac_save()`, `stac_init()`, `stac_add_collection()`, `stac_add_items()`, `stac_add_asset()`, `stac_add_link()`).
- Spatial helpers `extract_bbox()` and `as_geometry()` for bounding boxes and GeoJSON geometries (optional `terra` support).
- Thumbnail and style helpers: `stac_style()`, `qml_to_style()` (optional `xml2` support), and `new_thumbnail()` (optional `terra` support).
- Package documentation, README, vignette, pkgdown site, and GitHub Actions CI workflows.
