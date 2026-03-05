.ghqc_env <- new.env(parent = emptyenv())

.is_windows <- function() {
  .Platform$OS.type == "windows"
}

.ghqc_exe <- function() {
  if (.is_windows()) {
    "ghqc.exe"
  } else {
    "ghqc"
  }
}

.is_installed <- function() {
  processx::run("which", "ghqc", error_on_status = FALSE)$status == 0
}

.check_installed <- function() {
  if (!.is_installed()) {
    cli::cli_abort(
      "ghqc is not installed. Run {cli::cli_fmt({cli::cli_code(\"ghqc::ghqc_install()\")})}"
    )
  }
}

.run_ghqc <- function(args) {
  .check_installed()
  res <- processx::run(.ghqc_exe(), args, error_on_status = FALSE)
  res$stdout <- res$stdout |> trimws()
  res
}
