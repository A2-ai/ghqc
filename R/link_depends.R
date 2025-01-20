#' symlink previously installed package library containing all ghqc.app dependencies to an isolated package library
#'
#' @param link_path the path to the installed package library
#' @param lib_path *(optional)* the path to install the dependencies. If not set, defaults to ghqc_libpath()
#'
#' @return this function is primarly used for its effects, but will the results of the symlink
#'
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_abort
#' @importFrom fs link_create
#' @importFrom fs path
#'
#' @export
link_ghqcapp_dependencies <- function(link_path,
                                   lib_path = ghqc_libpath()) {
  check_link_path(link_path)
  tryCatch({
    start_time <- Sys.time()
    cli::cli_inform("Linking ghqc.app dependency packages...")
    libpath_setup(lib_path)
    res <- fs::link_create(fs::path(link_path, ghqc_depends),
                           fs::path(lib_path, ghqc_depends))
    dT <- difftime(Sys.time(), start_time)
    cli::cli_alert_success(sprintf("All {length(res)} ghqc.app dependency packages were linked to {.code {lib_path}} in %0.2f {units(dT)}", dT))
    if (is.null(ghqcapp_pkg_status(lib_path))) cli::cli_alert_warning("NOTE: ghqc.app is not installed in {lib_path}. Please install before running any ghqc apps")
    invisible(res)
  }, error = function(e) {
    cli::cli_abort("The ghqc.app dependencies could not be linked to {.code {lib_path}} due to {e$message}")
  })
}

#' @importFrom fs dir_exists
#' @importFrom fs dir_create
libpath_setup <- function(lib_path) {
  remove_ghqcapp_dependencies(lib_path = lib_path)
  if (!fs::dir_exists(lib_path)) return(fs::dir_create(lib_path))
}

#' @importFrom fs dir_exists
#' @importFrom fs dir_ls
#' @importFrom cli cli_abort
#' @importFrom utils packageVersion
#' @importFrom utils compareVersion
check_link_path <- function(link_path) {
  if (!fs::dir_exists(link_path)) cli::cli_abort("{.code {link_path}} does not exist")
  if (length(fs::dir_ls(link_path)) == 0) cli::cli_abort("{.code {link_path}} is empty")
  browser()
  if (any(!(ghqc_depends %in% basename(fs::dir_ls(link_path))))) {
    pkgs_not_in_link <- paste0(ghqc_depends[!(ghqc_depends %in% basename(fs::dir_ls(link_path)))], collapse = ", ")
    cli::cli_abort(c("The following packages are required for ghqc.app, but cannot be found in {.code {link_path}}:", "{pkgs_not_in_link}"))
  }
  pkg_version <- sapply(ghqc_explicit_depends$Package, function(x) tryCatch(paste0(utils::packageVersion(x, lib.loc = link_path), collapse = "."),
                                                                            error = function(e) NA))
  deps <- merge(ghqc_explicit_depends, data.frame(Package = names(pkg_version), Link_Version = pkg_version), by = "Package", all.x = TRUE)
  link_meets_deps <- apply(deps, 1, function(x) utils::compareVersion(x["Link_Version"], x["Depends_Version"]) == -1)
  if (any(link_meets_deps)) {
    pkgs_not_meets_dep <- paste0(row.names(ghqc_explicit_depends)[ghqc_explicit_depends$Package %in% deps$Package[link_meets_deps]], collapse = ", ")
    cli::cli_abort(c("The following packages are required for ghqc.app, but do not match the dependency limit {.code {link_path}}: {pkgs_not_meets_dep}"))
  }
  TRUE
}
