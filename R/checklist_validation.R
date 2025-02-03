#' @importFrom fs dir_ls
validate_checklists <- function(config_path = ghqc_config_path()) {
  if (!fs::dir_exists(file.path(config_path, "checklists"))) return(invisible())
  checklist_ls <- fs::dir_ls(file.path(config_path, "checklists"), regexp = "(.*?).yaml")
  lapply(checklist_ls, function(x) val_checklist(x))
}

checklist_has_trailing_newline <- function(file) {
  content <- readChar(file, file.info(file)$size, useBytes = TRUE)
  if (nchar(content) == 0) return(FALSE)  # empty file
  return(substr(content, nchar(content), nchar(content)) == "\n")
}

#' @importFrom yaml yaml.load_file
val_checklist <- function(checklist) {
  content <- tryCatch({
    yaml::yaml.load_file(checklist, readLines.warn = FALSE)
  },
  error = function(e) {
    NULL
  })

  if (is.null(content)) return(list(valid = FALSE, reason = "File is not a valid yaml format"))
  if (length(content) == 0) return(list(valid = FALSE, reason = "File is blank")) #CASE 1: empty file
  if (length(content) != 1) return(list(valid = FALSE, reason = "There are too many top level elements. The only top level should be the checklist title")) # CASE 2: Multiple top levels that create multiple lists when reading in the yaml
  if (!inherits(content, "list")) return(list(valid = FALSE, reason = "Only strings found. Use ':' for headers and '-' for checklist items")) # CASE 3: only a single. No top levels or elements
  if (any(sapply(content[[1]], function(x) class(x) != "character"))) return(list(valid = FALSE, reason = "There are too many sublevels. Checklist only supports a title and one section level"))
  if (!checklist_has_trailing_newline(checklist)) return(list(valid = TRUE, reason = "File does not have a trailing newline")) # checklist is valid, but give a warning
  list(valid = TRUE, reason = NA)
}

invalidate_checklists <- function(config_path = ghqc_config_path()) {
  check_structure <- validate_checklists(config_path)
  sapply(names(check_structure), function(x) invalid_checklist_rename(x, check_structure[[x]]$valid))
}

#' @importFrom fs file_move
invalid_checklist_rename <- function(checklist, check_structure) {
  new_name <- gsub("INVALID - ", "", checklist)
  if (!check_structure) {
    new_name <- file.path(dirname(new_name), sprintf("INVALID - %s", basename(new_name)))
  }
  fs::file_move(checklist, new_name)
}

#' @importFrom cli cli_bullets
#' @importFrom cli cli_inform
#' @importFrom cli cli_alert_info
print_checklists <- function(config_path) {
  res <- validate_checklists(config_path = config_path)

  print_check <- as.data.frame(sapply(names(res), function(x) {
    elem <- gsub("INVALID - ", "", basename(x))
    bullet <- "v"
    if (!res[[x]]$valid) {
      elem <- c(elem, res[[x]]$reason)
      bullet <- c("x", " ")
    }
    else if (res[[x]]$valid && !is.na(res[[x]]$reason)) {
      elem <- c(elem, res[[x]]$reason)
      bullet <- c("!", " ")
    }
    list(elem = elem, bullet = bullet)
  }))
  checks <- unlist(print_check["elem", ])
  names(checks) <- unlist(print_check["bullet", ])
  cli::cli_bullets(checks)
  if (any(unlist(res) == FALSE, na.rm = TRUE)) {
    cli::cli_inform(" ")
    cli::cli_alert_info("One or more checklists are not properly formatted. Refer to the documentation")
  }
}
