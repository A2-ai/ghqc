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
  res <- processx::run(
    .ghqc_exe(),
    args,
    error_on_status = FALSE
  )
  res$stdout <- res$stdout |> trimws()
  res
}

# Parse a version string like "0.1.1" into an integer vector c(0L, 1L, 1L)
.parse_version <- function(v) {
  as.integer(strsplit(trimws(v), "\\.")[[1]])
}

# Returns TRUE if installed version >= required version string
.check_min_version <- function(min_version) {
  installed <- tryCatch(ghqc_version(), error = function(e) NULL)
  if (is.null(installed)) {
    return(FALSE)
  }
  iv <- .parse_version(installed)
  rv <- .parse_version(min_version)
  n <- max(length(iv), length(rv))
  length(iv) <- n
  length(rv) <- n
  iv[is.na(iv)] <- 0L
  rv[is.na(rv)] <- 0L
  for (i in seq_len(n)) {
    if (iv[[i]] > rv[[i]]) {
      return(TRUE)
    }
    if (iv[[i]] < rv[[i]]) return(FALSE)
  }
  TRUE
}

.require_min_version <- function(min_version, fn_name) {
  if (!.check_min_version(min_version)) {
    cli::cli_abort(
      "{fn_name} requires ghqc >= {min_version}. \\
      Run {cli::cli_fmt({cli::cli_code(\"ghqc::ghqc_install()\")})} to upgrade."
    )
  }
}
