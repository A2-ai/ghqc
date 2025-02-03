#' Interactive function to set up the ghqc environment, including writing to the .Renviron, custom configuration repository download, and ghqc.app dependency installation/linking, for use of the ghqc application suite
#'
#' @importFrom cli cli_abort
#'
#' @return This function is used for its effects, not outputs. It will return the results of any ghqc dependency installation as needed
#' @export
setup_ghqc <- function() {
  if (!interactive()) {
    cli::cli_abort("This session is not interactive. This function is to interactively setup the environment for ghqc. Please use {.code install_ghqc_dependencies()}, {.code setup_ghqc_renviron()}, and {.code download_ghqc_configuration()} to setup directly")
  }

  renv_text <- interactive_renviron()
  interactive_config_download()
  check_res <- interactive_depends()
}

#' @importFrom cli cli_h1
#' @importFrom cli cli_alert_success
interactive_renviron <- function() {
  cli::cli_h1("GHQC RENVIRON SETUP")
  renv_text <- interactive_info(renviron_text())

  writeLines(renv_text, "~/.Renviron")
  renv_text
}

#' @importFrom cli cli_inform
#' @importFrom glue glue
interactive_info <- function(renv_text) {
  config <- parse_renviron("GHQC_CONFIG_REPO", renv_text)
  if (config$val == "") {
    cli::cli_inform(c(" ", "GHQC_CONFIG_REPO is not set in your ~/.Renviron"))
    config_read <- readline("Provide URL to custom configuration repository: ")
  }
  else {
    repeat {
      cli::cli_inform(c(" ", "GHQC_CONFIG_REPO is set to {config$val} in your ~/.Renviron"))
      yN_config <- readline(glue::glue("Custom configuration repository: {config$val} (y/N) "))
      if (yN_config %in% c("y", "Y", "")) {
        config_read <- config$val
        break
      }
      else if (yN_config %in% c("n", "N")) {
        config_read <- readline("Provide URL to custom configuration repository: ")
        break
      }
      cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
    } # repeat
  } # else
  repeat {
    config_read <- gsub('\"', "", config_read)
    if (grepl("^https:", config_read)) {
      config$val <- config_read
      break
    }
    config_read <- readline(glue::glue("GHQC_CONFIG_REPO does not start with 'https:'. Please provide a valid URL: "))
  }
  renviron_edit("GHQC_CONFIG_REPO", config$val, renv_text)
}

write_renv_text <- function(renv_text, val, var_name) {
  if (is.na(val$index)) return(c(renv_text, var_write(var_name, val$val)))
  overwrite_var(var_name, val$val, renv_text, val$index)
}

#' @importFrom cli cli_h1
#' @importFrom rlang is_installed
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_danger
#' @importFrom glue glue
interactive_config_download <- function() {
  cli::cli_h1("CUSTOM CONFIGURATION REPOSITORY")
  if (!rlang::is_installed("gert")) {
    repeat {
      cli::cli_inform(c("!" = "Package {.code gert} is not found in your project package library",
                        " " = "The custom configuration repository cannot be downloaded unless this package is present"))
      yN_gert <- gsub('\"', "", readline("Would you like to install `gert` to continue? (y/N) "))
      if (yN_gert %in% c("y", "Y")) {
        install.packages("gert")
        break
      }
      else if (yN_gert %in% c("n", "N")) {
        cli::cli_alert_danger("{.code gert} is not installed. Custom configuration repository cannot be checked or downloaded using this package")
        return(invisible())
      }
      cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
    } # repeat
  } # if

  repeat {
    cli::cli_inform(" ")
    config_yN <- gsub('\"', "", readline(glue::glue("Download custom configuration repository to path: {ghqc_config_path()} (y/N) ")))
    if (config_yN %in% c("y", "Y", "")) {
      config_path <- ghqc_config_path()
      break
    }
    else if (config_yN %in% c("n", "N")) {
      config_path <- gsub('\"', "", readline(glue::glue("Provide path to download custom configuration repository: ")))
      break
    }
    cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
  }

  cli::cli_inform(" ")
  check_ghqc_configuration(config_path = config_path)
}

