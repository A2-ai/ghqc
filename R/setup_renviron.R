#' helper function to setup/write Renviron file for ghqc
#'
#' @param GHQC_INFO_REPO Repository URL to the customizing information repository
#'
#' @return This function is used primarly to write to the ~/.Renviron file. It will return the text contained in ~/.Renviron
#' @export
setup_ghqc_renviron <- function(GHQC_INFO_REPO) {
  renv_text <- renviron_text()

  renv_text <- renviron_edit("GHQC_INFO_REPO", GHQC_INFO_REPO, renv_text)
  writeLines(renv_text, "~/.Renviron")
  invisible(renv_text)
}

#' @importFrom fs file_exists
#' @importFrom fs file_create
renviron_text <- function() {
  if (!fs::file_exists("~/.Renviron")) fs::file_create("~/.Renviron")
  readLines("~/.Renviron")
}

#' @importFrom cli cli_alert_success
#' @importFrom cli cli_alert_danger
#' @importFrom cli cli_alert_info
renviron_edit <- function(var_name, input_val, renv_text) {
  if (length(renv_text) == 0 || any(!nzchar(renv_text))) {
    cli::cli_alert_success("{var_name} was successfully updated to {input_val} in ~/.Renviron")
    return(invisible(var_write(var_name, input_val)))
  }
  renv_val <- parse_renviron(var_name, renv_text)
  if (renv_val$val == "") {
    tryCatch({
      renv_text <- c(renv_text, var_write(var_name, input_val))
      cli::cli_alert_success("{var_name} was successfully updated to {input_val} in ~/.Renviron")
    }, error = function(e) {
      cli::cli_alert_danger("{var_name} was not set due to: {e$message}")
    })
    return(invisible(renv_text))
  }

  if (renv_val$val != input_val) {
    tryCatch({
      renv_text <- overwrite_var(var_name, input_val, renv_text, renv_val$index)
      cli::cli_alert_success("{var_name} was successfully updated to {input_val} in ~/.Renviron")
    }, error = function(e) {
      cli::cli_alert_danger("{var_name} was not set due to: {e$message}")
    })
    return(invisible(renv_text))
  }

  cli::cli_alert_info("{var_name} found in ~/.Renviron matches input. No changes")
  invisible(renv_text)
}

#' @importFrom cli cli_inform
not_set_msg <- function(var_name) {
    cli::cli_inform(c("x" = "{var_name} is not set in ~/.Renviron and no input provided",
                      " " = "ghqc will not work as expected",
                      " " = "Please set before running any ghqc app"))
}

parse_renviron <- function(var_name, renv_text) {
  index <- which(grepl(paste0("^", var_name), renv_text))
  if (length(index) == 0) {
    return(list(index = NA, val = ""))
  }
  if (length(index) != 1) {
    cli::cli_abort("{var_name} found multiple times in ~/.Renvirion at index {paste0(index, collapse = ',')}. Please ensure only one occurance of the variable occurs in your ~/.Renviron")
  }
  else {
    val <- renviron_extract(renv_text[index], var_name)
  }
  list(index = index, val = val)
}

renviron_extract <- function(var_str, var_name) {
  regmatches(var_str, regexec(paste0(var_name, '=\\\"(.*?)\\\"'), var_str))[[1]][2]
}

var_write <- function(name, val) {
  c(paste0("#added by ghqc on ", Sys.Date()),
    paste0(name,'="', val, '"'))
}

overwrite_var <- function(var_name, input_val, renv_text, renv_index) {
  if (is.null(input_val)) return(renv_text)
  if (length(renv_text) == 1) return(var_write(var_name, input_val))
  if (grepl("added by ghqc", renv_text[renv_index-1])) {
    renv_text <- renv_text[-(renv_index-1)]
    renv_index <- renv_index - 1
  }
  if (renv_index == 1) {
    if (length(renv_text) == 1) return(var_write(var_name, input_val))
    return(c(var_write(var_name, input_val), renv_text[(renv_index+1):length(renv_text)]))
  }
  if (renv_index == length(renv_text)) return(c(renv_text[1:(renv_index-1)], var_write(var_name, input_val)))
  c(renv_text[1:(renv_index-1)], var_write(var_name, input_val), renv_text[(renv_index+1):length(renv_text)])
}
