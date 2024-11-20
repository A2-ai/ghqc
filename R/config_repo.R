#' Check the content of the downloaded ghqc custom configuration repository and download any updates needed
#'
#' @param config_path *(optional)* path in which the repository, set in environmental variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#'
#' @importFrom cli cli_abort
#' @export
check_ghqc_configuration <- function(config_path = ghqc_config_path()) {
  if (!interactive()) cli::cli_abort("Attempting to run in non-interactive function. Use {.code download_ghqc_configuration()} in non-interactive sections")
  check_ghqc_config_repo_exists()
  switch(config_repo_status(config_path),
         "clone" = prompt_repo_clone(config_path),
         "update" = prompt_repo_update(config_path),
         "none" = no_updates(config_path),
         "gert" = no_gert_found(config_path)
  )
}

#' Download the custom configuration repository as set in environmental variable `GHQC_CONFIG_REPO`
#'
#' @param config_path *(optional)* path in which the repository, set in environmental variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#' @param .force *(optional)* option to force a new download of the ghqc custom configuration repository
#' @export
download_ghqc_configuration <- function(config_path = ghqc_config_path(), .force = FALSE) {
  check_ghqc_config_repo_exists()
  switch(config_repo_status(config_path, .force),
         "clone" = repo_clone(config_path),
         "update" = repo_clone(config_path),
         "none" = no_updates(config_path),
         "gert" = no_gert_found(config_path)
  )
}
#' Remove the downloaded custom configuration repository from `config_path`
#' @param config_path *(optional)* path in which the repository, set in environmental variable `GHQC_CONFIG_REPO`, is, or should be, downloaded to. Defaults to `~/.local/share/ghqc/{repo_name}`
#'
#' @return this function is used for its effects, but will return the removed `config_path`
#'
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_abort
#' @importFrom fs dir_exists
#' @importFrom fs dir_delete
#'
#' @export
remove_ghqc_configuration <- function(config_path = ghqc_config_path()) {
  cli::cli_inform("Removing downloaded custom configuration in {config_path}...")
  tryCatch({
    if (fs::dir_exists(config_path)) fs::dir_delete(config_path)
    cli::cli_alert_success("Custom configuration in {config_path} successfully removed")
  }, error = function(e) {
    cli::cli_abort("Custom configuration in {config_path} not removed due to {e$message}")
  })
  config_path
}

# local status check #
#' @importFrom fs file_exists
#' @importFrom rlang is_installed
config_repo_status <- function(config_path, .force = FALSE) {
  if (.force) return("clone")
  if (!fs::file_exists(config_path)) return("clone")
  if (!rlang::is_installed("gert")) return("gert")
  if (remote_repo_updates(config_path)) return("update")
  return("none")
}

remote_repo_updates <- function(config_path) {
  remote_repo_updates <- gert::git_remote_ls(repo = config_path, verbose = FALSE)$oid[1] != gert::git_info(repo = config_path)$commit
}

# repo clone #

#' @importFrom cli cli_alert_danger
prompt_repo_clone <- function(config_path) {
  cli::cli_alert_danger(sprintf("Custom configuration repository %s is not found locally", basename(config_path)))
  yN <- readline(prompt = "Would you like to download the repository (y/N)? ")
  if (yN == "y") {
    repo_clone(config_path)
  } else {
    cli::cli_alert_danger("Run {.code ghqc::download_ghqc_configuration()} before running any of the ghqc ecosystem apps")
  }
}