#' @importFrom cli cli_h1
#' @importFrom cli cli_inform
#' @importFrom glue glue
#' @importFrom cli cli_alert_warning
interactive_depends <- function() {
  cli::cli_h1("GHQC.APP DEPENDENCY INSTALLATION")
  cli::cli_inform(c("Would you like to INSTALL new packages from Posit Package Manager or LINK to a previously installed package library?",
                    "1. INSTALL",
                    "2. LINK",
                    "3. Neither"))
  inst_method <- readline("Input: ")

  repeat {
    inst_method <- gsub('\"', "", inst_method)
    if ((inst_method %in% c("1", "2", "3"))) break
    inst_method <- readline(glue::glue("Input of {inst_method} is not a valid input. Please enter 1, 2, or 3: "))
  }

  switch(inst_method,
          "1" = return(interactive_install()),
          "2" = return(interactive_link()),
          "3" = {
            cli::cli_alert_warning("Ensure that ghqc.app and its dependencies are installed into an isolated ghqc package library path before using any ghqc ecosystem apps.")
            return(invisible())
          }
  )
} # interactive_depends

#' @importFrom rlang is_installed
#' @importFrom utils install.packages
#' @importFrom cli cli_inform
#' @importFrom fs file_exists
#' @importFrom fs dir_create
interactive_install <- function() {
  use_pak <- TRUE
  if (!rlang::is_installed("pak")) {
    repeat {
      cli::cli_inform(" ")
      cli::cli_inform("Package {.code pak} is not found in your project package library")
      yN_pak <- gsub('\"', "", readline("To improve performance, would you like to install `pak`? (y/N) "))
      if (yN_pak %in% c("y", "Y", "")) {
        utils::install.packages("pak")
        break
      }
      else if (yN_pak %in% c("n", "N")) {
        cli::cli_inform("{.code pak} not installed")
        use_pak <- FALSE
        break
      }
      cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
    } # repeat
  } # if

  repeat {
    cli::cli_inform(" ")
    yN_libpath <- gsub('\"', "", readline(glue::glue("Install ghqc.app dependencies to path: {ghqc_libpath()} (y/N) ")))
    if (yN_libpath %in% c("y", "Y", "")) {
      lib_path <- ghqc_libpath()
      break
    }
    else if (yN_libpath %in% c("n", "N")) {
      lib_path <- gsub('\"', "", readline(glue::glue("Provide path to install ghqc.app dependencies: ")))
      if (!fs::file_exists(lib_path)) fs::dir_create(lib_path)
      break
    }
    cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
  } # repeat

  cli::cli_inform(" ")
  check_ghqcapp_dependencies(lib_path = lib_path, use_pak = use_pak)
}

#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_danger
#' @importFrom fs file_exists
#' @importFrom fs dir_create
interactive_link <- function() {
  cli::cli_inform(" ")
  link_path <- gsub('\"', "", readline("Path to previously installed package library from which to link: "))

  result <- tryCatch({
    check_link_path(link_path)
    TRUE
  }, error = function(e) {
    cli::cli_alert_danger("Path provided is not sufficient: {conditionMessage(e)}")
    FALSE
  })

  if (!result) { # can't return from function in tryCatch
    return(invisible())
  }

  repeat {
    yN_libpath <- gsub('\"', "", readline(glue::glue("Link ghqc.app dependencies to path: {ghqc_libpath()} (y/N) ")))
    if (yN_libpath %in% c("y", "Y", "")) {
      lib_path <- ghqc_libpath()
      break
    }
    else if (yN_libpath %in% c("n", "N")) {
      lib_path <- gsub('\"', "", readline(paste0("Provide path to link ghqc.app dependencies: ")))
      if (!fs::file_exists(lib_path)) fs::dir_create(lib_path)
      break
    }
    cli::cli_inform("Unrecognized input. Please input 'y' or 'N'")
  } # repeat

  cli::cli_inform(" ")
  link_ghqcapp_dependencies(link_path = link_path, lib_path = lib_path)
}
