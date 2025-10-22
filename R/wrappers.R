#' @title Assign file(s) to be reviewed for QC
#' @description
#' This function provides an interface to assign one or more files for QC in the form of a GitHub Issue(s) within a
#' GitHub Milestone, with options to assign a repository collaborator as the QCer and/or generate a checklist
#' of suggested review tasks during QC.
#'
#' Each Issue created corresponds to a single file assigned to be reviewed for QC.
#' Issues are organized into Milestones as designated by the user.
#'
#' **To assign file(s) for QC:**
#' 1) Input a name to create a new Milestone or select an existing Milestone.
#' 2) Optional: if creating a new Milestone, input a description.
#' 3) Optional: select one or more collaborators who will be assigned to perform the QC. The selected collaborator(s) will not be
#' assignee(s) until explicitly assigned to one or more selected files (Step 5 below).
#' 4) Select one or more files from the file tree. Click the + signs to expand directories in the file tree.
#' 5) Optional: select an assignee for each selected file.
#' 6) Select a checklist type for each selected file.
#' 7) Post the Milestone by clicking "Assign File(s) for QC" on the bottom of the pane.
#'
#' At any time, the user can:
#' - Click the `Preview file contents` button below a selected file to view its contents.
#' - Click the `Preview checklist` button below a selected file to view the items in a its selected checklist.
#'
#' @param app_name the name of the app to run in the background
#' @param qc_dir the directory in which the app is run
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc configuring information
#'
#' @seealso \link{ghqc_status_app} and \link{ghqc_record_app}
#'
#' @export
ghqc_assign_app <- function(app_name = "ghqc_assign_app",
                                qc_dir = getwd(),
                                lib_path = ghqc_libpath(),
                                config_path = ghqc_config_path()) {
  run_app(app_name = app_name,
          qc_dir = qc_dir,
          lib_path = lib_path,
          config_path = config_path)
}



#' @title Comment in an Issue to display file changes during QC
#' @description
#' This function allows a user to insert a comment into a ghqc GitHub Issue that displays changes
#' in the version control information for the Issue’s corresponding file. By default, the comment
#' displays both the original and current commits and hashes for the file. These versions are
#' selected by the user. The comment can optionally display the file difference (“diff”) between
#' the current and previous versions. These changes will likely be implementations of QC feedback.
#'
#' To use this app, first initialize one or more Issues with \link{ghqc_assign_app}.
#'
#' **To comment in an Issue:**
#' 1) Optional: filter to the set of Issues within a Milestone.
#' 2) Select the Issue to be updated.
#' 3) Optional: provide a contextualizing message about the changes made to the file (e.g. “Implemented QC feedback for line 20”).
#' 4) Optional: insert the file difference display into the comment, by selecting “Show file difference”.
#'  If displaying the file difference, choose to either:
#'      - compare the original version with the current version or,
#'      - compare a previous version with the current version.
#' 5) Optional: preview the comment before posting to the Issue.
#' 6) Post the comment to the Issue.
#'
#'
#' @param app_name the name of the app to run in the background
#' @param qc_dir the directory in which the app is run
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc configuring information
#'
#' @seealso \link{ghqc_assign_app} and \link{ghqc_record_app}
#'
#' @export
ghqc_notify_app <- function(app_name = "ghqc_notify_app",
                         qc_dir = getwd(),
                         lib_path = ghqc_libpath(),
                         config_path = ghqc_config_path()) {
  run_app(app_name = app_name,
          qc_dir = qc_dir,
          lib_path = lib_path,
          config_path = config_path)
}

#' @title Generate a QC Record for one or more Milestones
#' @description
#' This function allows the user to generate a QC Record for one or more Milestones created with \link{ghqc_assign_app}.
#'
#' **To Generate a QC Record:**
#'
#' 1) Select one or more Milestones.
#'
#'     - optional to include both open and closed Milestones by unchecking "Closed Milestones only".
#'
#' 2) Optional: input a name for the PDF.
#'
#'     - The default name is a hyphenated combination of the GitHub repository name and selected Milestone name(s).
#'
#' 3) Optional: input the directory in which to generate the PDF.
#'
#'     - The default directory is the root of the R project.
#'
#' 4) Optional: indicate if the report should only include the Milestone and Issue summary tables by checking "Just tables".
#' Else, the default setting will generate a Record that contains the summary tables up front as well as detailed descriptions
#' for each Issue including version control information, users, datetimes, events, actions, comments and more.
#'
#' 5) Create the PDF by clicking "Generate QC Record" at the bottom of the pane.
#'
#'
#' @param app_name the name of the app to run in the background
#' @param qc_dir the directory in which the app is run
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc configuring information
#'
#' @seealso \link{ghqc_assign_app} and \link{ghqc_status_app}
#'
#' @export
ghqc_record_app <- function(app_name = "ghqc_record_app",
                                qc_dir = getwd(),
                                lib_path = ghqc_libpath(),
                        config_path = ghqc_config_path()) {
  run_app(app_name = app_name,
          qc_dir = qc_dir,
          lib_path = lib_path,
          config_path = config_path)
}

#' @title Status QC file(s)
#'
#' @param app_name the name of the app to run in the background
#' @param qc_dir the directory in which the app is run
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc configuring information
#'
#' @seealso \link{ghqc_assign_app} and \link{ghqc_record_app}
#'
#' @export
ghqc_status_app <- function(app_name = "ghqc_status_app",
                            qc_dir = getwd(),
                            lib_path = ghqc_libpath(),
                            config_path = ghqc_config_path()) {
  run_app(app_name = app_name,
          qc_dir = qc_dir,
          lib_path = lib_path,
          config_path = config_path)
}


#' @title Archive QC file(s)
#'
#' @param app_name the name of the app to run in the background
#' @param qc_dir the directory in which the app is run
#' @param lib_path the path to the ghqc package and its dependencies
#' @param config_path the path to the ghqc configuring information
#'
#' @seealso \link{ghqc_assign_app} and \link{ghqc_record_app}
#'
#' @export
ghqc_archive_app <- function(app_name = "ghqc_archive_app",
                            qc_dir = getwd(),
                            lib_path = ghqc_libpath(),
                            config_path = ghqc_config_path()) {
  run_app(app_name = app_name,
          qc_dir = qc_dir,
          lib_path = lib_path,
          config_path = config_path)
}

