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
