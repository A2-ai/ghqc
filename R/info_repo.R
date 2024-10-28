#' Check the content of the downloaded ghqc configuration information repository and download any updates needed
#'
#' @param info_path *(optional)* path in which the repository, set in environmental variable `GHQC_INFO_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#'
#' @importFrom cli cli_abort
#' @export
check_ghqc_configuration <- function(info_path = ghqc_infopath()) {
  if (!interactive()) cli::cli_abort("Attempting to run in non-interactive function. Use {.code download_ghqc_configuration()} in non-interactive sections")
  check_ghqc_info_repo_exists()
  switch(info_repo_status(info_path),
         "clone" = prompt_repo_clone(info_path),
         "update" = prompt_repo_update(info_path),
         "none" = no_updates(info_path),
         "gert" = no_gert_found(info_path)
  )
}

#' Download the customizing information repository as set in environmental variable `GHQC_INFO_REPO`
#'
#' @param info_path *(optional)* path in which the repository, set in environmental variable `GHQC_INFO_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#' @param .force *(optional)* option to force a new download of the ghqc configuration information repository
#' @export
download_ghqc_configuration <- function(info_path = ghqc_infopath(), .force = FALSE) {
  check_ghqc_info_repo_exists()
  switch(info_repo_status(info_path, .force),
         "clone" = repo_clone(info_path),
         "update" = repo_clone(info_path),
         "none" = no_updates(info_path),
         "gert" = no_gert_found(info_path)
  )
}
#' Remove the downloaded customizing information repository from `info_path`
#' @param info_path *(optional)* path in which the repository, set in environmental variable `GHQC_INFO_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#'
#' @return this function is used for its effects, but will return the removed `info_path`
#'
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_abort
#' @importFrom fs dir_exists
#' @importFrom fs dir_delete
#'
#' @export
remove_ghqc_configuration <- function(info_path = ghqc_infopath()) {
  cli::cli_inform("Removing downloaded customizing information in {info_path}...")
  tryCatch({
    if (fs::dir_exists(info_path)) fs::dir_delete(info_path)
    cli::cli_alert_success("All packages in {info_path} were successfully removed")
  }, error = function(e) {
    cli::cli_abort("All packages in {info_path} were not removed due to {e$message}")
  })
  info_path
}

# local status check #
#' @importFrom fs file_exists
#' @importFrom rlang is_installed
info_repo_status <- function(info_path, .force = FALSE) {
  if (.force) return("clone")
  if (!fs::file_exists(info_path)) return("clone")
  if (!rlang::is_installed("gert")) return("gert")
  if (remote_repo_updates(info_path)) return("update")
  return("none")
}

remote_repo_updates <- function(info_path) {
  remote_repo_updates <- gert::git_remote_ls(repo = info_path, verbose = FALSE)$oid[1] != gert::git_info(repo = info_path)$commit
}

# repo clone #

#' @importFrom cli cli_alert_danger
prompt_repo_clone <- function(info_path) {
  cli::cli_alert_danger(sprintf("Info repository %s is not found locally", basename(info_path)))
  yN <- readline(prompt = "Would you like to download the repository (y/N)? ")
  if (yN == "y") {
    repo_clone(info_path)
  } else {
    cli::cli_alert_danger("Run 'ghqc::download_info_repo() before running any of the ghqc ecosystem apps")
  }
}

# repo update #
#' @importFrom cli cli_alert_warning
#' @importFrom cli cli_alert_danger
prompt_repo_update <- function(info_path) {
  cli::cli_alert_warning(sprintf("Info repository %s was found locally, but is not the most recent version", basename(info_path)))
  yN <- readline(prompt = "Would you like to update the repository. This will delete all local changes to {info_path} (y/N)? ")
  if (yN == "y") {
    repo_clone(info_path)
  } else {
    cli::cli_alert_danger("Run 'ghqc::download_info_repo()' before running any of the ghqc ecosystem apps")
  }
}

