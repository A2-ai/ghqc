# Remove the downloaded custom configuration repository from `config_path`

Remove the downloaded custom configuration repository from `config_path`

## Usage

``` r
remove_ghqc_configuration(config_path = ghqc_config_path())
```

## Arguments

- config_path:

  *(optional)* path in which the repository, set in environmental
  variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults
  to `~/.local/share/ghqc/{repo_name}`

## Value

this function is used for its effects, but will return the removed
`config_path`
