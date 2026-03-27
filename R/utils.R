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

.is_rstudio <- function() {
  if (rstudioapi::isAvailable()) {
    return(
      rstudioapi::versionInfo()$citation |> grepl(pattern = "RStudio")
    )
  }
  FALSE
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
    error_on_status = FALSE,
    echo_cmd = TRUE
  )
  res$stdout <- res$stdout |> trimws()
  res
}

# Parse a version string like "0.1.1" into c(0L, 1L, 1L), and treat
# prerelease/build suffixes like "0.3.1-rc1" as c(0L, 3L, 1L, 1L).
.parse_version <- function(v) {
  if (length(v) == 0) {
    return(integer())
  }

  v <- v[[1]]
  v <- trimws(v)
  has_suffix <- grepl("-", v, fixed = TRUE)
  base <- sub("-.*$", "", v)
  parsed <- as.integer(strsplit(base, "\\.")[[1]])

  if (has_suffix) {
    parsed <- c(parsed, 1L)
  }

  parsed
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
