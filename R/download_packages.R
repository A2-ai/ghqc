#' install ghqc.app's dependencies into an isolated library
#'
#' @param lib_path *(optional)* the path to install the dependencies. If not set, defaults to ghqc_libpath()
#' @param pkgs *(optional)* list of packages to install. Defaults to ghqc and all of its dependencies
#' @param use_pak *(optional)* optionally removes the requirement to have `pak` installed in the project repository. Setting to `FALSE` will reduce performance
#'
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_success
#' @importFrom fs dir_exists
#' @importFrom rlang is_installed
#' @importFrom rlang abort
#' @importFrom withr with_options
#' @importFrom utils install.packages
#'
#' @export
install_ghqcapp_dependencies <- function(lib_path = ghqc_libpath(),
                                      pkgs = ghqc_depends,
                                      use_pak = TRUE) {

  check_pak_version(use_pak)

  tryCatch({
    start_time <- Sys.time()
    cli::cli_inform("Installing ghqc.app package dependencies...")
    if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path)
    if (!rlang::is_installed("pak") && use_pak) rlang::abort("pak is not installed. Install pak for better performance. If pak cannot be installed, set `use_pak` = FALSE in `install_ghqcapp_dependencies()` function call")

    if (use_pak) {
      res <- withr::with_options(list("pkg.sysreqs" = FALSE, repos = setup_rspm_url(ghqc_depends_snapshot_date)),
                                 pak::pkg_install(pkgs, lib = lib_path, upgrade = TRUE, ask = FALSE)) #blow cache, run this, check description file

    } else {
      if (rlang::is_installed("pak")) cli::cli_alert_warning("pak is installed, but input `use_pak` was set to FALSE. Set `use_pak` to TRUE for better performance.")
      res <- utils::install.packages(pkgs, lib = lib_path, repos = setup_rspm_url(ghqc_depends_snapshot_date))
    }

    dT <- difftime(Sys.time(), start_time)
    cli::cli_alert_success(sprintf("Installation of ghqc.app package dependencies completed in %0.2f %s", dT, units(dT)))

    # if ghqc.app is an available package, install it
    if ("ghqc.app" %in% as.data.frame(available.packages())$Package) {
      install.packages("ghqc.app",
                       lib = lib_path)
    }

    ghqcapp_status <- ghqcapp_pkg_status(lib_path)
    if (is.null(ghqcapp_status)) {
      cli::cli_alert_warning("NOTE: ghqc.app is not installed in {lib_path}. Please install before running any ghqc apps")
    }
    else {
      cli::cli_alert_success("ghqc.app {ghqcapp_status[2]} installed in {lib_path}")
    }

    invisible(res)
  }, error = function(e) {
    cli::cli_inform(c("Package installation failed",
                      "*" = "ghqc will not work as expected.",
                      "i" = "If issue persists, please contact the authors"))
    rlang::abort(message = e$message, class = "error", parent = e$parent)
  })
}

#' Remove all content in the specified lib path. Optionally removes the cache as well.
#' @param lib_path *(optional)* the path to the installed dependency packages. If not set, defaults to ghqc_libpath()
#' @param cache *(optional)* flag of whether to clear the cache or not. Defaults to keeping the cache
#' @param .remove_all *(optional)* flag to delete all contents in the basepath: ~/.local/share/ghqc/rpkgs
#'
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_abort
#' @importFrom fs dir_exists
#' @importFrom fs dir_delete
#'
#' @return information related to deleted lib path
#' @export
remove_ghqcapp_dependencies <- function(lib_path = ghqc_libpath(),
                           cache = FALSE,
                           .remove_all = FALSE) {


  msg <- ifelse(cache, "cache and all packages", "all packages")
  base_dir <- get_basepath()
  deleted_dir <- ifelse(.remove_all, base_dir, lib_path)
  cli::cli_inform("Removing {msg} in {deleted_dir}...")

  tryCatch({
    if (cache) {
      if (fs::dir_exists("~/.cache/R/pkgcache")) fs::dir_delete("~/.cache/R/pkgcache/")
      cli::cli_alert_success("Cache successfully cleared")
    }

    if (.remove_all) {
      if (fs::dir_exists(base_dir)) fs::dir_delete(base_dir)

      cli::cli_alert_success("All content in {base_dir} was successfully removed")
      return(invisible())
    }

    if (fs::dir_exists(lib_path)) fs::dir_delete(lib_path)

    cli::cli_alert_success("All packages in {lib_path} were successfully removed")
  }, error = function(e) {
    cli::cli_abort("All packages in {lib_path} were not removed due to {e$message}")
  })
}

