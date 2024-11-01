% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/info_repo.R
\name{check_ghqc_configuration}
\alias{check_ghqc_configuration}
\title{Check the content of the downloaded ghqc configuration information repository and download any updates needed}
\usage{
check_ghqc_configuration(info_path = ghqc_infopath())
}
\arguments{
\item{info_path}{\emph{(optional)} path in which the repository, set in environmental variable \code{GHQC_INFO_REPO}, is, or should be, downloaded to. Defaults to \verb{~/.local/share/ghqc/\{repo_name\}}}
}
\description{
Check the content of the downloaded ghqc configuration information repository and download any updates needed
}
