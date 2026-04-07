#' Install or upgrade the ghqc binary
#'
#' Downloads and installs the ghqc command-line binary using the bundled
#' platform install script. On Linux and macOS, the binary is installed to
#' `~/.local/bin`. On Windows, it is installed to
#' `%LOCALAPPDATA%/Programs/ghqc`.
#'
#' If `version` is not supplied and ghqc is already installed, the local
#' version is compared to the latest GitHub release. When running
#' interactively and a newer version is available, the user is prompted to
#' confirm the upgrade before proceeding. If `version` is supplied, that
#' specific release is installed instead.
#'
#' After a successful install, the install directory is added to `PATH` for
#' the current R session if it is not already present.
#'
#' @param version Optional release tag to install, such as `"v0.4.1"`.
#' If omitted, the latest available release is installed.
#'
#' @return `NULL` invisibly.
#'
#' @examples
#' \dontrun{
#' ghqc_install()
#' ghqc_install(version = "v0.7.0")
#' }
#'
#' @export
ghqc_install <- function(version = NULL) {
  requested_version <- .normalize_release_version(version)
  target_version <- if (is.null(requested_version)) {
    ghqc_remote_version()
  } else {
    requested_version |> .normalize_release_version()
  }
  target_unknown <- is.null(target_version)

  if (.is_installed()) {
    installed_version <- ghqc_version()

    if (!target_unknown) {
      if (glue::glue("v{installed_version}") == target_version) {
        cli::cli_alert_success("ghqc {installed_version} is up to date!")
        return(invisible())
      }
    }

    if (is.null(requested_version) && rlang::is_interactive()) {
      if (target_unknown) {
        cli::cli_alert_warning(
          "ghqc {installed_version} is installed with an unknown latest version"
        )
      } else {
        cli::cli_alert_warning(
          "ghqc {installed_version} is installed but does not match the latest available {target_version}"
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

    upgrade_msg <- if (target_unknown) {
      ""
    } else {
      glue::glue(" to {target_version}")
    }
    cli::cli_inform("Upgrading ghqc{upgrade_msg}...")
  } else {
    install_msg <- if (target_unknown) {
      ""
    } else {
      glue::glue(" {target_version}")
    }
    cli::cli_inform("Installing ghqc{install_msg}...")
  }

  .install(target_version)
}

.install <- function(version = NULL) {
  if (.is_windows()) {
    install_res <- processx::run(
      "powershell",
      c(
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        system.file("install.ps1", package = "ghqc"),
        if (!is.null(version)) c("-Version", version)
      ),
      stdout = "",
      error_on_status = FALSE
    )
    bin_path <- file.path(Sys.getenv("LOCALAPPDATA"), "Programs", "ghqc")
  } else {
    install_res <- processx::run(
      "bash",
      c(
        system.file("install.sh", package = "ghqc"),
        if (!is.null(version)) version
      ),
      stdout = "",
      error_on_status = FALSE
    )
    bin_path <- glue::glue("{Sys.getenv('HOME')}/.local/bin")
  }

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
  path_sep <- if (.is_windows()) ";" else ":"
  path_entries <- strsplit(path_env, path_sep, fixed = TRUE)[[1]]
  if (!(bin_path %in% path_entries)) {
    cli::cli_alert_info(
      "{bin_path} not found in your PATH. Adding for this R session..."
    )
    Sys.setenv("PATH" = paste(c(bin_path, path_entries), collapse = path_sep))
  }

  cli::cli_alert_success(
    "Successfully installed ghqc!"
  )
}

.normalize_release_version <- function(version = NULL) {
  if (is.null(version)) {
    return(NULL)
  }

  version <- trimws(version)
  if (!nzchar(version)) {
    return(NULL)
  }

  if (startsWith(version, "v")) {
    version
  } else {
    paste0("v", version)
  }
}
