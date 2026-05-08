#' Print a situation report for ghqc and the current project
#'
#' Collects and displays diagnostic information about the ghqc binary, the
#' currently running ghqc background server (if any), and the git repository
#' for the given directory (owner, repo, branch, and milestones). It also
#' reports authentication state for the repository host. Optionally it reports
#' on the ghqc configuration (checklists, options, etc.).
#'
#' @param directory Path to the project directory. Defaults to the project root
#'   as determined by [here::here()].
#' @param config_dir Path to the ghqc configuration directory. If `NULL`
#'   (default), ghqc uses its default configuration discovery logic.
#' @param with_configuration Logical. If `TRUE`, include a section describing
#'   the ghqc configuration (checklists, options). Defaults to `FALSE`.
#'
#' @return The raw sitrep data list returned by `ghqc sitrep --json`,
#'   invisibly. The primary purpose of this function is its printed output.
#'
#' @examples
#' \dontrun{
#' # Basic sitrep
#' ghqc_sitrep()
#'
#' # Include configuration details
#' ghqc_sitrep(with_configuration = TRUE)
#' }
#'
#' @export
ghqc_sitrep <- function(
  directory = here::here(),
  config_dir = NULL,
  with_configuration = FALSE
) {
  .require_min_version("0.2.0", "ghqc_sitrep()")
  data <- .sitrep(directory, config_dir)
  .print_sitrep(data, with_configuration)
  invisible(data)
}

.sitrep <- function(directory, config_dir) {
  args <- c("sitrep", "--json", "--directory", directory)
  if (!is.null(config_dir)) {
    args <- c(args, "--config_dir", config_dir)
  }
  res <- .run_ghqc(args)

  if (res$status != 0) {
    cli::cli_abort(
      "Failed to run `ghqc sitrep`{}",
      if (res$stderr == "") {
        " with no stderr"
      } else {
        glue::glue(": {res$stderr}")
      }
    )
  }

  res$stdout |> jsonlite::fromJSON()
}

.print_sitrep <- function(data, with_configuration) {
  .print_binary_sitrep(data$binary)
  .print_process_sitrep()
  .print_repo_sitrep(data$repository, data$directory)
  if (!is.null(data$auth)) {
    .print_auth_sitrep(data$auth)
  }
  if (with_configuration) {
    .print_config_sitrep(data$configuration)
  }
}

.print_process_sitrep <- function() {
  cli::cli_h1("Process")
  url <- .ghqc_env$url
  if (is.null(url)) {
    cli::cli_text("Status: Not running")
    return(invisible(NULL))
  }
  proc <- .ghqc_env$proc
  if (!is.null(proc) && proc$is_alive()) {
    cli::cli_text("Status: Running at {url}")
  } else {
    cli::cli_text("Status: Stopped (was running at {url})")
  }
}

.print_binary_sitrep <- function(binary) {
  cli::cli_h1("Binary")
  if (!is.null(binary$path$Ok)) {
    cli::cli_text("Path: {binary$path$Ok}")
  } else {
    cli::cli_text(
      "Path: Failed to determine executable path: {binary$path$Err}"
    )
  }
  cli::cli_text("Version: {binary$version}")
  remote_version <- suppressMessages(ghqc_remote_version())
  if (is.null(remote_version)) {
    cli::cli_alert_warning("Unable to determine remote version")
  } else {
    cli::cli_text("Remote Version: {gsub('v', '', remote_version)}")
  }
}

.print_repo_sitrep <- function(repo, directory) {
  cli::cli_h1("Repository")
  if (!is.null(repo$Ok)) {
    r <- repo$Ok
    cli::cli_text("Directory: {r$path}")
    cli::cli_text("Repository: {r$owner}/{r$repo} ({r$remote_url})")
    # Branch
    if (!is.null(r$branch$Ok)) {
      cli::cli_text("Branch: {r$branch$Ok}")
    } else {
      cli::cli_text("Branch: Failed to determine branch: {r$branch$Err}")
    }
    # Milestones
    cli::cli_h1("Milestones")
    if (!is.null(r$milestones$Ok)) {
      ms <- r$milestones$Ok
      if (NROW(ms) == 0) {
        cli::cli_text("No milestones")
      } else {
        ms_names <- sapply(ms, `[[`, 1)
        ms_is_open <- sapply(ms, function(x) x[[2]]$is_open)
        ms_open <- sapply(ms, function(x) x[[2]]$open)
        ms_closed <- sapply(ms, function(x) x[[2]]$closed)
        ms_labels <- paste0(
          ms_names,
          ": ",
          ms_open,
          " open | ",
          ms_closed,
          " closed"
        )

        open_labels <- ms_labels[ms_is_open]
        closed_labels <- ms_labels[!ms_is_open]

        cli::cli_text("{.strong Open Milestones: {length(open_labels)}}")
        if (length(open_labels) > 0) {
          cli::cli_ul(open_labels)
        }
        cli::cli_inform("")

        cli::cli_text("{.strong Closed Milestones: {length(closed_labels)}}")
        if (length(closed_labels) > 0) cli::cli_ul(closed_labels)
      }
    } else {
      cli::cli_text(
        "Milestones: Failed to determine milestones: {r$milestones$Err}"
      )
    }
  } else {
    cli::cli_text(
      "Failed to determine Git Repository Info for {directory}: {repo$Err}"
    )
  }
}

