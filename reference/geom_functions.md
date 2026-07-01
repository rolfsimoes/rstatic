# Spatial helpers for STAC documents

Helper functions to derive the spatial metadata required by STAC items.

- `extract_bbox()`: reads a raster (local or remote) and returns its
  bounding box in WGS84 (`EPSG:4326`). This function requires the
  optional terra package. It is generic: pass either a `character` path
  or URL, or a `doc_asset` from
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md),
  in which case the raster is read from the asset's resolved
  `local_path` (see
  [`update_root()`](https://rolfsimoes.github.io/rstatic/reference/update_root.md))
  or its `href`.

- `as_geometry()`: converts a bounding box into a GeoJSON `Polygon`
  geometry. This function has no external dependencies.

If terra is not installed, you can still build items by passing a
bounding box (a numeric vector `c(xmin, ymin, xmax, ymax)`) directly to
[`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
and, optionally, a geometry created with `as_geometry()`.

## Usage

``` r
extract_bbox(x)

# S3 method for class 'character'
extract_bbox(x)

# S3 method for class 'doc_asset'
extract_bbox(x)

as_geometry(bbox)
```

## Arguments

- x:

  A `character` path or URL to a raster file readable by terra, or a
  `doc_asset` from
  [`new_asset()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md).
  Remote `http(s)` URLs are accessed through GDAL's `/vsicurl/` driver.

- bbox:

  A numeric vector of length 4 with the bounding box coordinates in the
  order `c(xmin, ymin, xmax, ymax)`.

## Value

- `extract_bbox()`: a numeric vector `c(xmin, ymin, xmax, ymax)`, or
  `NULL` if the raster could not be read.

- `as_geometry()`: a `list` representing a GeoJSON `Polygon` geometry,
  or `NULL` if `bbox` is `NULL`.

## Examples

``` r
# as_geometry() works without any optional dependency
bbox <- c(-50, -10, -49, -9)
as_geometry(bbox)
#> <GeoJSON Geometry: Polygon>
#>   bbox: -50, -10, -49, -9

# extract_bbox() requires terra
if (requireNamespace("terra", quietly = TRUE)) {
  f <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.tif",
                    package = "rstatic")
  if (nzchar(f)) {
    # from a path or URL
    extract_bbox(f)
    # or directly from an asset
    extract_bbox(new_asset(f, title = "B04"))
  }
}
#>       xmin       ymin       xmax       ymax 
#> -63.636579  -8.630257 -63.418217  -8.412882 
```
