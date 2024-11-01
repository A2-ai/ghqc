#' Interactive function to set up the ghqc environment, including writing to the .Renviron, configuration information repository download, and ghqc.app dependency installation/linking, for use of the ghqc application suite
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
  interactive_info_download()
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
  info <- parse_renviron("GHQC_INFO_REPO", renv_text)
  if (info$val == "") {
    cli::cli_inform(c(" ", "GHQC_INFO_REPO is not set in your ~/.Renviron"))
    info_read <- readline("Provide the URL to the configuring information repository: ")
  } else {
    cli::cli_inform(c(" ", "GITHUB_INFO_REPO is set to {info$val} in your ~/.Renviron"))
    info_read <- readline(glue::glue("Customizing Information Repository ({info$val}) "))
    if (info_read == "") info_read <- info$val
  }
  repeat {
    info_read <- gsub('\"', "", info_read)
    if (grepl("^https:", info_read)) {
      info$val <- info_read
      break
    }
    info_read <- readline(glue::glue("GHQC_INFO_REPO does not start with 'https:'. Please provide a valid URL: "))
  }
  renviron_edit("GHQC_INFO_REPO", info$val, renv_text)
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
interactive_info_download <- function() {
  cli::cli_h1("CONFIGURING INFORMATION REPOSITORY")
  if (!rlang::is_installed("gert")) {
    cli::cli_inform(c("!" = "Package {.code gert} is not found in your project package library",
                      " " = "The configuration information repository cannot be downloaded unless this package is present"))
    yN <- gsub('\"', "", readline("Would you like to install `gert` to continue? (y/N) "))
    if (yN != "y" && yN == "") {
      cli::cli_alert_danger("`gert` is not installed. Configuring information repository cannot be checked or downloaded using this package")
      return(invisible())
    }
    install.packages("gert")
  }

  cli::cli_inform(" ")
  info_path <- gsub('\"', "", readline(glue::glue("Path to download the configuration information repository ({ghqc_infopath()}) ")))
  if (info_path == "") info_path <- ghqc_infopath()

  cli::cli_inform(" ")
  check_ghqc_configuration(info_path = info_path)
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

  if (inst_method == "3") {
    cli::cli_alert_warning("Ensure the ghqc and its dependencies are installed into an isolated ghqc package library path before using any of the ghqc ecosystem apps.")
    return(invisible())
  }

  if (inst_method == "1") return(interactive_install())
  if (inst_method == "2") return(interactive_link())
}

#' @importFrom rlang is_installed
#' @importFrom utils install.packages
#' @importFrom cli cli_inform
#' @importFrom fs file_exists
#' @importFrom fs dir_create
interactive_install <- function() {
  use_pak <- TRUE
  if (!rlang::is_installed("pak")) {
    cli::cli_inform(" ")
    yN <- gsub('\"', "", readline("Package `pak` is not found in your project package library. To improve performance, would you like to install pak? (y/N) "))
    if (yN == "y" || yN == "") utils::install.packages("pak") else use_pak <- FALSE
  }

  cli::cli_inform(" ")
  lib_path <- gsub('\"', "", readline("Path to install the ghqc.app dependencies (~/.local/share/ghqc/rpkgs) "))
  if (lib_path == "") lib_path <- ghqc_libpath()
  if (!fs::file_exists(lib_path)) fs::dir_create(lib_path)

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

  tryCatch({
    check_link_path(link_path)
  }, error = function(e) {
    cli::cli_alert_danger("Path provided is not sufficient because {e$message}")
    return(invisible())
  })

  lib_path <- gsub('\"', "", readline("Path to link the ghqc.app dependencies (~/.local/share/ghqc/rpkgs) "))
  if (lib_path == "") lib_path <- ghqc_libpath()
  if (!fs::file_exists(lib_path)) fs::dir_create(lib_path)

  cli::cli_inform(" ")
  link_ghqcapp_dependencies(link_path = link_path, lib_path = lib_path)
}
