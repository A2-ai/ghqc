#' Interactive function to set up the ghqc environment, including writing to the .Renviron, custom configuration repository download, and ghqc.app dependency installation/linking, for use of the ghqc application suite
#'
#' @importFrom cli cli_abort
#'
#' @return This function is used for its effects, not outputs. It will return the results of any ghqc dependency installation as needed
#' @export
ghqc_setup <- function() {
  if (!interactive()) {
    cli::cli_abort("This session is not interactive. This function is to interactively setup the environment for ghqc. Please use {.code install_ghqc_dependencies()}, {.code setup_ghqc_renviron()}, and {.code download_ghqc_configuration()} to setup directly")
  }

  renv_text <- interactive_renviron()
  interactive_config_download()
  lib_path <- interactive_depends()
  ghqcapp_status <- install_ghqcapp_if_available(lib_path)

  if (!is.null(ghqcapp_status)) {
    cli::cli_alert_success("Setup complete!")
  }
}

install_ghqcapp_if_available <- function(lib_path) {
  # if ghqc.app is an available package, install it even if a version is already installed
  if ("ghqc.app" %in% as.data.frame(available.packages())$Package) {
    install.packages("ghqc.app",
                     lib = lib_path)
    ghqcapp_status <- ghqcapp_pkg_status(lib_path)
    cli::cli_alert_success("ghqc.app {ghqcapp_status[2]} installed in {lib_path}")
  }
  else {
    ghqcapp_status <- ghqcapp_pkg_status(lib_path)
    if (is.null(ghqcapp_status)) {
      cli::cli_alert_warning("NOTE: ghqc.app is not installed in {lib_path}. Please install before running any ghqc apps")
    }
    else {
      cli::cli_alert_success("ghqc.app {ghqcapp_status[2]} already installed in {lib_path}")
    }
  }

  return(ghqcapp_status)
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
  if (!rlang::is_installed("pak", version = "0.8.0")) { # if min version of pak isn't installed
    repeat {
      pak_old_version_installed <- rlang::is_installed("pak") # if pak is installed, it's the old version
      cli::cli_inform(" ")
      if (pak_old_version_installed) {
        pak_version <- packageVersion("pak")
        cli::cli_inform("Package {.code pak} version is {pak_version}")
      }
      else {
        cli::cli_inform("Package {.code pak (>= 0.8.0)} is not found in your project package library")
      }

      yN_pak <- gsub('\"', "", readline("To improve performance, would you like to install `pak (>= 0.8.0)`? (y/N) "))
      if (yN_pak %in% c("y", "Y", "")) {
        if (pak_old_version_installed) { # if an old version was installed, remove the package and its cache to avoid corruption errors
          if ("pak" %in% loadedNamespaces()) {
            unloadNamespace("pak")
          }
          utils::remove.packages("pak")
          unlink(".RData")
        }
        utils::install.packages("pak")
        rlang::check_installed("pak", version = "0.8.0")
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
  return(lib_path)
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
  return(lib_path)
}

#' Function to set up the ghqc environment, including writing to the .Renviron, custom configuration repository download, ghqc.app dependency installation, and ghqc.app installation if available, for use of the ghqc application suite
#'
#' @param config_repo the URL for the custom configuration repository from which to import organization specific items like checklist templates
#' @export
ghqc_example_setup <- function(
    config_repo = "https://github.com/A2-ai/ghqc.example_config_repo"
) {
  # if the config isn't set up, make sure gert is installed so it can be set up
  config_repo_env_var_set <- Sys.getenv("GHQC_CONFIG_REPO") != ""

  # step 1: setup renviron
  # if the renviron hasn't been setup OR the input config_repo isn't the default, setup the renviron
  # if there is already a config repo, chances are that the user wants to stick with that one instead of overwriting the
  # renviron with the example repo
  # if the inputted config repo isn't the default example, then chances are the user wanted to be explicit to set the renviron
  if (
    !config_repo_env_var_set ||
    config_repo != "https://github.com/A2-ai/ghqc.example_config_repo"
  ) {
    setup_ghqc_renviron(config_repo)
  }

  # step 2: clone config repo (this will check if gert is installed)
  if (!download_ghqc_configuration()) {
    cli::cli_abort(
      "The configuration repository could not be downloaded. Refer to the above error message."
    )
  }

  # step 3: use_pak if at least 0.8.0 is installed
  use_pak <- rlang::is_installed("pak", version = "0.8.0")

  # step 4: install ghqc.app dependencies
  install_ghqcapp_dependencies(use_pak = use_pak)

  # step 5: install ghqc.app if available
  ghqcapp_status <- install_ghqcapp_if_available(lib_path = ghqc_libpath())

  # step 6: output message
  if (!is.null(ghqcapp_status)) {
    cli::cli_alert_success(
      "Setup complete! Visit the ghqc documentation to learn how to connect your organization's custom repository for checklist templates and more."
    )
  }
} # ghqc_example_setup
