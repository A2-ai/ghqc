# Remove all content in the specified lib path. Optionally removes the cache as well.

Remove all content in the specified lib path. Optionally removes the
cache as well.

## Usage

``` r
remove_ghqcapp_dependencies(
  lib_path = ghqc_libpath(),
  cache = FALSE,
  .remove_all = FALSE
)
```

## Arguments

- lib_path:

  *(optional)* the path to the installed dependency packages. If not
  set, defaults to ghqc_libpath()

- cache:

  *(optional)* flag of whether to clear the cache or not. Defaults to
  keeping the cache

- .remove_all:

  *(optional)* flag to delete all contents in the basepath:
  ~/.local/share/ghqc/rpkgs

## Value

information related to deleted lib path
