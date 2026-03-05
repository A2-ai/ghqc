#' Run the ghqc UI as a background job
#'
#' Starts the ghqc web UI as a supervised background R process and opens it in
#' the browser. Any previously running ghqc server is stopped first. Use
#' [ghqc_stop()] to stop the server, [ghqc_status()] to check its status, or
#' [ghqc_reconnect()] to reopen the browser tab without restarting the server.
#'
#' @param directory Path to the project directory. Defaults to the project root
#'   as determined by [here::here()].
#' @param port Integer port to bind the server to. If `NULL` (default), a
#'   random available port is selected automatically.
#' @param config_dir Path to the ghqc configuration directory. If `NULL`
#'   (default), ghqc uses its default configuration discovery logic.
#'
#' @return Called for its side effect of starting the server and opening the
#'   browser. Returns `NULL` invisibly.
#'
#' @examples
#' \dontrun{
#' # Start with defaults (project root, random port)
#' ghqc()
#'
#' # Start on a specific port
#' ghqc(port = 8080)
#'
#' # Start for a subdirectory with a custom config location
#' ghqc(directory = "analysis", config_dir = "~/.config/ghqc")
#' }
#'
#' @export
ghqc <- function(directory = here::here(), port = NULL, config_dir = NULL) {
  ghqc_stop()

  directory <- here::here(directory)
  port <- if (is.null(port)) random_port()
  args <- c(
    "ui",
    "--port",
    port,
    "--directory",
    directory,
    "--no-open"
  )

  if (!is.null(config_dir)) {
    args <- c(args, "--config-dir", here::here(config_dir))
  }

  proc <- callr::r_bg(
    function(args) ghqc:::.run_ghqc(args),
    args = list(args = args),
    supervise = TRUE
  )

  if (!wait_for_server(port)) {
    err <- proc$read_error()
    if (nzchar(trimws(err))) {
      stop("ghqc server failed to start:\n", err)
    } else {
      stop("ghqc server did not start within the timeout period")
    }
  }

  .ghqc_env$proc <- proc
  .ghqc_env$port <- port

  url <- glue::glue("http://localhost:{port}")
  cli::cli_alert_success("ghqc server started successfully at {url}")
  utils::browseURL(url)
}

wait_for_server <- function(port, timeout = 15) {
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    ready <- tryCatch(
      suppressWarnings({
        con <- socketConnection("0.0.0.0", port, timeout = 0.5, open = "r+")
        close(con)
        TRUE
      }),
      error = function(e) FALSE
    )
    if (ready) {
      return(invisible(TRUE))
    }
    Sys.sleep(0.1)
  }
  invisible(FALSE)
}


#' Stop the running ghqc background server
#'
#' Kills the supervised background process started by [ghqc()]. If no server is
#' running, a message is printed and the function returns silently.
#'
#' @return `NULL` invisibly.
#'
#' @examples
#' \dontrun{
#' ghqc()
#' ghqc_stop()
#' }
#'
#' @export
ghqc_stop <- function() {
  proc <- .ghqc_env$proc
  if (is.null(proc)) {
    message("No background ghqc server is running.")
    return(invisible(NULL))
  }
  if (!proc$is_alive()) {
    message("ghqc server has already stopped.")
    .ghqc_env$proc <- NULL
    return(invisible(NULL))
  }
  proc$kill()
  .ghqc_env$proc <- NULL
  message("ghqc server stopped.")
  invisible(NULL)
}

#' Check the status of the ghqc background server
#'
#' Reports whether the server started by [ghqc()] is currently running and, if
#' so, prints its URL.
#'
#' @return The server URL (`"http://localhost:<port>"`) invisibly, or `NULL`
#'   invisibly if no server has been started this session.
#'
#' @examples
#' \dontrun{
#' ghqc()
#' ghqc_status()
#' }
#'
#' @export
ghqc_status <- function() {
  port <- .ghqc_env$port

  if (is.null(port)) {
    message("No ghqc server has been started this session.")
    return(invisible(NULL))
  }

  proc <- .ghqc_env$proc
  url <- glue::glue("http://localhost:{port}")

  if (!is.null(proc) && proc$is_alive()) {
    message(glue::glue("ghqc server is running at {url}"))
  } else {
    message(glue::glue("ghqc server has stopped (was at {url})"))
  }

  invisible(url)
}

#' Reopen the ghqc UI in the browser
#'
#' Opens a browser tab pointing to a ghqc server that is already running in the
#' background. This is useful after accidentally closing the browser tab without
#' stopping the server. If no server is running, a message is printed instead.
#'
#' @return The server URL (`"http://localhost:<port>"`) invisibly, or `NULL`
#'   invisibly if no server is running.
#'
#' @examples
#' \dontrun{
#' ghqc()
#' ghqc_reconnect()
#' }
#'
#' @export
ghqc_reconnect <- function() {
  port <- .ghqc_env$port
  if (is.null(port)) {
    message(
      "No ghqc server has been started this session. Use ghqc() to start one."
    )
    return(invisible(NULL))
  }

  proc <- .ghqc_env$proc
  if (is.null(proc) || !proc$is_alive()) {
    message("ghqc server has stopped. Use ghqc() to start a new one.")
    return(invisible(NULL))
  }

  url <- glue::glue("http://localhost:{port}")
  utils::browseURL(url)
  invisible(url)
}
