# Convert a QGIS QML raster style to a thumbnail style

`qml_to_style()` reads a supported QGIS `.qml` raster style and converts
it to the same normalized style object produced by
[`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md).

This function supports a limited subset of QGIS raster renderers:
paletted, single-band gray, and single-band pseudocolor. Other renderers
are rejected with a clear error.

The function is a converter, not a general QML parser. QGIS-specific
details are normalized to the `rstatic` style model. It requires the
optional xml2 package; if xml2 is not installed, build the style
manually with
[`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md).

## Usage

``` r
qml_to_style(qml_path)
```

## Arguments

- qml_path:

  A `character` path or URL to a QGIS `.qml` file.

## Value

A normalized `rstatic_style` object, as produced by
[`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md).

## Examples

``` r
if (requireNamespace("xml2", quietly = TRUE)) {
  qml <- system.file("extdata/s2/S2_MSI_20LMR_B04_2022-07-16.qml",
                      package = "rstatic")
  if (nzchar(qml)) {
    qml_to_style(qml)
  }
}
#> <Style: continuous>
#>   stretch: min=192, max=1371
#>   palette: #30123b, #28bceb, #a4fc3c, #fb7e21, #7a0403
```
