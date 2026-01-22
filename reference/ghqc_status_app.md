# Status QC file(s)

Status QC file(s)

## Usage

``` r
ghqc_status_app(
  app_name = "ghqc_status_app",
  qc_dir = getwd(),
  lib_path = ghqc_libpath(),
  config_path = ghqc_config_path()
)
```

## Arguments

- app_name:

  the name of the app to run in the background

- qc_dir:

  the directory in which the app is run

- lib_path:

  the path to the ghqc package and its dependencies

- config_path:

  the path to the ghqc configuring information

## See also

[ghqc_assign_app](https://a2-ai.github.io/ghqc/reference/ghqc_assign_app.md)
and
[ghqc_record_app](https://a2-ai.github.io/ghqc/reference/ghqc_record_app.md)