.print_auth_sitrep <- function(auth) {
  cli::cli_h1("Auth")

  store_dir <- .or_default(auth$store_dir, "unavailable")
  cli::cli_text("Store Directory: {store_dir}")

  stored_tokens <- .or_default(auth$stored_tokens, "unavailable")
  if (
    identical(stored_tokens, "none") || identical(stored_tokens, "unavailable")
  ) {
    cli::cli_text("Stored Tokens: {stored_tokens}")
  } else {
    cli::cli_text("{.strong Stored Tokens:}")
    cli::cli_verbatim(stored_tokens)
  }

  host <- .or_default(auth$host, "not determined")
  cli::cli_text("Repository Host: {host}")

  sources <- .auth_sources_to_list(auth$sources)
  if (length(sources) == 0) {
    cli::cli_text("Available Auth Sources: unknown")
    return(invisible(NULL))
  }

  cli::cli_h2("Available Auth Sources")
  for (source in sources) {
    .print_auth_source(source)
  }
}

.auth_sources_to_list <- function(sources) {
  if (is.null(sources) || length(sources) == 0) {
    return(list())
  }

  if (is.data.frame(sources)) {
    return(lapply(seq_len(nrow(sources)), function(i) {
      as.list(sources[i, , drop = FALSE])
    }))
  }

  if (is.list(sources) && !is.null(sources$kind)) {
    return(list(sources))
  }

  if (is.list(sources)) {
    return(sources)
  }

  list()
}

.format_auth_source <- function(source) {
  kind <- .or_default(source$kind, "unknown")
  preview <- .or_default(source$token_preview, NULL)

  if (.is_missing_value(preview)) {
    kind
  } else {
    sprintf("%s (%s)", kind, preview)
  }
}

.print_auth_source <- function(source) {
  message <- .format_auth_source(source)
  available <- .auth_source_is_available(source)
  status_symbol <- if (available) cli::symbol$tick else cli::symbol$cross
  status_glyph <- if (available) {
    cli::col_green(status_symbol)
  } else {
    cli::col_red(status_symbol)
  }
  prefix <- if (isTRUE(source$is_active)) {
    paste0(cli::symbol$arrow_right, " ")
  } else {
    "  "
  }

  cli::cat_line(prefix, status_glyph, " ", message)
}

.auth_source_is_available <- function(source) {
  !.is_missing_value(source$token_preview)
}

.or_default <- function(x, default) {
  if (.is_missing_value(x)) {
    default
  } else {
    x
  }
}

.is_missing_value <- function(x) {
  is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))
}

.print_config_sitrep <- function(cfg) {
  cli::cli_h1("Configuration")
  # Directory line with optional ❌ indicator
  dir_label <- cfg$configuration$path
  if (!cfg$path_exists) {
    dir_label <- paste0(dir_label, "    \u274c Directory not found")
  }
  cli::cli_text("Directory: {dir_label}")
  # Repository line
  if (!is.null(cfg$owner) && !is.null(cfg$repo)) {
    cli::cli_text("Repository: {cfg$owner}/{cfg$repo} ({cfg$remote_url})")
  } else {
    cli::cli_text("Repository: Not determined to be git repository")
  }
  # Checklists
  checklists <- cfg$configuration$checklists
  cli::cli_text("Checklists: {length(checklists)}")
  if (length(checklists) > 0) {
    # Count items per checklist (lines starting with "- [")
    item_counts <- vapply(
      checklists,
      function(cl) {
        sum(grepl("^- \\[", strsplit(cl$content, "\n")[[1]]))
      },
      integer(1)
    )
    cli::cli_ul(paste0(names(checklists), ": ", item_counts, " items"))
  }
  # Options
  opts <- cfg$configuration$options
  cli::cli_inform("")
  cli::cli_text("{.strong Options:}")
  if (!is.null(opts$prepended_checklist_note)) {
    cli::cli_ul("Prepended Checklist Note:")
    cli::cli_blockquote(opts$prepended_checklist_note)
  }
  cli::cli_ul("Checklist Display Name:  '{opts$checklist_display_name}'")
  cli::cli_ul("Logo Path: '{opts$logo_path}'")
  cli::cli_ul("Checklist Directory: '{opts$checklist_directory}'")
  cli::cli_ul("Record Template Path: '{opts$record_path}'")
}
