# Changelog

## rstatic 0.3.0.9000

### New features

- Added
  [`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md),
  which re-points a document’s assets at their on-disk locations under a
  local root directory, following the canonical static catalog layout.
  It sets each asset’s `local_path` attribute so files written by
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  – such as a rendered thumbnail – can be resolved by
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and other
  local readers. It is an S3 generic: for a `doc_item` the paths resolve
  under the item directory (using the item’s own `collection` field),
  and for a `doc_collection` under the collection directory (covering a
  propagated collection thumbnail).
- [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  gained an optional `collection` argument (a `doc_collection` or a
  `character` id) that records the item’s top-level `collection` field.
  STAC requires this field whenever the item links to a collection; when
  omitted,
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  still stamps it from the `collection` it is given.
- [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  and
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  are now S3 generics. In addition to a `character` path or URL, both
  accept a `doc_asset` from
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  in which case the raster is read from the asset’s resolved
  `local_path` (see
  [`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md))
  or its `href`.
- Added
  [`list_links()`](https://rolfsimoes.github.io/rstatic/reference/list_links.md),
  which returns a document’s links as a plain `list` and filters them
  with expressions evaluated against each link,
  e.g. `list_links(catalog, rel == "child")`. Multiple expressions
  combine with logical AND; with none, all links are returned.
- The [`print()`](https://rdrr.io/r/base/print.html) methods for
  `doc_collection` and `doc_item` now summarize spatial and temporal
  extent. Collections show the union `bbox` and `interval` of their
  extent; items show their `bbox` and a `datetime` that prefers a
  `start_datetime`/`end_datetime` range over a single `datetime`. Both
  now close with a dimmed, complete list of field names.

### Bug fixes

- [`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  now records `datetime` as `null` (rather than omitting the field) when
  only a `start_datetime`/`end_datetime` range is supplied, so the
  written item is valid per the STAC specification, which requires
  `datetime` to be present.
- [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  now warns when an item’s own `collection` field differs from the
  `collection` argument, instead of silently writing the item under its
  own collection’s path. The item’s value remains authoritative.

### Breaking changes

- The first argument of
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  was renamed from `asset_href` to `x` to support method dispatch. Calls
  that named the argument (`new_thumbnail(asset_href = ...)`) must be
  updated; positional calls are unaffected.

### Documentation

- Reworked the package vignette around the shipped Sentinel-2 example
  data: a categorical land-cover map and a continuous B04 (red band)
  preview, each rendered as a thumbnail and linked into the catalog as
  its own collection. The thumbnails are now plotted by resolving their
  on-disk path with
  [`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md).

## rstatic 0.2.0.9000

### Breaking changes

- The package was reorganized into a pure functional core and a thin I/O
  shell. Constructors (`new_*()`) and builders (`add_*()`) no longer
  touch disk; reading and writing happen only in
  [`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md)
  and
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md).
- The eager `stac_add_*()` helpers were renamed to `add_*()`
  ([`add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md),
  [`add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  [`add_asset()`](https://rolfsimoes.github.io/rstatic/reference/add_asset.md),
  [`add_link()`](https://rolfsimoes.github.io/rstatic/reference/add_link.md))
  and are now pure: each updates an in-memory document and returns it
  instead of writing to disk. Any link deduplication is scoped within a
  single `rel`.
- `stac_init()` was removed. Use
  `stac_read(path, default = new_catalog(...))` to load an existing
  catalog, or fall back to a freshly built one, without writing.
- [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  is now the only writer and performs a pure overwrite: it persists
  exactly the documents it is given, with no implicit disk reads or
  merges. To accumulate state across runs, read the existing document
  first with
  [`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md),
  extend it with the `add_*()` builders, then save. Cross-document links
  (`self`, `root`, `parent`, and relative hrefs) are synthesized at save
  time rather than stored in memory.

### New features

- Added
  [`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md),
  the package’s only reader. It loads a `Catalog`, `Collection`, or
  `Item` JSON document and returns the corresponding in-memory object,
  or returns a supplied `default` when the file does not exist –
  supporting a load-or-create pattern without ever writing to disk.
- [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  is now a pure builder. Instead of rendering immediately, it returns an
  asset carrying the render intent (source raster, width, and style),
  which
  [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  materializes into a PNG when the owning item is written (requires
  `terra`).

### Documentation and data

- Replaced the bundled example data with a Sentinel-2 L2A subset over
  tile `20LMR` (Rondônia, Brazil): a categorical land-cover
  classification and the B04 (red) band, each with a matching QGIS
  `.qml` style.
- Rewrote the vignette and README around the pure-core / I/O-shell
  workflow and the new example data.

## rstatic 0.1.0.9000

### Breaking changes

- [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md)
  was redesigned around an explicit, backend-independent style object.
  The `type` and `legend` arguments were removed. The rendering mode
  (categorical, continuous, or RGB) is now inferred from the parameters:
  supply `values`/`colors`/`labels` for categorical styles, `min`/`max`
  or `pmin`/`pmax` (with an optional `palette`) for continuous styles,
  and three `bands` for RGB. New `bands`, `values`, `colors`, `labels`,
  `nodata`, `opacity`, and `gamma` arguments were added. The function
  now returns a classed `rstatic_style` object instead of a plain list.
- [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md)
  is now a thin converter that detects the QGIS raster renderer and
  delegates to
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md).
  It supports the `paletted`, `singlebandgray`, and
  `singlebandpseudocolor` renderers and fails clearly on anything else,
  including per-class alpha, discrete pseudocolor interpolation, and
  unsupported transparency rules.

### New features

- [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  applies an `rstatic_style` object with a defined rendering order
  (nodata mask, band selection, stretch or value mapping,
  palette/colors, opacity), with support for `gamma` correction and RGB
  composites.
- Added a [`print()`](https://rdrr.io/r/base/print.html) method for
  `rstatic_style` objects.
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
  `stac_init()`, `stac_add_collection()`, `stac_add_items()`,
  `stac_add_asset()`, `stac_add_link()`).
- Spatial helpers
  [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  and
  [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  for bounding boxes and GeoJSON geometries (optional `terra` support).
- Thumbnail and style helpers:
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md),
  [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md)
  (optional `xml2` support), and
  [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  (optional `terra` support).
- Package documentation, README, vignette, pkgdown site, and GitHub
  Actions CI workflows.
