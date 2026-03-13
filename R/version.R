#' Get the locally installed ghqc version
#'
#' Runs `ghqc --version` and returns the version string. Errors if the ghqc
#' binary is not installed; run [ghqc_install()] first.
#'
#' @return A character string containing the version number (e.g. `"0.4.2"`).
#'
#' @examples
#' \dontrun{
#' ghqc_version()
#' }
#'
#' @export
ghqc_version <- function() {
  .run_ghqc("--version")$stdout |>
    # ghqc == 0.1.0: `ghqc --version` -> ghqctoolkit 0.1.0
    gsub(pattern = "ghqctoolkit ", replacement = "") |>
    # ghqc >= 0.2.0: `ghqc --version` -> ghqc 0.2.0
    gsub(pattern = "ghqc ", replacement = "")
}

#' Get the latest released ghqc version from GitHub
#'
#' Queries the GitHub Releases API for the `a2-ai/ghqctoolkit` repository and
#' returns the tag name of the latest release (e.g. `"v0.4.2"`). Returns
#' `NULL` invisibly and prints a warning if the request fails (e.g. due to no
#' internet access or rate limiting).
#'
#' @return A character string with the latest release tag (e.g. `"v0.4.2"`), or
#'   `NULL` invisibly if the version could not be determined.
#'
#' @examples
#' \dontrun{
#' ghqc_remote_version()
#' }
#'
#' @export
ghqc_remote_version <- function() {
  res <- processx::run(
    "curl",
    c(
      "-L",
      "https://api.github.com/repos/a2-ai/ghqctoolkit/releases/latest"
    ),
    error_on_status = FALSE
  )

  if (res$status != 0) {
    cli::cli_alert_warning("Failed to determine remote version")
    return(invisible())
  }

  jsonlite::fromJSON(res$stdout)$tag_name |> trimws()
}
