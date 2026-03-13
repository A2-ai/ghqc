#' Install or upgrade the ghqc binary
#'
#' Downloads and installs the ghqc command-line binary to `~/.local/bin` using
#' the bundled install script. Only supported on unix-like systems (Linux,
#' macOS). On Windows a warning is printed and the function returns early.
#'
#' If ghqc is already installed, the local version is compared to the latest
#' GitHub release. When running interactively and a newer version is available,
#' the user is prompted to confirm the upgrade before proceeding.
#'
#' After a successful install, `~/.local/bin` is added to `PATH` for the
#' current R session if it is not already present.
#'
#' @return `NULL` invisibly.
#'
#' @examples
#' \dontrun{
#' ghqc_install()
#' }
#'
#' @export
ghqc_install <- function() {
  remote_version <- ghqc_remote_version()
  remote_known <- is.null(remote_version)

  if (.is_installed()) {
    version <- ghqc_version()

    if (!remote_known) {
      if (glue::glue("v{version}") == remote_version) {
        cli::cli_alert_success("ghqc {version} is up to date!")
        return(invisible())
      }
    }

    if (rlang::is_interactive()) {
      if (remote_known) {
        cli::cli_alert_warning(
          "ghqc {version} is installed with an unknown latest version"
        )
      } else {
        cli::cli_alert_warning(
          "ghqc {version} is installed but does not match the latest available {remote_version}"
        )
      }

      install_response <- readline(glue::glue(
        "{cli::col_green('?')} Would you like to install the latest version of ghqc? (y/N) "
      )) |>
        tolower()

      if ((c("no", "n", "") == install_response) |> any()) {
        cli::cli_alert_danger("User rejected installation")
        return(invisible())
      }
      if (!(c("yes", "y") == install_response) |> any()) {
        cli::cli_alert_danger(
          "User response '{install_response}' not recognized. Enter 'yes' or 'y' to install"
        )
        return(invisible())
      }
    }

    upgrade_msg <- if (remote_known) {
      glue::glue(" to {remote_version}")
    } else {
      ""
    }
    cli::cli_inform("Upgrading ghqc{upgrade_msg}...")
  } else {
    install_msg <- if (remote_known) {
      glue::glue(" {remote_version}")
    } else {
      ""
    }
    cli::cli_inform("Installing ghqc{install_msg}...")
  }

  .install()
}

.install <- function() {
  if (.is_windows()) {
    cli::cli_alert_warning(
      "Operation system detected as Windows. Install only available for unix-like systems"
    )
    return(invisible())
  }

  install_res <- processx::run(
    "bash",
    system.file("install.sh", package = "ghqc"),
    stdout = "",
    error_on_status = FALSE
  )

  if (install_res$status != 0) {
    stderr_msg <- if (install_res$stderr != "") {
      glue::glue(": {install_res$stderr}")
    } else {
      " with no stderr"
    }
    cli::cli_alert_danger("Failed to install ghqc{stderr_msg}")
    return(invisible())
  }

  path_env <- Sys.getenv("PATH")
  bin_path <- glue::glue("{Sys.getenv('HOME')}/.local/bin")
  if (!grepl(bin_path, path_env)) {
    cli::cli_alert_info(
      "~/.local/bin not found in your PATH. Adding for this R session..."
    )
    Sys.setenv("PATH" = glue::glue("{bin_path}:{path_env}"))
  }

  cli::cli_alert_success(
    "Successfully installed ghqc!"
  )
}
