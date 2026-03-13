#' Stream logs from the running ghqc server to the console
#'
#' Blocks the R session and prints server log output as it arrives.
#' Press Ctrl+C (or Escape in RStudio/Positron) to stop streaming.
#'
#' @param log_level Logging filter level
#' @param interval Seconds to wait for output before checking again.
#' @export
ghqc_log <- function(
  log_level = Sys.getenv("GHQC_LOG_LEVEL", "DEBUG"),
  interval = 0.2
) {
  filter <- .make_log_filter(log_level)
  proc <- .ghqc_env$proc

  if (is.null(proc)) {
    message("No ghqc server has been started this session.")
    return(invisible(NULL))
  }
  if (!proc$is_alive()) {
    message("ghqc server is not running.")
    return(invisible(NULL))
  }

  message("Streaming ghqc logs (press Ctrl+C to stop)...")
  on.exit(message("Log streaming stopped."))

  repeat {
    poll_result <- processx::poll(list(proc), as.integer(interval * 1000))
    stderr_status <- poll_result[[1]][["error"]]

    if (stderr_status == "ready") {
      lines <- proc$read_error_lines()
      if (length(lines) > 0) {
        lines <- lines[vapply(lines, filter, logical(1))]
        if (length(lines) > 0) cat(paste0(lines, collapse = "\n"), "\n")
      }
    }

    if (stderr_status == "eof" || !proc$is_alive()) {
      remaining <- proc$read_error()
      if (nzchar(trimws(remaining))) {
        rem_lines <- strsplit(remaining, "\n")[[1]]
        rem_lines <- rem_lines[vapply(rem_lines, filter, logical(1))]
        if (length(rem_lines) > 0) cat(paste(rem_lines, collapse = "\n"), "\n")
      }
      message("ghqc server has stopped.")
      break
    }
  }
}

.validate_log_level <- function(log_level) {
  log_level <- toupper(log_level)
  if (!log_level %in% c("TRACE", "DEBUG", "INFO", "WARN", "ERROR")) {
    cli::cli_abort(
      "Invalid log level: {log_level}. Must be one of TRACE, DEBUG, INFO, WARN, ERROR."
    )
  }
  log_level
}

.verbosity_flag <- function(log_level) {
  log_level <- .validate_log_level(log_level)
  switch(
    log_level,
    INFO = ,
    WARN = ,
    ERROR = "",
    DEBUG = "-v",
    TRACE = "-vv"
  )
}

.make_log_filter <- function(log_level) {
  log_level <- .validate_log_level(log_level)
  levels <- c("TRACE", "DEBUG", "INFO", "WARN", "ERROR")
  included <- levels[seq(match(log_level, levels), length(levels))]
  include_pattern <- paste0("^\\[\\S+ (", paste(included, collapse = "|"), ") ")
  any_level_pattern <- "^\\[\\S+ (TRACE|DEBUG|INFO|WARN|ERROR) "
  show <- TRUE
  function(line) {
    if (grepl(any_level_pattern, line)) {
      show <<- grepl(include_pattern, line)
    }
    show
  }
}
