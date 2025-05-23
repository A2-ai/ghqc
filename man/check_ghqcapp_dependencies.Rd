% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check_packages.R
\name{check_ghqcapp_dependencies}
\alias{check_ghqcapp_dependencies}
\title{Check the installed/linked packages in \code{lib_path} against the recommended ghqc.app dependency package version}
\usage{
check_ghqcapp_dependencies(lib_path = ghqc_libpath(), use_pak = TRUE)
}
\arguments{
\item{lib_path}{\emph{(optional)} the path to the installed/linked dependencies. If not set, defaults to ghqc_libpath()}

\item{use_pak}{\emph{(optional)} optionally removes the requirement to have \code{pak} installed in the project repository. Setting to \code{FALSE} will reduce performance}
}
\value{
This function is primarily used for its printed results and subsequent actions, not a returned output.
Will return a dataframe of package upgrades needed
}
\description{
Check the installed/linked packages in \code{lib_path} against the recommended ghqc.app dependency package version
}