# repo update #
#' @importFrom cli cli_alert_warning
#' @importFrom cli cli_alert_danger
prompt_repo_update <- function(config_path) {
  cli::cli_alert_warning(sprintf("Custom configuration repository %s was found locally, but is not the most recent version", basename(config_path)))
  yN <- readline(prompt = glue::glue("Would you like to update the repository. This will delete all local changes to {config_path} (y/N)? "))
  if (yN == "y") {
    repo_clone(config_path)
  } else {
    cli::cli_alert_danger("Run {.code ghqc::download_ghqc_configuration()} before running any of the ghqc ecosystem apps")
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
repo_clone <- function(config_path) {
  if (!rlang::is_installed("gert", version = "1.5.0")) {
    cli::cli_alert_danger(sprintf("Package 'gert' (>= 1.5.0) is not installed. %s cannot be cloned", config_repo_url()))
    return()
  }
  cli::cli_alert("Attempting to clone {config_repo_url()} to {config_path}...")
  tryCatch({
    if (fs::dir_exists(config_path)) fs::dir_delete(config_path)
    gert::git_clone(config_repo_url(), path = config_path, verbose = FALSE)
    cli::cli_alert_success("Successfully cloned {config_repo_name()} to {config_path}")
    invalidate_checklists(config_path)
    cli::cli_h2("{basename(config_path)} Local Content")
    config_files_desc(config_path)
  }, error = function(e) {
    cli::cli_abort(message = c(sprintf("Clone of %s was not successful", config_repo_name()),
                               "x" = sprintf("Error is due to: %s", e$message)))
  })
}

#' @importFrom cli cli_inform
no_updates <- function(config_path) {
  invalidate_checklists(config_path)
  cli::cli_inform("Custom Configuration Repository found up to date at {config_path}")
  config_files_desc(config_path)
}


# no gert found #
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_warning
no_gert_found <- function(config_path) {
  cli::cli_inform("Custom configuration Repository at {config_path}")
  config_files_desc(config_path)
  cli::cli_inform("")
  cli::cli_alert_warning("Package 'gert' (>= 1.5.0) was not installed to check if custom configuration repository is up to date")
}

# Custom configuration repo description #
#' @importFrom fs file_exists
#' @importFrom cli cli_alert_success
#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_info
config_files_desc <- function(config_path) {
  repo_files <- config_repo_files(config_path)
  if (fs::file_exists(repo_files[1])) {
    cli::cli_alert_success(paste0(cli::col_blue("logo.png"), " successfully found"))
  } else {
    cli::cli_alert_info(paste0(cli::col_blue("logo.png"), " not found. This file is not required."))
  }
  cli::cli_inform(" ")

  if (fs::file_exists(repo_files[2])) {
    custom_options_found(repo_files[2])
  } else {
    cli::cli_alert_info(paste0(cli::col_blue("options.yaml"), " not found. This file is not required."))
    cli::cli_inform("")
  }

  if (fs::file_exists(repo_files[3])) {
    if (length(fs::dir_ls(file.path(config_path, "checklists"), regexp = "(.*?).yaml")) == 0) {
      cli::cli_alert_danger(paste0(cli::col_blue("Checklist directory"), " is empty"))
    } else {
      checklists_found(config_path)
    }
  } else {
    cli::cli_alert_danger(paste0(cli::col_blue("Checklist directory"), " not found"))
  }
}

config_repo_files <- function(config_path) {
  file.path(config_path, c("logo.png", "options.yaml", "checklists"))
}

#' @importFrom cli cli_alert_success
#' @importFrom cli cli_blockquote
custom_options_found <- function(yaml_path) {
  content <- tryCatch({
    unlist(yaml::yaml.load_file(yaml_path))
  }, error = function(e) {
    NULL
  })
  if (is.null(content)) {
    cli::cli_alert_danger(paste0(cli::col_blue("{basename(yaml_path)}"), " could not be read"))
    return()
  }

  if (all(!(c("prepended_checklist_note", "checklist_display_name_var") %in% names(content)))) {
    cli::cli_alert_warning(paste0("No recognized custom options found in ", cli::col_blue("{basename(yaml_path)}")))
    return()
  }

  if ("prepended_checklist_note" %in% names(content)) {
    pcn_idx <- which("prepended_checklist_note" == names(content))
    content <- append(content[-pcn_idx], content[pcn_idx])
  }

  cli::cli_div(theme = list(ul = list(`margin-left` = 4, before = "")))
  cli::cli_alert_success(paste0(cli::col_blue("{basename(yaml_path)}"), " successfully found"))
  ul <- cli::cli_ul()
  sapply(names(content), function(x) switch(x,
                                     "prepended_checklist_note" = note_found(content[x]),
                                     "checklist_display_name_var" = checklist_display_name_found(content[x]),
                                     cli::cli_alert_info("{x} is not a recognized custom option.")))
  cli::cli_end(ul)
  if (!("prepended_checklist_note" %in% names(content))) cli::cli_inform("")
}

note_found <- function(note_content) {
  cli::cli_alert_success("{names(note_content)}:")
  cli::cli_blockquote(note_content)
}

checklist_display_name_found <- function(checklist_disp_name) {
  cli::cli_alert_success("{names(checklist_disp_name)}: {checklist_disp_name}")
}

#' @importFrom cli cli_alert_success
#' @importFrom cli cli_h3
checklists_found <- function(config_path) {
  cli::cli_div(theme = list(ul = list(`margin-left` = 4, before = "")))
  cli::cli_alert_success(paste0(cli::col_blue("Checklist directory"), " successfully found"))
  ul <- cli::cli_ul()
  print_checklists(config_path)
  cli::cli_end(ul)
}

# Checking and setting repo name and url #
#' @importFrom fs file_exists
#' @importFrom cli cli_abort
check_ghqc_config_repo_exists <- function() {
  if (!fs::file_exists("~/.Renviron")) config_repo_not_found()
  readRenviron("~/.Renviron")
  config_repo <- Sys.getenv("GHQC_CONFIG_REPO")
  if (config_repo == "") config_repo_not_found()
  if (substr(config_repo, 1, 8) != "https://") {
    cli::cli_abort("GHQC_CONFIG_REPO ({config_repo}) does not start with 'https://'")
  }
}

config_repo_name <- function() {
  gsub(".git", "", basename(config_repo_url()))
}

config_repo_url <- function() {
  check_ghqc_config_repo_exists()
  Sys.getenv("GHQC_CONFIG_REPO")
}

#' @importFrom cli cli_abort
config_repo_not_found <- function() {
  cli::cli_abort(message = "GHQC_CONFIG_REPO not found. Please set in ~/.Renviron")
}
