# STAC style objects for thumbnails

Helpers to describe how a raster should be rendered into a thumbnail.

- `stac_style()`: builds a style object from explicit parameters. This
  function has no external dependencies.

- `qml_to_style()`: parses a QGIS Layer Style file (`.qml`) into a style
  object. This function requires the optional xml2 package.

If xml2 is not installed, build the style manually with `stac_style()`
instead of reading a `.qml` file.

## Usage

``` r
stac_style(
  min = NULL,
  max = NULL,
  pmin = NULL,
  pmax = NULL,
  palette = NULL,
  legend = NULL
)

qml_to_style(qml_path)
```

## Arguments

- min:

  Minimum value for stretching or color mapping.

- max:

  Maximum value for stretching or color mapping.

- pmin:

  Percentile minimum for stretching (e.g. `0.02`).

- pmax:

  Percentile maximum for stretching (e.g. `0.98`).

- palette:

  Color palette name or a vector of colors.

- legend:

  A `data.frame` with `value` and `color` columns for categorical data.

- qml_path:

  A `character` path or URL to a QGIS `.qml` style file.

## Value

A `list` with style parameters: a `categorical`, `continuous`, or
`simple` style depending on the inputs.

## Examples

``` r
# Build a style directly (no optional dependency required)
stac_style(min = 0, max = 255, palette = c("black", "white"))
#> $type
#> [1] "simple"
#> 
#> $min
#> [1] 0
#> 
#> $max
#> [1] 255
#> 
#> $palette
#> [1] "black" "white"
#> 

# Parse a QML file (requires xml2)
if (requireNamespace("xml2", quietly = TRUE)) {
  qml <- system.file("extdata/example.qml", package = "rstatic")
  if (nzchar(qml)) {
    qml_to_style(qml)
  }
}
#> $type
#> [1] "categorical"
#> 
#> $legend
#>   value     color
#> 1     1 #1f78b4FF
#> 2     2 #33a02cFF
#> 3     3 #e31a1cFF
#> 
```
