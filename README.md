
# ghqc <a href="https://github.com/a2-ai/ghqc/"><img src="man/figures/logo.png" align="right" height="139" alt="ghqc website" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/A2-ai/ghqc/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/A2-ai/ghqc/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The ghqc R package is a lightweight wrapper that installs and runs the
[ghqctoolkit](https://github.com/a2-ai/ghqctoolkit) CLI binary, which provides
a web UI for managing QC through GitHub Issues and Milestones.

## Installation

``` r
# install.packages("pak")
pak::pak("a2-ai/ghqc")
```

## Getting Started

### 1. Install the ghqc binary

The ghqc R package is a wrapper around the `ghqctoolkit` binary. Install it with:

``` r
ghqc::ghqc_install()
```

This downloads the appropriate binary for your platform (Linux or macOS) to
`~/.local/bin` and adds it to your `PATH` for the current R session.

If ghqc is already installed, `ghqc_install()` will compare your local version
against the latest GitHub release and prompt you to upgrade if a newer version
is available.

### 2. Launch the ghqc UI

``` r
ghqc::ghqc()
```

This starts the ghqc web UI as a supervised background process and opens it in
your browser. Any previously running ghqc server is stopped first.

You can optionally specify a port or a custom configuration directory:

``` r
# Start on a specific port
ghqc::ghqc(port = 8080)

# Start for a specific directory with a custom config location
ghqc::ghqc(directory = "analysis", config_dir = "~/.config/ghqc")
```

## Managing the Server

``` r
# Check whether the server is running and get its URL
ghqc::ghqc_status()

# Reopen the browser tab without restarting the server
ghqc::ghqc_reconnect()

# Stop the running server
ghqc::ghqc_stop()
```

## Version Information

``` r
# Get the locally installed binary version
ghqc::ghqc_version()

# Get the latest release version from GitHub
ghqc::ghqc_remote_version()
```

## Diagnostics

``` r
# Print a situation report: binary, server status, git repo, and milestones
ghqc::ghqc_sitrep()

# Include configuration details (checklists, options)
ghqc::ghqc_sitrep(with_configuration = TRUE)
```
