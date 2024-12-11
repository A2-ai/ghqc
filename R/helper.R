delete_bgj_script <- function(script) {
  Sys.sleep(10)
  file.remove(script)
}

#' @importFrom fs dir_exists
#' @importFrom cli cli_abort
error_checks <- function(app_name, qc_dir, lib_path, config_path) {
  if(!fs::dir_exists(qc_dir)) cli::cli_abort(paste(qc_dir, "does not exist."))
  if(!fs::dir_exists(lib_path)) cli::cli_abort(paste(lib_path, "does not exist. Refer to installation guide and check library path is set to correct location."))
  if(!(app_name) %in% c("ghqc_assign_app", "ghqc_resolve_app", "ghqc_record_app")) cli::cli_abort(paste(app_name, "not found in ghqc package."))
  if(!fs::dir_exists(config_path)) cli::cli_abort(c("{config_path} does not exist.", "Run {.code ghqc::check_ghqc_configuration(config_path = '{config_path}')} to verify proper setup."))
}



#' Shiny is "ready" if the download.file is able to serve the starting html,
#' at this point, we will try to hit the shiny app and see if it downloads
#'
#' @param url the http port
#'
#' @return true or false depending on if Shiny is ready
#' @importFrom utils download.file
is_shiny_ready <- function(url) {
  temp <- tempfile()
  withr::defer({
    if (fs::file_exists(temp)) {
      fs::file_delete(temp)
    }
  })

  tryCatch({
    suppressMessages({
      suppressWarnings({
        download.file(url = url, destfile = temp, method = "libcurl", quiet = TRUE)
      })
    })
    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  })
} # is_shiny_ready

#' @importFrom httpuv randomPort
#' @importFrom rstudioapi jobRunScript
#' @importFrom rstudioapi viewer
#' @importFrom fs file_exists
#' @importFrom withr defer
run_app <- function(app_name, qc_dir, lib_path, config_path) {
 error_checks(app_name = app_name,
              qc_dir = qc_dir,
              lib_path = lib_path,
              config_path = config_path
              )
  #browser()

  # needed a way to create a temp file that would ran in a background job in the qc dir
  # the script needed to point towards the ghqc libpaths, load the package, and run the app
  tryCatch({
    if (is.null(ghqcapp_pkg_status(lib_path))) rlang::abort(message = glue::glue("ghqc.app not installed in {lib_path}. Please install before running any ghqc apps"))
    script <- tempfile("background", tmpdir = tempdir(), fileext = ".R")
    withr::defer(fs::file_delete(script))

    script_content <- paste(
      'cat("State of session prior to running ghqc:")',
      'lib_paths <- .libPaths()',
      'sessionInfo <- sessionInfo()',
      'lib_paths_indexed <- paste0("[", seq_along(lib_paths), "] ", "\", lib_paths, "\", collapse = "\n")',
      'cat(paste0("Output from .libPaths():\n", lib_paths_indexed))',
      'cat(paste0("Output from sessionInfo():"))',
      'print(sessionInfo())',
      paste0('.libPaths("', lib_path, '")'),
      'library(ghqc.app)',
      'cat("State of session after running ghqc:")',
      'lib_paths <- .libPaths()',
      'sessionInfo <- sessionInfo()',
      'lib_paths_indexed <- paste0("[", seq_along(lib_paths), "] ", "\", lib_paths, "\", collapse = "\n")',
      'cat(paste0("Output from .libPaths():\n", lib_paths_indexed))',
      'cat(paste0("Output from sessionInfo():"))',
      'print(sessionInfo())',
      paste0('ghqc.app::ghqc_set_config_repo("', config_path, '")'),
      paste0("withr::with_dir(", "'", qc_dir, "',", "{",
        'ghqc.app::', app_name, '()',
      "})"),

      sep = "\n"
    )
    writeLines(script_content, script)

    # create a random port, set it as a sys env so that the shiny app can open to it and then rstudio opens viewer pane to it
    port <- httpuv::randomPort()
    Sys.setenv("GHQC_SHINY_PORT" = port)

    # runs the script within the qc dir and sleeps as its spinning up
    # using stopApp() within shiny seems to close the the viewer pane + causes bg to succeed
    job_id <- rstudioapi::jobRunScript(script, name = app_name, workingDir = qc_dir, importEnv = TRUE)

    url <- sprintf("http://127.0.0.1:%s", port)


    cli::cli_inform("Waiting for shiny app to start...")
    counter <- 1
    while(counter < 35) {
      if (is_shiny_ready(url)) {
        cli::cli_inform("Shiny app started")
        break
      }

      counter <- counter + 1
      Sys.sleep(1)
    }
    if (counter > 34) {
      cli::cli_alert_danger("Shiny app could not be started due to timeout or error")
    }


    rstudioapi::viewer(url)
  }, error = function(e){
    cli::cli_alert_danger(cli::col_br_red(e$message))
  })
}
