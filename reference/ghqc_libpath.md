# The default install location for the ghqc package and its dependencies. If it does not exist, it will be created.

The default install location for the ghqc package and its dependencies.
If it does not exist, it will be created.

## Usage

``` r
ghqc_libpath()
```

## Value

string containing the default lib path for the ghqc package and its
dependencies depending on the user's platform, R version, and os arch:
`~/.local/share/ghqc/rpkgs/<platform>/<R version>/<os arch>`
