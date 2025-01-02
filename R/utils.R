#' The default install location for the ghqc package and its dependencies. If it does not exist, it will be created.
#'
#' @return string containing the default lib path for the ghqc package and its dependencies (~/.local/share/ghqc/rpkgs)
#'
#' @importFrom fs dir_exists
#' @importFrom fs dir_create
#'
#' @export
ghqc_libpath <- function() {
  base_path <- "~/.local/share/ghqc/rpkgs" # this is now the BASE PATH to be installed to
  # platform <- similar to renv. For linux, format is "linux-{linux flavor}-{flavor version}" i.e. "linux-ubuntu-jammy". For mac, just "macos"
  # r_version <- glue::glue("R-{R.version$major}.{//split R.version$minor to grab the minor and not include the path//}")

  # lib_path <- file.path(base_path, platform, r_version)

  if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path, recurse = TRUE)
  lib_path
}

#' The default install location for the ghqc custom configuration repository
#'
#' @return string containing the default path to the ghqc custom configuration repository (~/.local/share/ghqc/&lt;config repo name here&gt;
#' @export
ghqc_config_path <- function() {
  file.path("~/.local/share/ghqc", config_repo_name())
}
