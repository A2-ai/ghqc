# symlink previously installed package library containing all ghqc.app dependencies to an isolated package library

symlink previously installed package library containing all ghqc.app
dependencies to an isolated package library

## Usage

``` r
link_ghqcapp_dependencies(link_path, lib_path = ghqc_libpath())
```

## Arguments

- link_path:

  the path to the installed package library

- lib_path:

  *(optional)* the path to install the dependencies. If not set,
  defaults to ghqc_libpath()

## Value

this function is primarly used for its effects, but will the results of
the symlink
