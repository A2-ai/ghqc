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

  tryCatch({
    start_time <- Sys.time()
    cli::cli_inform("Installing ghqc.app package dependencies...")
    if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path)
    if (!rlang::is_installed("pak") && use_pak) rlang::abort("pak is not installed. Install pak for better performance. If pak cannot be installed, set `use_pak` = FALSE in `install_ghqcapp_dependencies()` function call")

    if (use_pak) {
      res <- withr::with_options(list("pkg.sysreqs" = FALSE, repos = setup_rpsm_url(ghqc_depends_snapshot_date)),
                                 pak::pkg_install(pkgs, lib = lib_path, upgrade = TRUE, ask = FALSE)) #blow cache, run this, check description file

    } else {
      if (rlang::is_installed("pak")) cli::cli_alert_warning("pak is installed, but input `use_pak` was set to FALSE. Set `use_pak` to TRUE for better performance.")
      res <- utils::install.packages(pkgs, lib = lib_path, repos = setup_rpsm_url(ghqc_depends_snapshot_date))
    }
    dT <- difftime(Sys.time(), start_time)
    cli::cli_alert_success(sprintf("Installation of ghqc.app package dependencies completed in %0.2f %s", dT, units(dT)))
    if (is.null(ghqcapp_pkg_status(lib_path))) cli::cli_alert_warning("NOTE: ghqc.app is not installed in {lib_path}. Please install before running any ghqc apps")
    invisible(res)
  }, error = function(e) {
    cli::cli_inform(c("Package installation failed",
                      "*" = "ghqc will not work as epected.",
                      "i" = "If issue pursists, please contact the authors"))
    rlang::abort(class = "error", parent = e$parent)
  })
}

#' Remove all content in the specified lib path. Optionally removes the cache as well.
#' @param lib_path *(optional)* the path to the installed dependency packages. If not set, defaults to ghqc_libpath()
#' @param cache *(optional)* flag of whether to clear the cache or not. Defaults to keeping the cache
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
                           .only_base = FALSE) {
  if (.only_base) {
    # can't just delete everything because the packages may have been downloaded in the new style,
    # hence the name of the flag .only_base, excluding the new convention
    base_dir <- ghqc_basepath()
    base_dir_contents <- dir_ls(base_dir, type = "directory", recurse = FALSE)

    folder_names_to_remove <- ghqc_depends
    dirs_to_remove <- base_dir_contents[basename(base_dir_contents) %in% folder_names_to_remove]
    # include _cache and ghqc.app folders
    dirs_to_remove <- c(dirs_to_remove, file.path(base_dir, "_cache"), file.path(base_dir, "ghqc.app"))

    fs::file_delete(dirs_to_remove)
    return()
  }

  msg <- ifelse(cache, "cache and all packages", "all packages")
  cli::cli_inform("Removing {msg} in {lib_path}...")
  tryCatch({
    if (cache){
      if (fs::dir_exists("~/.cache/R/pkgcache")) fs::dir_delete("~/.cache/R/pkgcache/")
      cli::cli_alert_success("Cache successfully cleared")
    }

    if (fs::dir_exists(lib_path)) fs::dir_delete(lib_path)
    cli::cli_alert_success("All packages in {lib_path} were successfully removed")
  }, error = function(e) {
    cli::cli_abort("All packages in {lib_path} were not removed due to {e$message}")
  })
}

#' @importFrom cli cli_alert_warning
setup_rspm_url <- function(snapshot_date) {
  repo <- if (grepl("linux", R.version$platform)) {
    code_name <- find_os_release()
    if (is.na(code_name)) {
      source_and_test(snapshot_date)
    } else {
      url <- file.path("https://packagemanager.posit.co/cran/__linux__", code_name, snapshot_date)
      if (!test_repo_url(url)) {
        cli::cli_alert_warning("Linux binary for {code_name} not found. Using source packages")
        source_and_test(snapshot_date)
      }
      url
    }
  } else {
    source_and_test(url)
  }

  c("CRAN" = repo)
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
    withr::with_options(list(repos = url), pak::repo_status(bioc = FALSE, cran_mirror = url))$ok
  } else {
    tryCatch({
      utils::available.packages(repos = url)
      TRUE
    }, error = function(e) {
      FALSE
    })
  }
}

find_os_release <- function() {
  if (grepl("linux", R.version$platform)) {
    return(
      tryCatch({
        gsub(".*=", "",
             grep("VERSION_CODENAME",
                  readLines("/etc/os-release"),
                  value = TRUE
                  )
             ) #gsub
      }, error = function(e) {
        NA
      })
    )
  }

  tryCatch({
      Sys.info()["release"]
    }, error = function(e) {
      NA
    })
}


#' @importFrom rlang is_installed
#' @importFrom rlang abort
install_dev_ghqcapp <- function(remote_path = "a2-ai/ghqc.app",
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
    pak::pkg_install(remote_path, lib = lib_path, ask = FALSE)
  }, error = function(e) {
    rlang::abort("Remote ghqc.app cannot be found", parent = "Remote ghqc.app cannot be found")
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
