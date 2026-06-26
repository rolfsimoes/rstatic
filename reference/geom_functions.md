# Spatial helpers for STAC documents

Helper functions to derive the spatial metadata required by STAC items.

- `extract_bbox()`: reads a raster (local or remote) and returns its
  bounding box in WGS84 (`EPSG:4326`). This function requires the
  optional terra package.

- `as_geometry()`: converts a bounding box into a GeoJSON `Polygon`
  geometry. This function has no external dependencies.

If terra is not installed, you can still build items by passing a
bounding box (a numeric vector `c(xmin, ymin, xmax, ymax)`) directly to
[`new_item()`](https://rolfsimoes.github.io/rstatic/reference/item_functions.md)
and, optionally, a geometry created with `as_geometry()`.

## Usage

``` r
extract_bbox(url)

as_geometry(bbox)
```

## Arguments

- url:

  A `character` path or URL to a raster file readable by terra. Remote
  `http(s)` URLs are accessed through GDAL's `/vsicurl/` driver.

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
#> $type
#> [1] "Polygon"
#> 
#> $coordinates
#> $coordinates[[1]]
#> $coordinates[[1]][[1]]
#> [1] -50 -10
#> 
#> $coordinates[[1]][[2]]
#> [1] -49 -10
#> 
#> $coordinates[[1]][[3]]
#> [1] -49  -9
#> 
#> $coordinates[[1]][[4]]
#> [1] -50  -9
#> 
#> $coordinates[[1]][[5]]
#> [1] -50 -10
#> 
#> 
#> 

# extract_bbox() requires terra
if (requireNamespace("terra", quietly = TRUE)) {
  f <- system.file("extdata/example.tif", package = "rstatic")
  if (nzchar(f)) {
    extract_bbox(f)
  }
}
#>       xmin       ymin       xmax       ymax 
#> -63.636579  -8.630220 -63.450282  -8.491029 
```
