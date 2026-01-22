# Download the custom configuration repository as set in environmental variable `GHQC_CONFIG_REPO`

Download the custom configuration repository as set in environmental
variable `GHQC_CONFIG_REPO`

## Usage

``` r
download_ghqc_configuration(config_path = ghqc_config_path(), .force = FALSE)
```

## Arguments

- config_path:

  *(optional)* path in which the repository, set in environmental
  variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults
  to `~/.local/share/ghqc/{repo_name}`

- .force:

  *(optional)* option to force a new download of the ghqc custom
  configuration repository

## Value

this function is used for its effects, but will return if bool if the
result is a config repo found locally at config_path