#' @importFrom rlang is_installed
#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_alert
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_abort
#' @importFrom cli cli_h2
#' @importFrom fs dir_exists
#' @importFrom fs dir_delete
repo_clone <- function(info_path) {
  if (!rlang::is_installed("gert", version = "1.5.0")) {
    cli::cli_alert_danger(sprintf("Package 'gert' (>= 1.5.0) is not installed. %s cannot be cloned", info_repo_url()))
    return()
  }
  cli::cli_alert("Attempting to clone {info_repo_url()} to {info_path}...")
  tryCatch({
    if (fs::dir_exists(info_path)) fs::dir_delete(info_path)
    gert::git_clone(info_repo_url(), path = info_path, verbose = FALSE)
    cli::cli_alert_success("Successfully cloned {info_repo_name()} to {info_path}")
    invalidate_checklists(info_path)
    cli::cli_h2("{basename(info_path)} Local Content")
    info_files_desc(info_path)
  }, error = function(e) {
    cli::cli_abort(message = c(sprintf("Clone of %s was not succesful", info_repo_name()),
                               "x" = sprintf("Error is due to: %s", e$message)))
  })
}

#' @importFrom cli cli_inform
no_updates <- function(info_path) {
  invalidate_checklists(info_path)
  cli::cli_inform("Configuration Information Repository found up to date at {info_path}")
  info_files_desc(info_path)
}


# no gert found #
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_warning
no_gert_found <- function(info_path) {
  cli::cli_inform("Configuration Information Repository at {info_path}")
  info_files_desc(info_path)
  cli::cli_inform("")
  cli::cli_alert_warning("Package 'gert' (>= 1.5.0) was not installed to check if information repository is up to date")
}

# info repo description #
#' @importFrom fs file_exists
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_info
info_files_desc <- function(info_path) {
  repo_files <- info_repo_files(info_path)
  if (fs::file_exists(repo_files[1])) {
    cli::cli_alert_success("logo.png successfully found")
  } else {
    cli::cli_alert_danger("logo.png not found")
  }
  cli::cli_inform(" ")

  if (fs::file_exists(repo_files[2])) {
    note_found(repo_files[2])
  } else {
    cli::cli_alert_info("'note' not found. This file is not required")
    cli::cli_inform(" ")
  }

  if (fs::file_exists(repo_files[3])) {
    if (length(fs::dir_ls(file.path(info_path, "checklists"), regexp = "(.*?).yaml")) == 0) {
      cli::cli_alert_danger("Checklists directory is empty")
    } else {
      checklists_found(info_path)
    }
  } else {
    cli::cli_alert_danger("Checklists directory not found")
  }
}

info_repo_files <- function(info_path) {
  file.path(info_path, c("logo.png", "note", "checklists"))
}

#' @importFrom cli cli_alert_success
#' @importFrom cli cli_blockquote
note_found <- function(note_path) {
  cli::cli_alert_success("'note' successfully found")
  cli::cli_blockquote(readLines(note_path))
}

#' @importFrom cli cli_alert_success
#' @importFrom cli cli_h3
checklists_found <- function(info_path) {
  cli::cli_alert_success("Checklists directory successfully found")
  cli::cli_h3("Checklist directory content")
  print_checklists(info_path)
}

# Checking and setting repo name and url #
#' @importFrom fs file_exists
#' @importFrom cli cli_abort
check_ghqc_info_repo_exists <- function() {
  if (!fs::file_exists("~/.Renviron")) info_repo_not_found()
  readRenviron("~/.Renviron")
  info_repo <- Sys.getenv("GHQC_INFO_REPO")
  if (info_repo == "") info_repo_not_found()
  if (substr(info_repo, 1, 8) != "https://") {
    cli::cli_abort("GHQC_INFO_REPO ({info_repo}) does not start with 'https://'")
  }
}

info_repo_name <- function() {
  gsub(".git", "", basename(info_repo_url()))
}

info_repo_url <- function() {
  check_ghqc_info_repo_exists()
  Sys.getenv("GHQC_INFO_REPO")
}

#' @importFrom cli cli_abort
info_repo_not_found <- function() {
  cli::cli_abort(message = "GHQC_INFO_REPO not found. Please set in ~/.Renviron")
}
