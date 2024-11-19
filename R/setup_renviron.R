#' helper function to setup/write Renviron file for ghqc
#'
#' @param GHQC_CONFIG_REPO Repository URL to the customizing information repository
#'
#' @return This function is used primarly to write to the ~/.Renviron file. It will return the text contained in ~/.Renviron
#' @export
setup_ghqc_renviron <- function(GHQC_CONFIG_REPO) {
  renv_text <- renviron_text()

  renv_text <- renviron_edit("GHQC_CONFIG_REPO", GHQC_CONFIG_REPO, renv_text)
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
  if (length(renv_text) == 0) {
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
  x <- gsub(" ", "",
            gsub('"', "", renv_text))
  # based on Sys.getenv
  m <- regexpr("=", x, fixed = TRUE)
  n <- substring(x, 1L, m - 1L)
  v <- substring(x, m + 1L)
  if (!(var_name %in% n)) return(list(index = NA, val = ""))
  if (anyDuplicated(n[n == var_name]) != 0) cli::cli_abort("{var_name} found multiple times in ~/.Renvirion. Please ensure only one occurance of the variable occurs in your ~/.Renviron")
  index <- which(var_name == n)
  list(index = index, val = v[index])
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
