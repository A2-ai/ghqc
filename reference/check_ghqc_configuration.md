# Check the content of the downloaded ghqc custom configuration repository and download any updates needed

Check the content of the downloaded ghqc custom configuration repository
and download any updates needed

## Usage

``` r
check_ghqc_configuration(config_path = ghqc_config_path())
```

## Arguments

- config_path:

  *(optional)* path in which the repository, set in environmental
  variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults
  to `~/.local/share/ghqc/{repo_name}`

## Value

this function is used for its effects, but will return if bool if the
result is a config repo found locally at config_path
