#' Situation report for ghqc set-up
#'
#' @param ... options to expand output. Current option is only "pkgs" to expand list of dependencies
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc custom configuration
#'
#' @return This function is primarily used for its printed output, not a returned output
#'
#' @importFrom cli cli_h1
#' @importFrom cli cli_h2
#'
#' @export
ghqc_sitrep <- function(...,
                        lib_path = ghqc_libpath(),
                        config_path = ghqc_config_path()){
  inputs <- c(...)

  cli::cli_h1("Environment")
  cli::cli_alert_info(sprintf("R version: %s", get_r_version()))
  cli::cli_alert_info(sprintf("Operating system: %s", get_platform()))


  cli::cli_h1("Package Dependencies")
  sitrep_dep_check(lib_comparison(lib_path), lib_path)
  if ("pkgs" %in% inputs) {
    cli::cli_h2("Local vs Approved Package Version Comparison")
    pkg_output_table(rbind(lib_comparison(lib_path), ghqcapp_pkg_status(lib_path)))
  }

  cli::cli_h1("Renviron Settings")
  sitrep_renviron_check()

  config_repo_section = FALSE
  tryCatch({
    config_path
    config_repo_section = TRUE
  }, error = function(e) {
    config_repo_section = FALSE
  }) # if config_path not self set AND GHQC_CONFIG_REPO not set, section will be omitted
  if (config_repo_section){
    cli::cli_h1("Custom configuration Repository")
    sitrep_config_check(config_path)
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
    ghqcapp_version <- utils::packageVersion("ghqc.app", lib.loc = ghqc::ghqc_libpath())
    cli::cli_alert_success("ghqc.app {ghqcapp_version} is installed in {lib_path}")
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
         cli::cli_alert_danger("GHQC_CONFIG_REPO is not set in ~/.Renviron"),
         cli::cli_alert_success("GHQC_CONFIG_REPO is set to {sysenv}"))
  invisible(NA)
}

#' @importFrom fs file_exists
sitrep_read_renviron <- function() {
  if (fs::file_exists("~/.Renviron")) {
    readRenviron("~/.Renviron")
    Sys.getenv("GHQC_CONFIG_REPO")
  } else {
    ""
  }
}

### Custom configuration Repo ###
#' @importFrom cli cli_alert_danger
sitrep_config_check <- function(config_path) {
  switch(config_repo_status(config_path),
         "clone" = cli::cli_alert_danger(sprintf("%s cannot be found locally", config_repo_name())),
         "update" = sitrep_repo_update(config_path),
         "none" = sitrep_repo_none(config_path),
         "gert" = sitrep_repo_gert(config_path)
         )
}

#' @importFrom cli cli_alert_warning
sitrep_repo_update <- function(config_path) {
  cli::cli_alert_warning(sprintf("%s was found locally but needs to be updated", config_repo_name()))
  print_local_content(config_path)
}

#' @importFrom cli cli_alert_success
sitrep_repo_none <- function(config_path) {
  cli::cli_alert_success(sprintf("%s was successfully found locally", config_repo_name()))
  print_local_content(config_path)
}

#' @importFrom cli cli_alert_warning
sitrep_repo_gert <- function(config_path) {
  sitrep_repo_none(config_path)
  cli::cli_alert_warning("Package 'gert' (>= 1.5.0) was not installed to check if custom configuration repository is up to date")
}

#' @importFrom cli cli_inform
#' @importFrom cli cli_h2
print_local_content <- function(config_path) {
  cli::cli_inform(sprintf("    Local Directory: %s", config_path))
  cli::cli_h2(sprintf("%s Local Content", config_repo_name()))
  config_files_desc(config_path)
}

