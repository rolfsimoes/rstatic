# AGENTS.md

## Purpose

This file defines general development rules for this R package.

Follow these rules unless the task gives more specific instructions.

## First steps

Before changing code:

1. Inspect the current implementation.
2. Read the related tests.
3. Read the related documentation.
4. Check `DESCRIPTION`.
5. Follow existing package conventions.

ALWAYS inspect before deciding. Do not guess package behavior, API shape, file layout, or coding conventions.

## Scope of changes

Keep patches focused.

Prefer small, reviewable changes.

Separate unrelated work into separate patches or notes.

When a refactor exposes another problem, report it separately unless it blocks the requested task.

Avoid mixing feature work, cleanup, formatting, and unrelated fixes.

## R code

Write clean R code.

Prefer:

1. Small functions.
2. Clear names.
3. Explicit inputs.
4. Explicit return values.
5. Local state.
6. Simple control flow.

Use S3 when behavior depends on object class.

Constructors validate and normalize objects.

Methods dispatch on class.

Public constructors own object invariants.

Avoid:

1. Hidden state.
2. Global side effects.
3. Implicit assumptions.
4. Partial matching.
5. Silent recycling of parallel inputs.
6. Broad conditional logic when S3 dispatch is clearer.

## Package workflow

Use `usethis` and `devtools` for package work.

Use `roxygen2` for documentation.

Use `testthat` for tests.

Use namespace-qualified calls for external packages:

```r
terra::rast()
xml2::read_xml()
```

Add required dependencies with:

```r
usethis::use_package("pkg")
```

Handle optional dependencies with:

```r
requireNamespace("pkg", quietly = TRUE)
```

Optional dependencies must not be loaded at package load time.

## Documentation

Write package documentation in a matter-of-fact style.

Documentation should be:

1. Clear.
2. Factual.
3. Concise.
4. Readable.
5. Specific about behavior.

Public functions need roxygen blocks with:

```r
#' @title
#' @name
#' @description
#' @param
#' @return
#' @examples
#' @export
```

Use `@rdname` for related functions and S3 methods.

Internal functions use:

```r
#' @keywords internal
#' @noRd
```

For internal S3 specialized functions use "export" to register the specialization:

```r
#' @export
#' @keywords internal
#' @noRd
```

Document what the function does, what arguments mean, what the object represents, what is returned, and what errors users should expect.

Do not edit generated documentation by hand. NEVER edit `NAMESPACE` or files in `man/`.

Do not write roxygen blocks, vignettes, README text, pkgdown articles, or user-facing messages in the terse style used for agent instructions.

## Tests

New behavior needs tests.

Bug fixes need regression tests when practical.

Test:

1. Normal behavior.
2. Edge cases.
3. Object invariants.
4. Expected errors.
5. User-visible behavior.

Use small, stable fixtures in:

```text
tests/testthat/
inst/extdata/
```

Avoid large fixtures, local caches, generated files, and temporary artifacts in Git.

## Parsers, converters, and constructors

Separate:

1. Detection.
2. Parsing.
3. Validation.
4. Construction.

Use public constructors to enforce object invariants.

Converters should return package objects through public constructors when practical.

Parsers should fail clearly when input is unsupported.

## Vignettes and examples

Examples and vignettes must describe the actual data they use.

Keep examples small and reproducible.

Use optional dependencies conditionally.

When documentation, examples, vignettes, or pkgdown articles change, verify that they build.

Use:

```r
pkgdown::build_site()
```

when site-level documentation needs checking.

## Validation before completion

Before considering work done, run:

```r
devtools::document()
devtools::test()
devtools::check()
```

`R CMD check` is acceptable.

The package must remain CRAN-clean: no ERRORs, no WARNINGs, and no avoidable NOTEs.

EVERY change should leave the package documented, tested, and checkable.
