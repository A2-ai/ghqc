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
  log_file <- .ghqc_env$log_file

  if (is.null(proc)) {
    message("No ghqc server has been started this session.")
    return(invisible(NULL))
  }
  if (!proc$is_alive()) {
    message("ghqc server is not running.")
    return(invisible(NULL))
  }
  if (is.null(log_file) || !file.exists(log_file)) {
    message("No ghqc log file is available for the running server.")
    return(invisible(NULL))
  }

  message("Streaming ghqc logs (press Ctrl+C to stop)...")
  on.exit(message("Log streaming stopped."))

  repeat {
    lines <- .read_ghqc_log_lines()
    if (length(lines) > 0) {
      lines <- lines[vapply(lines, filter, logical(1))]
      if (length(lines) > 0) {
        cat(paste0(lines, collapse = "\n"), "\n")
      }
    }

    if (!proc$is_alive()) {
      remaining <- .read_ghqc_log_lines()
      if (length(remaining) > 0) {
        rem_lines <- remaining[vapply(remaining, filter, logical(1))]
        if (length(rem_lines) > 0) cat(paste(rem_lines, collapse = "\n"), "\n")
      }
      message("ghqc server has stopped.")
      break
    }

    Sys.sleep(interval)
  }
}

.read_ghqc_log_lines <- function() {
  chunk <- .read_ghqc_log()

  if (!nzchar(chunk)) {
    return(character())
  }

  strsplit(chunk, "\n", fixed = TRUE)[[1]] |>
    (\(x) x[nzchar(x)])()
}

.read_ghqc_log <- function() {
  log_file <- .ghqc_env$log_file
  from <- .ghqc_env$log_position

  if (is.null(log_file) || !file.exists(log_file)) {
    return("")
  }
  if (is.null(from)) {
    from <- 0L
  }

  size <- file.info(log_file)$size
  if (is.na(size) || size <= 0) {
    return("")
  }
  if (from > size) {
    from <- 0L
  }

  text <- .read_log_chunk(log_file, from = from)
  .ghqc_env$log_position <- size
  text
}

.read_log_chunk <- function(log_file, from = 0L) {
  size <- file.info(log_file)$size

  if (is.na(size) || size <= from) {
    return("")
  }

  con <- file(log_file, open = "rb")
  on.exit(close(con), add = TRUE)
  seek(con, where = from, origin = "start")
  readBin(con, what = "raw", n = size - from) |>
    rawToChar(multiple = FALSE)
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
