.pe <- new.env()

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
  if (!exists("no_config_repo", envir = .pe)) interactive_config_download()
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
  val <- if (config$val == "") renviron_not_set() else renviron_set(config$val)
  if (!exists("no_config_repo", envir = .pe)) renv_text <- renviron_edit("GHQC_CONFIG_REPO", val, renv_text)
  renv_text
}

renviron_set <- function(config_url) {
  cli::cli_inform(c(" ", "GHQC_CONFIG_REPO is set to {config_url} in your ~/.Renviron. Would you like to: ",
                    " " = "1. Proceed",
                    " " = "2. Replace",
                    # " " = "3. Delete", Potentially add later
                    " " = "3. Abort with error"))
  input <- readline_and_verify("Input: ", 1:3)
  if (input == "3") cli::cli_abort("GHQC_CONFIG_REPO is set in ~/.Renviron. Aborting...")
  if (input == "2") return(readline_and_verify_config())
  if (input == "1") return(config_url)
}

renviron_not_set <- function() {
  cli::cli_inform(c(" ", "GHQC_CONFIG_REPO is not set in your ~/.Renviron. Would you like to: ",
                    " " = "1. Set value",
                    " " = "2. Proceed without setting",
                    " " = "3. Abort with error"))
  input <- readline_and_verify("Input: ", 1:3)
  if (input == "3") cli::cli_abort("GHQC_CONFIG_REPO not set in ~/.Renviron. Aborting...")
  if (input == "2") {
    cli::cli_alert_danger("GHQC_CONFIG_REPO not set in ~/.Renviron. The ghqc shiny apps will not function.")
    assign("no_config_repo", FALSE, .pe)
  }
  if (input == "1") readline_and_verify_config()
}

readline_and_verify_config <- function() {
  input <- readline("Provide the URL to the custom configuration repository: ")
  repeat {
    input <- gsub('\"', "", input)
    if (grepl("^https://", input)) break
    input <- readline(glue::glue("'{input}' does not start with 'https://'. Please provide a valid URL: "))
  }
  input
}

readline_and_verify <- function(message, input_options) {
  if (!is.character(input_options)) input_options <- as.character(input_options)
  input <- readline(message)
  repeat {
    input <- gsub('\"', "", input)
    if (input %in% input_options) break
    io_str <- paste0(paste0(input_options[-length(input_options)], collapse = ", "), ", or ", input_options[length(input_options)])
    input <- readline(glue::glue("Input value of '{input}' is not valid. Please enter {io_str}: "))
  }
  input
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
    cli::cli_inform(c("!" = "Package {.code gert} is not found in your project package library",
                      " " = "The custom configuration repository cannot be downloaded unless this package is present"))
    yN <- gsub('\"', "", readline("Would you like to install `gert` to continue? (y/N) "))
    if (yN != "y" || yN == "") {
      cli::cli_alert_danger("`gert` is not installed. Custom configuration repository cannot be checked or downloaded using this package")
      return(invisible())
    }
    install.packages("gert")
  }

  determine_ghqc_config_download()
}

determine_ghqc_config_download <- function() {
  cli::cli_inform(c(" ", "Would you like to download the custom configuration repository to the default location ({ghqc_config_path()})? ",
                    " " = "1. yes, absolutely!",
                    " " = "2. can I check the contents in the default location first?",
                    " " = "3. no, I have other plans and want to specify a different location",
                    " " = "4. no, I don't want to download right now",
                    " " = "5. Abort with error"))
  input <- readline_and_verify("Input: ", 1:5)
  if (input == "5") cli::cli_abort("Custom configuration repository is not downloaded. Aborting...")
  if (input == "4") {
    cli::cli_alert_danger("Cannot verify custom configuration repository is downloaded. Please ensure before running any ghqc shiny apps")
    assign("no_config_repo", TRUE, .pe)
  }
  if (input == "3") {
    cli::cli_alert_warning("NOTE: This is a non-standard option. Please ensure you have an understanding of the effects before continuing.")
    yN <- readline_and_verify("Would you like to continue (y/N)? ", c("y", "N"))
    if (yN == "N") {
      determine_ghqc_config_download()
      return(invisible())
    }
    path <- gsub('\"', "", readline("Provide the path to install the custom configuration repository: "))
    assign("config_path", path, .pe)
    download_ghqc_configuration(config_path = path, .force = TRUE)
  }
  assign("config_path", ghqc_config_path(), .pe)
  if (input == "2") {
    check_ghqc_configuration()
  }
  if (input == "1") {
    download_ghqc_configuration()
  }
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
  inst_method <- readline_and_verify("Input: ", 1:3)

  if (inst_method == "3") {
    cli::cli_alert_warning("Ensure that ghqc.app and its dependencies are installed into an isolated ghqc package library path before using any of the ghqc ecosystem apps.")
    return(invisible())
  }

  if (inst_method == "1") res <- list("install_results" = interactive_install())
  if (inst_method == "2") res <- list("link_results" = interactive_link())
  if (!exists("no_config_repo", envir = .pe)) {
    list(res, "ghqcapp_results" = interactive_ghqcapp_install())
  } else {
    cli::cli_alert_warning("The repository from which to install ghqc.app cannot be determined without the custom configuration repository being downloaded.")
  }
}

