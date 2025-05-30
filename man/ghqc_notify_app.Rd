% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wrappers.R
\name{ghqc_notify_app}
\alias{ghqc_notify_app}
\title{Comment in an Issue to display file changes during QC}
\usage{
ghqc_notify_app(
  app_name = "ghqc_notify_app",
  qc_dir = getwd(),
  lib_path = ghqc_libpath(),
  config_path = ghqc_config_path()
)
}
\arguments{
\item{app_name}{the name of the app to run in the background}

\item{qc_dir}{the directory in which the app is run}

\item{lib_path}{the path to the ghqc package and its dependencies}

\item{config_path}{the path to the ghqc configuring information}
}
\description{
This function allows a user to insert a comment into a ghqc GitHub Issue that displays changes
in the version control information for the Issue’s corresponding file. By default, the comment
displays both the original and current commits and hashes for the file. These versions are
selected by the user. The comment can optionally display the file difference (“diff”) between
the current and previous versions. These changes will likely be implementations of QC feedback.

To use this app, first initialize one or more Issues with \link{ghqc_assign_app}.

\strong{To comment in an Issue:}
\enumerate{
\item Optional: filter to the set of Issues within a Milestone.
\item Select the Issue to be updated.
\item Optional: provide a contextualizing message about the changes made to the file (e.g. “Implemented QC feedback for line 20”).
\item Optional: insert the file difference display into the comment, by selecting “Show file difference”.
If displaying the file difference, choose to either:
\itemize{
\item compare the original version with the current version or,
\item compare a previous version with the current version.
}
\item Optional: preview the comment before posting to the Issue.
\item Post the comment to the Issue.
}
}
\seealso{
\link{ghqc_assign_app} and \link{ghqc_record_app}
}
