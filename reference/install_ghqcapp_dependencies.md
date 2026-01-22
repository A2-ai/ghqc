# install ghqc.app's dependencies into an isolated library

install ghqc.app's dependencies into an isolated library

## Usage

``` r
install_ghqcapp_dependencies(
  lib_path = ghqc_libpath(),
  pkgs = ghqc_depends,
  use_pak = TRUE
)
```

## Arguments

- lib_path:

  *(optional)* the path to install the dependencies. If not set,
  defaults to ghqc_libpath()

- pkgs:

  *(optional)* list of packages to install. Defaults to ghqc and all of
  its dependencies

- use_pak:

  *(optional)* optionally removes the requirement to have `pak`
  installed in the project repository. Setting to `FALSE` will reduce
  performance