interactive_use_pak <- function() {
  use_pak <- TRUE
  if (!rlang::is_installed("pak")) {
    cli::cli_inform(" ")
    yN <- gsub('\"', "", readline("Package `pak` is not found in your project package library. To improve performance, would you like to install pak? (y/N) "))
    if (yN == "y" || yN == "") utils::install.packages("pak") else use_pak <- FALSE
  }
  use_pak
}

#' @importFrom rlang is_installed
#' @importFrom utils install.packages
#' @importFrom cli cli_inform
#' @importFrom fs file_exists
#' @importFrom fs dir_create
interactive_install <- function() {
  use_pak <- interactive_use_pak()
  assign("use_pak", use_pak, .pe)

  cli::cli_inform(c(" ", "Would you like to install the ghqc.app dependencies to the default location ({ghqc_libpath()})?",
                    " " = "1. yes, absolutely!",
                    " " = "2. can I check the contents in the default location first?",
                    " " = "3. no, I have other plans and want to specify a different location",
                    " " = "4. Abort with error"))
  input <- readline_and_verify("Input: ", 1:4)

  if (input == "4") cli::cli_abort("Dependency packages not installed. Aborting...")
  if (input == "3") {
    cli::cli_alert_warning("NOTE: This is a non-standard option. Please ensure you have an understanding of the effects before continuing.")
    yN <- readline_and_verify("Would you like to continue (y/N)? ", c("y", "N"))
    if (yN == "N") {
      interactive_install()
      return(invisible())
    }
    path <- gsub('\"', "", readline("Provide the path to install the dependency packages: "))
    assign("lib_path", path, .pe)
    install_ghqcapp_dependencies(lib_path = path, use_pak = use_pak)
  }
  assign("lib_path", ghqc_libpath(), .pe)
  if (input == "2") {
    check_ghqcapp_dependencies()
  }
  if (input == "1") {
    install_ghqcapp_dependencies()
  }
}

#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_danger
#' @importFrom fs file_exists
#' @importFrom fs dir_create
interactive_link <- function() {
  cli::cli_inform(" ")
  link_path <- gsub('\"', "", readline("Path to previously installed package library from which to link: "))

  tryCatch({
    check_link_path(link_path)
  }, error = function(e) {
    cli::cli_alert_danger("Path provided is not sufficient because {e$message}")
    return(invisible())
  })

  cli::cli_inform(c(" ", "Would you like to link the ghqc.app dependencies to the default location ({ghqc_libpath()})?",
                  " " = "1. yes, absolutely!",
                  " " = "2. no, I have other plans and want to specify a different location",
                  " " = "3. Abort with error"))
  input <- readline_and_verify("Input: ", 1:3)
  if (input == 3) cli::cli_abort("Dependency packages not symlinked. Aborting...")
  if (input == 2) {
    cli::cli_alert_warning("NOTE: This is a non-standard option. Please ensure you have an understanding of the effects before continuing.")
    yN <- readline_and_verify("Would you like to continue (y/N)? ", c("y", "N"))
    if (yN == "N") {
      interactive_install()
      return(invisible())
    }
    path <- gsub('\"', "", readline("Provide the path to symlink the dependency packages to: "))
  }
  if (input == 1) path <- ghqc_libpath()
  assign("lib_path", path, .pe)
  link_ghqcapp_dependencies(link_path, path)
}

interactive_ghqcapp_install <- function() {
  #FOR DEV
  # assign("lib_path", ghqc_libpath(), .pe)
  # assign("config_path", ghqc_config_path(), .pe)

  cli::cli_h1("GHQC.APP INSTALLATION")
  repo <- ghqcapp_repo(config_path = .pe$config_path)
  specified <- NULL
  if (!repo$unset) specified <- "specified "
  cli::cli_inform("ghqc.app will install from {specified}repository: {repo$url}")
  yN <- tolower(readline(glue::glue("Would you like to install ghqc.app to {(.pe$lib_path)} (y/N)? ")))

  if (yN == "n") {
    cli::cli_alert_danger("Please install ghqc.app to {.pe$lib_path} before running any ghqc apps")
    return(invisible())
  }

  if (!exists("use_pak", envir = .pe)) assign("use_pak", interactive_use_pak(), .pe)
  install_ghqcapp(lib_path = .pe$lib_path, repo = repo$url, use_pak = .pe$use_pak)
}
