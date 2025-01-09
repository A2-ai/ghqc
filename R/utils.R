find_linux_os_info <- function() {
  os_release_path <- "/etc/os-release"

  # check if os file exists
  if (!file.exists(os_release_path)) {
    cli::cli_abort("Cannot determine Linux flavor: /etc/os-release file is missing.")
  }

  os_release <- readLines(os_release_path)

  # parse
  os_info <- list(
    name = sub('NAME="?(.*?)"?$', "\\1", grep("^NAME=", os_release, value = TRUE)),
    version_codename = sub('VERSION_CODENAME="?(.*?)"?$', "\\1", grep("^VERSION_CODENAME=", os_release, value = TRUE))
  )
}


#' Find and format the linux platform string for ghqc/rpkg installation
#'
#' @return the string of the linux platform based on os-release file
format_linux_platform <- function() {
  os_info <- find_linux_os_info()

  # linux-{name}-{version_codename}
  linux_string <- paste0("linux-", tolower(os_info$name), "-", os_info$version_codename)
  return(linux_string)
}

get_platform <- function() {
  platform <- switch(
    Sys.info()[["sysname"]],
    "Linux" = format_linux_platform(),
    "Darwin" = "macos",
    "Windows" = "windows",
    cli::cli_abort("Unsupported OS")
  )
  return(platform)
}

get_r_version <- function() {
  paste0("R-", R.version$major, ".", sub("\\..*", "", R.version$minor)) # don't include patch
}

get_basepath <- function() {
  "~/.local/share/ghqc/rpkgs" # this is now the BASE PATH to be installed to
}

get_os_arch <- function() {
  R.version$platform
}


#' The default install location for the ghqc package and its dependencies. If it does not exist, it will be created.
#'
#' @return string containing the default lib path for the ghqc package and its dependencies (~/.local/share/ghqc/rpkgs/<platform>/<r version>/<os arch>)
#'
#' @importFrom fs dir_exists
#' @importFrom fs dir_create
#'
#' @export
ghqc_libpath <- function() {
  # example: ~/.local/share/ghqc/rpkgs/linux-ubuntu-jammy/R-4.4/x86_64-pc-linux-gnu
  lib_path <- file.path(get_basepath(), get_platform(), get_r_version(), get_os_arch())

  if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path, recurse = TRUE)
  return(lib_path)
}

#' The default install location for the ghqc custom configuration repository
#'
#' @return string containing the default path to the ghqc custom configuration repository (~/.local/share/ghqc/&lt;config repo name here&gt;
#' @export
ghqc_config_path <- function() {
  file.path("~/.local/share/ghqc", config_repo_name())
}
