# ghqc 0.6.1

- renames `setup_ghqc()` to `ghqc_setup()` to maintain function naming consistency
- modifies `ghqc_setup()` to install ghqc.app if it is an available package according to a user's `option("repos")` if the user chooses to INSTALL ghqc.app package dependencies

# ghqc 0.6.0

- exports new ghqc_example_setup() function, which provides an out-of-the-box installation architecture and configuration to begin using the ghqc ecosystem
- modifies `install_ghqcapp_dependencies()` to install ghqc.app if it is an available package according to a user's `option("repos")`

# ghqc 0.5.0

- includes .txt checklist files in custom configuration repository validation

# ghqc 0.4.2

- adds other necessary packages to ghqc_depends (ellipsis, colorspace)

# ghqc 0.4.1

- adds necessary packages to ghqc_depends

# ghqc 0.4.0

- modifies package dependencies and wrapper functions to export the new functions in ghqc.app

# ghqc 0.3.9

- increases timeout for shiny sessions that take a long time to start

# ghqc 0.3.8

- adds error handling for whether the minimum version of pak is installed in `setup_ghqc()`, `check_ghqcapp_dependencies()` and `install_ghqcapp_dependencies()`

# ghqc 0.3.7

- fixes html in `ghqc_libpath()` documentation

# ghqc 0.3.6

- fixes typo in parse_renviron

# ghqc 0.3.5

- fixes typo in local custom configuration repository update prompt
- rephrases warning for required setup before running ghqc ecosystem apps

# ghqc 0.3.4

- adds warning to checklist validation if checklist yamls lack a trailing newline

# ghqc 0.3.3

- refactors `setup_ghqc()` such that each interactive input is (y/N)
- updates explicit dependencies of `ghqc.app` in sysdata.rda
- updates pak version to 0.8.0

# ghqc 0.3.2

- fixes typos and returns error message of error handling in `install_ghqcapp_dependencies`

# ghqc 0.3.1

- fixes bug from 0.2.1 in which jobGetState was imported from rstudioapi but was unavailable in versions < 0.16.0 and caught by renv

# ghqc 0.3.0

- refactors ghqc.app dependency installation based on R version and operating system
- removes extraneous ghqc.app dependencies, minimizing number of required dependency packages from 148 to 92

# ghqc 0.2.2

- fixes error handling bug in install_dev_ghqcapp (non-exported function)
- adds branch input to install_dev_ghqcapp (non-exported function)

# ghqc 0.2.1

- increases counter for starting up shiny apps
- adds waiter to console while app is starting up

# ghqc 0.2.0

- Updated the custom configuration options repository (now `GHQC_OPTIONS_REPO`) check to reflect the following changes:
  - The "note" file within the custom configuration repository is now `prepended_checklist_note` within "options.yaml"
  - `checklist_display_name_var` in "options.yaml" provides option to change the name in which the QC checklists are referred to as.

# ghqc 0.1.8

- The logic for rejecting `gert` install as part of `setup_ghqc` was incorrect. Updating to allow for rejection

# ghqc 0.1.7

- typo found in `setup_ghqc` related to the info repo global variable. No performance change

# ghqc 0.1.6

- remove version limits for dependencies. Tested version limits down to snapshot date of 2022-08-31
- when using the `use_pak = FALSE` flag in `install_ghqcapp_dependencies`, forcing `utils::install.packages` to remove potential renv issues

# ghqc 0.1.5

- language change in `remove_ghqc_configuration` from "customizing information" to "custom configuration"

# ghqc 0.1.4

- Changes `install_dev_ghqc` to `install_dev_ghqcapp`
- Changes default remote in `install_dev_ghqcapp` to a2-ai/ghqc.app
- Changes language in `install_ghqcapp_dependencies` to be clearer (the function does not install ghqc or ghqc.app)

# ghqc 0.1.3

- Fixes typos in output messages for `remove_ghqc_configuration` and `repo_clone`


# ghqc 0.1.2

-   Converting the download of the configuration information repository in ghqc_setup to checking if you'd like to download instead of automatically downloading.

# ghqc 0.1.1

## Changes

-   Bug fixes related to empty checklist folders and parsing GHQC_INFO_REPO out of the ~/.Renviron
