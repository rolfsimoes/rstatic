# Package index

## Catalogs

- [`new_catalog()`](https://rolfsimoes.github.io/rstatic/reference/catalog_functions.md)
  : Create STAC catalogs
- [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
  [`add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
  : Create and attach STAC collections

## Collections

- [`new_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
  [`add_collection()`](https://rolfsimoes.github.io/rstatic/reference/collection_functions.md)
  : Create and attach STAC collections
- [`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  : Create STAC items, properties, and assets

## Items, properties and assets

- [`new_properties()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  [`add_items()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
  : Create STAC items, properties, and assets
- [`add_asset()`](https://rolfsimoes.github.io/rstatic/reference/add_asset.md)
  : Add an asset to a STAC document
- [`add_link()`](https://rolfsimoes.github.io/rstatic/reference/add_link.md)
  : Add a link to a STAC document
- [`list_links()`](https://rolfsimoes.github.io/rstatic/reference/list_links.md)
  : List and filter the links of a STAC document

## Persistence

- [`stac_save()`](https://rolfsimoes.github.io/rstatic/reference/stac_save.md)
  : Save STAC documents to their canonical paths
- [`stac_read()`](https://rolfsimoes.github.io/rstatic/reference/stac_read.md)
  : Read a STAC document from disk

## Spatial helpers

- [`extract_bbox()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  [`as_geometry()`](https://rolfsimoes.github.io/rstatic/reference/geom_functions.md)
  : Spatial helpers for STAC documents

## Styles and thumbnails

- [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md)
  : Define a raster style for thumbnail rendering
- [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md)
  : Convert a QGIS QML raster style to a thumbnail style
- [`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
  : Describe a thumbnail asset
- [`plot(`*`<doc_asset>`*`)`](https://rolfsimoes.github.io/rstatic/reference/plot_rstatic.md)
  : Plot a STAC asset
- [`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md)
  : Resolve a document's asset paths under a local root

## Printing

- [`print(`*`<doc_catalog>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_collection>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_item>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_asset>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_geometry>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_link>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  [`print(`*`<doc_links>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print_rstatic.md)
  : Print STAC documents
- [`print(`*`<rstatic_style>`*`)`](https://rolfsimoes.github.io/rstatic/reference/print.rstatic_style.md)
  : Print a raster style object