#' @importFrom cli cli_alert_warning
setup_rspm_url <- function(snapshot_date) {
  # check if linux
  if (grepl("linux", get_os_arch())) {
    code_name <- find_linux_os_info()$version_codename
    url_binary <- file.path("https://packagemanager.posit.co/cran/__linux__", code_name, snapshot_date)
    # check if the binary url is valid, if it is return it
    if (test_repo_url(url_binary)) {
      return(c("CRAN" = url_binary))
    }
    cli::cli_alert_warning("Linux binary for {code_name} not found. Using source packages")
  }
  # if its not linux OR the binary url isn't valid, test and return the source url
  c("CRAN" = source_and_test(snapshot_date))
}

source_and_test <- function(snapshot_date) {
  url <- file.path("https://packagemanager.posit.co/cran", snapshot_date)
  if (!test_repo_url(url)) abort_source(url, snapshot_date)
  url
}

#' @importFrom cli cli_abort
abort_source <- function(url, snapshot_date) {
  cli::cli_abort("Repository could not be found for {snapshot_date}. Please use different date (repository url: {url})")
}

#' @importFrom withr with_options
#' @importFrom utils available.packages
#' @importFrom rlang is_installed
test_repo_url <- function(url) {
  if (rlang::is_installed("pak")) {
    any(withr::with_options(list(repos = url), pak::repo_status(bioc = FALSE, cran_mirror = url))$ok)
  } else {
    tryCatch({
      utils::available.packages(repos = url)
      TRUE
    }, error = function(e) {
      FALSE
    })
  }
}



#' @importFrom rlang is_installed
#' @importFrom rlang abort
install_dev_ghqcapp <- function(branch = NULL, remote_path = "a2-ai/ghqc.app",
                             lib_path = ghqc_libpath(),
                             .local = FALSE) {
  if (.local) {
    ghqc_ver <- ghqc_local_ver()
    if (rlang::is_installed("pak")) {
      res <- pak::pkg_install(ghqc_ver$path, lib = lib_path, ask = FALSE)
      return(invisible(res))
    }
    res <- install.packages(ghqc_ver$path, lib = lib_path)
    return(invisible(res))
  }

  tryCatch({
    pkg_input_path <- ifelse(is.null(branch), remote_path, paste0(remote_path, "@", branch))

    pak::pkg_install(pkg_input_path, lib = lib_path, ask = FALSE)
  }, error = function(e) {
    rlang::abort(paste("Remote ghqc.app cannot be found:", e$message))
  })
}

#' @importFrom fs dir_ls
#' @importFrom cli cli_abort
#' @importFrom utils compareVersion
ghqc_local_ver <- function() {
  ls <- fs::dir_ls("~", regexp = "ghqc.app_(.*?).tar.gz$")
  if (length(ls) == 0) {
    cli::cli_abort(c("x" = "Local version of ghqc.app not found",
                     " " = "ghqc will not work as expected.",
                     " " = "Please download a ghqc.app .tar.gz file to your home directory (~/)"))
  }
  ghqc_versions <- sapply(regmatches(ls, regexec("ghqc.app_(.*?).tar.gz$", ls)), function(x) x[2])
  max_ver <- ghqc_versions[1]
  for (ver in ghqc_versions) {
    if (utils::compareVersion(ver, max_ver) == 1) max_ver <- ver
  }
  list(path = ls[ghqc_versions == max_ver], ver = max_ver)
}
