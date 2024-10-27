#' Situation report for ghqc set-up
#'
#' @param ... options to expand output. Current option is only "pkgs" to expand list of dependencies
#' @param lib_path the path to the ghqc package and its dependencies
#' @param info_path the path to the ghqc customizing information
#'
#' @return This function is primarily used for its printed output, not a returned output
#'
#' @importFrom cli cli_h1
#' @importFrom cli cli_h2
#'
#' @export
ghqc_sitrep <- function(...,
                        lib_path = ghqc_libpath(),
                        info_path = ghqc_infopath()){
  inputs <- c(...)

  cli::cli_h1("Package Dependencies")
  sitrep_dep_check(lib_comparison(lib_path), lib_path)
  if ("pkgs" %in% inputs) {
    cli::cli_h2("Local vs Approved Package Version Comparison")
    pkg_output_table(rbind(lib_comparison(lib_path), ghqcapp_pkg_status(lib_path)))
  }

  cli::cli_h1("Renviron Settings")
  sitrep_renviron_check()

  info_repo_section = FALSE
  tryCatch({
    info_path
    info_repo_section = TRUE
  }, error = function(e) {
    info_repo_section = FALSE
  }) # if info_path not self set AND GHQC_INFO_REPO not set, section will be ommitted
  if (info_repo_section){
    cli::cli_h1("Information Repository")
    sitrep_info_check(info_path)
  }
}

## write table to stdout instead of arrows at dots

### Package Dependencies ###
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_alert_info
sitrep_dep_check <- function(lib_comp, lib_path) {
  sitrep_add_pkgs(lib_comp[is.na(lib_comp$Installed_Version), ], max(nchar(lib_comp$Package)))

  upg_pkgs <- lib_comp[ver_comp(lib_comp) == -1 & !is.na(lib_comp$Installed_Version), ]
  sitrep_upg_pkgs(upg_pkgs, max(nchar(lib_comp$Package)))

  correct_pkgs <- lib_comp[ver_comp(lib_comp) == 0 | (ver_comp(lib_comp) == 1 & !is.na(lib_comp$Recommended_Version)), ]
  cli::cli_alert_success(sprintf("Packages correctly installed: %i", dim(correct_pkgs)[1]))

  extra_pkgs <- lib_comp[is.na(lib_comp$Recommended_Version), ]
  cli::cli_alert_info(sprintf("Extra packages installed: %i", dim(extra_pkgs)[1]))

  if (is.null(ghqcapp_pkg_status(lib_path))) {
    cli::cli_inform("")
    cli::cli_alert_danger("ghqc.app is not installed in {lib_path}")
  } else {
    cli::cli_inform("")
    cli::cli_alert_success("ghqc.app is installed in {lib_path}")
  }
}

lib_comparison <- function(lib_path) {
  inst_pkgs <- installed_pkgs(lib_path)
  if (length(inst_pkgs) == 0) return(cbind(rec_pkgs(), "Installed_Version" = NA)[,c(1,3,2)])
  comp <- merge(inst_pkgs, rec_pkgs(), by = "Package", all = TRUE)
  comp[comp$Package != "ghqc" & comp$Package != "ghqc.app", ]
}

#' @importFrom cli cli_alert_danger
sitrep_add_pkgs <- function(add_pkgs, max_pkg) {
  cli::cli_alert_danger(sprintf("Packages not installed: %i", dim(add_pkgs)[1]))
  if (dim(add_pkgs)[1] > 0) pkg_output_table(add_pkgs)
}

#' @importFrom cli cli_alert_warning
sitrep_upg_pkgs <- function(upg_pkgs, max_pkg) {
  cli::cli_alert_warning(sprintf("Package upgrades needed: %i", dim(upg_pkgs)[1]))
  if (dim(upg_pkgs)[1] > 0) {
    pkg_output_table(upg_pkgs)
  }
}

sitrep_pkg_status <- function(pkg_comp) {
  if (is.na(pkg_comp$Installed_Version)) return("danger")
  if (is.na(pkg_comp$Recommended_Version)) return("info")
  if (ver_comp(pkg_comp) == -1) return("warning")
  return("success")
}

#' @importFrom utils installed.packages
ghqcapp_pkg_status <- function(lib_path) {
  ip <- as.data.frame(installed.packages(lib.loc = lib_path))[, c("Package", "Version")]
  if ("ghqc.app" %in% ip$Package) return(c("ghqc.app", ip["ghqc.app", "Version"], ip["ghqc.app", "Version"]))
  NULL
}

### Renviron Check ###
#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_alert_success
sitrep_renviron_check <- function() {
  sysenv <- sitrep_read_renviron()
  ifelse(sysenv == "",
         cli::cli_alert_danger("GHQC_INFO_REPO is not set in ~/.Renviron"),
         cli::cli_alert_success("GHQC_INFO_REPO is set to {sysenv}"))
  invisible(NA)
}

#' @importFrom fs file_exists
sitrep_read_renviron <- function() {
  if (fs::file_exists("~/.Renviron")) {
    readRenviron("~/.Renviron")
    Sys.getenv("GHQC_INFO_REPO")
  } else {
    ""
  }
}

### Information Repo ###
#' @importFrom cli cli_alert_danger
sitrep_info_check <- function(info_path) {
  switch(info_repo_status(info_path),
         "clone" = cli::cli_alert_danger(sprintf("%s cannot be found locally", info_repo_name())),
         "update" = sitrep_repo_update(info_path),
         "none" = sitrep_repo_none(info_path),
         "gert" = sitrep_repo_gert(info_path)
         )
}

#' @importFrom cli cli_alert_warning
sitrep_repo_update <- function(info_path) {
  cli::cli_alert_warning(sprintf("%s was found locally but needs to be updated", info_repo_name()))
  print_local_content(info_path)
}

#' @importFrom cli cli_alert_success
sitrep_repo_none <- function(info_path) {
  cli::cli_alert_success(sprintf("%s was successfully found locally", info_repo_name()))
  print_local_content(info_path)
}

#' @importFrom cli cli_alert_warning
sitrep_repo_gert <- function(info_path) {
  sitrep_repo_none(info_path)
  cli::cli_alert_warning("Package 'gert' (>= 1.5.0) was not installed to check if information repository is up to date")
}

#' @importFrom cli cli_inform
#' @importFrom cli cli_h2
print_local_content <- function(info_path) {
  cli::cli_inform(sprintf("    Local Directory: %s", info_path))
  cli::cli_h2(sprintf("%s Local Content", info_repo_name()))
  info_files_desc(info_path)
}

