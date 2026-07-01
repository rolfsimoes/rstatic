# Print a raster style object

Prints a compact summary of an `rstatic_style` object, including its
rendering mode and the parameters relevant to that mode.

## Usage

``` r
# S3 method for class 'rstatic_style'
print(x, ...)
```

## Arguments

- x:

  An `rstatic_style` object from
  [`stac_style()`](https://rolfsimoes.github.io/rstatic/reference/stac_style.md)
  or
  [`qml_to_style()`](https://rolfsimoes.github.io/rstatic/reference/qml_to_style.md).

- ...:

  Ignored.

## Value

Invisibly, `x`.

## Examples

``` r
print(stac_style(min = 0, max = 1, palette = c("black", "white")))
#> <Style: continuous>
#>   stretch: min=0, max=1
#>   palette: black, white
```
