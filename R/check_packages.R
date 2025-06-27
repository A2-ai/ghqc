#' Check the installed/linked packages in `lib_path` against the recommended ghqc.app dependency package version
#'
#' @param lib_path *(optional)* the path to the installed/linked dependencies. If not set, defaults to ghqc_libpath()
#' @param use_pak *(optional)* optionally removes the requirement to have `pak` installed in the project repository. Setting to `FALSE` will reduce performance
#'
#' @return This function is primarily used for its printed results and subsequent actions, not a returned output.
#' Will return a dataframe of package upgrades needed
#'
#' @importFrom fs dir_exists
#' @importFrom fs dir_create
#' @importFrom cli cli_alert_success
#'
#' @export
check_ghqcapp_dependencies <- function(lib_path = ghqc_libpath(),
                                       use_pak = TRUE) {

  check_pak_version(use_pak)

  if (!fs::dir_exists(lib_path)) fs::dir_create(lib_path)
  res <- check_lib_status(lib_path)
  switch(res$status,
         "all_upg" = all_upg_needed(lib_path, use_pak),
         "some_upg" = some_upg_needed(lib_path, res$upg_needed, use_pak),
         "no_upg" = {
           cli::cli_alert_success(sprintf("All ghqc.app dependency packages in %s are up to date", lib_path))
         }
         )

  # if ghqc.app available, install it

  invisible(res$upg_needed)
}

#' @importFrom fs dir_ls
check_lib_status <- function(lib_path) {
  if (nrow(installed_pkgs(lib_path)) == 0) return(list(status = "all_upg", upg_needed = cbind(rec_pkgs(), Installed_Version = NA)[c(1,3,2)]))

  diffs <- pkg_diffs(installed_pkgs(lib_path), rec_pkgs())
  if (dim(diffs)[1] == 0) {
    list(status = "no_upg")
  } else {
    list(status = "some_upg", upg_needed = diffs)
  }
}

#' @importFrom utils installed.packages
installed_pkgs <- function(lib_path) {
  inst_pkgs <- as.data.frame(installed.packages(lib.loc = lib_path))[c("Package", "Version")]
  inst_pkgs <- cbind(inst_pkgs, "Installed_Version" = gsub("-", ".", inst_pkgs$Version))
  inst_pkgs[,-2]
}

#' @importFrom utils available.packages
rec_pkgs <- function() {
  ap <- as.data.frame(utils::available.packages(repos = setup_rspm_url(ghqc_depends_snapshot_date)))
  ap <- ap[ap$Package %in% ghqc_depends, c("Package", "Version")]
  colnames(ap) <- c("Package", "Recommended_Version")
  ap$Recommended_Version <- gsub("-", ".", ap$Recommended_Version)
  invisible(ap)
}

pkg_diffs <- function(installed_pkgs, rec_pkgs) {
  lib_comp <- merge(installed_pkgs, rec_pkgs, by = "Package", all = TRUE)
  lib_comp[ver_comp(lib_comp) == -1, ]
}

#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_abort
all_upg_needed <- function(lib_path, use_pak) {
  cli::cli_alert_danger(sprintf("No packages found in %s", lib_path))
  if (!interactive()) {
    cli::cli_abort("Function not ran interactively. Call {.code ghqc_sitrep()} for package dependency status or {.code install_ghqcapp_dependencies()} to install package dependencies.")
  }
  yN <- readline("Would you like to install the ghqc.app dependencies (y/N)? ")
  upg_pkgs(yN, lib_path, use_pak = use_pak)
}

#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_abort
some_upg_needed <- function(lib_path, upg_needed, use_pak) {
  cli::cli_alert_danger(sprintf("Some dependency packages in %s may not be found or require updates", lib_path))
  pkg_output_table(upg_needed)
  if (!interactive()) {
    cli::cli_abort("Function not ran interactively. Call {.code ghqc_sitrep()} for package dependency status or {.code install_ghqcapp_dependencies()} to install package dependencies.")
  }
  yN <- readline("Would you like to install or update the above packages (y/N)? ")
  upg_pkgs(yN, lib_path, pkgs = upg_needed$Package, use_pak = use_pak)
}

#' @importFrom utils write.table
pkg_output_table <- function(upg_needed) {
  max_pkg <- max(c(nchar(upg_needed$Package), nchar("Package")))
  pkg_inst_sep <- paste0(strrep(" ", max_pkg - nchar(upg_needed$Package)), " ")
  pkg_inst_name_sep <- paste0(strrep(" ", max_pkg - nchar("Package")), " ")

  max_inst <- max(c(nchar(upg_needed$Installed_Version), nchar("Installed_Version")))
  if (is.na(max_inst)) max_inst <- nchar("Installed_Version")
  inst_rec_sep <- paste0(strrep(" ", ifelse(is.na(upg_needed$Installed_Version), max_inst-2, max_inst - nchar(upg_needed$Installed_Version))), " ")
  inst_rec_name_sep <- paste0(strrep(" ", max_inst - nchar("Installed_Version")), " ")

  ## Due to using columns to even out table and column names, if the column names are both the same, an extra space is needed
  if (pkg_inst_name_sep == inst_rec_name_sep) {
    inst_rec_sep <- paste0(inst_rec_sep, " ")
    inst_rec_name_sep <- paste0(inst_rec_name_sep, " ")
  }

  tbl <- cbind(upg_needed, pkg_inst_sep, inst_rec_sep)
  names(tbl) <- c(names(upg_needed), pkg_inst_name_sep, inst_rec_name_sep)

  utils::write.table(tbl[ ,c(1,4,2,5,3)], file = stdout(), quote = FALSE, row.names = FALSE)
  tbl[ ,c(1,4,2,5,3)]
}

#' @importFrom cli cli_alert_warning
upg_pkgs <- function(yN, lib_path, pkgs = ghqc_depends, use_pak) {
  if (yN == "y") {
    install_ghqcapp_dependencies(lib_path, pkgs = pkgs, use_pak = use_pak)

  } else {
    cli::cli_alert_warning("Run {.code install_ghqcapp_dependencies()} before running any other ghqc functions")
    if (is.null(ghqcapp_pkg_status(lib_path))) cli::cli_alert_warning("NOTE: ghqc.app is not installed in {lib_path}. Please install before running any ghqc apps")
    NA
  }
}

#' @importFrom utils compareVersion
ver_comp <- function(lib_comp) {
  apply(lib_comp, 1, function(x) utils::compareVersion(x["Installed_Version"], x["Recommended_Version"]))
}




