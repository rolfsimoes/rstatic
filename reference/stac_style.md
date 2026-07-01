# Define a raster style for thumbnail rendering

`stac_style()` creates a normalized style object used by
[`new_thumbnail()`](https://rolfsimoes.github.io/rstatic/reference/new_thumbnail.md)
to render raster previews. The style describes how raster values are
mapped to thumbnail pixels. It does not render the image.

Continuous styles use `min`/`max` or `pmin`/`pmax`, optionally with a
color ramp supplied by `palette`. RGB rendering is represented by
passing three band names to `bands`.

Categorical styles use explicit `values` and `colors` mappings. Values
do not need to be sequential. Optional `labels` describe the categorical
values and may be used to derive legends.

`nodata` is applied before any rendering rule and is rendered as
transparent.

## Usage

``` r
stac_style(
  bands = NULL,
  min = NULL,
  max = NULL,
  pmin = NULL,
  pmax = NULL,
  palette = NULL,
  values = NULL,
  colors = NULL,
  labels = NULL,
  nodata = NULL,
  opacity = NULL,
  gamma = NULL
)
```

## Arguments

- bands:

  Optional band name or vector of three band names. Three bands indicate
  RGB rendering.

- min:

  Minimum value used for continuous stretching. Must have length one or
  three. Length three is only allowed when `bands` has length three.

- max:

  Maximum value used for continuous stretching. Must have length one or
  three. Length three is only allowed when `bands` has length three.

- pmin:

  Lower percentile used to derive the stretch minimum from the image.
  Must have length one or three. Length three is only allowed when
  `bands` has length three.

- pmax:

  Upper percentile used to derive the stretch maximum from the image.
  Must have length one or three. Length three is only allowed when
  `bands` has length three.

- palette:

  Color ramp for continuous single-band rendering. It can be a known
  palette name or a vector of colors.

- values:

  Raster values for categorical rendering.

- colors:

  Colors associated with `values`.

- labels:

  Optional labels associated with `values`. Defaults to
  `as.character(values)`.

- nodata:

  Optional value to render as transparent. It is applied before all
  other rendering rules.

- opacity:

  Optional global opacity between `0` and `1` for valid pixels.

- gamma:

  Optional gamma correction for continuous rendering. It must not be
  used with categorical styles.

## Value

A normalized `rstatic_style` object. The object also carries a
mode-specific subclass: `rstatic_style_categorical`,
`rstatic_style_continuous`, or `rstatic_style_rgb`.

## Examples

``` r
# Continuous grayscale stretch
stac_style(min = 0, max = 0.5, palette = c("black", "white"))
#> <Style: continuous>
#>   stretch: min=0, max=0.5
#>   palette: black, white

# Single-band percentile stretch
stac_style(bands = "B04", pmin = 0.02, pmax = 0.98, palette = "viridis")
#> <Style: continuous>
#>   bands: B04
#>   stretch: pmin=0.02, pmax=0.98
#>   palette: viridis

# RGB composite from three bands
stac_style(bands = c("B04", "B03", "B02"), pmin = 0.02, pmax = 0.98)
#> <Style: rgb>
#>   bands: B04, B03, B02
#>   stretch: pmin=0.02, pmax=0.98

# Categorical land-cover mapping
stac_style(
  values = c(1, 2, 3),
  colors = c("#c14d00", "#367906", "#7cc900"),
  labels = c("Crop", "Forest", "Grassland"),
  nodata = 0
)
#> <Style: categorical>
#>   labels: Crop, Forest, Grassland
#>   nodata: 0
```
