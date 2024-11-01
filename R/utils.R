#' The default install location for the ghqc package and its dependencies. If it does not exist, it will be created.
#'
#' @return string containing the default lib path for the ghqc package and its dependencies (~/.local/share/ghqc/rpkgs)
#'
#' @importFrom fs dir_exists
#' @importFrom fs dir_create
#'
#' @export
ghqc_libpath <- function() {
  lib_path <- "~/.local/share/ghqc/rpkgs"
  if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path, recurse = TRUE)
  lib_path
}

#' The default install location for the ghqc customizing information repository
#'
#' @return string containing the default path to the ghqc information repository (~/.local/share/ghqc/&lt;info repo name here&gt;
#' @export
ghqc_infopath <- function() {
  file.path("~/.local/share/ghqc", info_repo_name())
}
