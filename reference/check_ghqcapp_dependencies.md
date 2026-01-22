# Check the installed/linked packages in `lib_path` against the recommended ghqc.app dependency package version

Check the installed/linked packages in `lib_path` against the
recommended ghqc.app dependency package version

## Usage

``` r
check_ghqcapp_dependencies(lib_path = ghqc_libpath(), use_pak = TRUE)
```

## Arguments

- lib_path:

  *(optional)* the path to the installed/linked dependencies. If not
  set, defaults to ghqc_libpath()

- use_pak:

  *(optional)* optionally removes the requirement to have `pak`
  installed in the project repository. Setting to `FALSE` will reduce
  performance

## Value

This function is primarily used for its printed results and subsequent
actions, not a returned output. Will return a dataframe of package
upgrades needed
