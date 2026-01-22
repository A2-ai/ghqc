# Package index

## All functions

- [`check_ghqc_configuration()`](https://a2-ai.github.io/ghqc/reference/check_ghqc_configuration.md)
  : Check the content of the downloaded ghqc custom configuration
  repository and download any updates needed

- [`check_ghqcapp_dependencies()`](https://a2-ai.github.io/ghqc/reference/check_ghqcapp_dependencies.md)
  :

  Check the installed/linked packages in `lib_path` against the
  recommended ghqc.app dependency package version

- [`download_ghqc_configuration()`](https://a2-ai.github.io/ghqc/reference/download_ghqc_configuration.md)
  :

  Download the custom configuration repository as set in environmental
  variable `GHQC_CONFIG_REPO`

- [`format_linux_platform()`](https://a2-ai.github.io/ghqc/reference/format_linux_platform.md)
  : Find and format the linux platform string for ghqc/rpkg installation

- [`ghqc_archive_app()`](https://a2-ai.github.io/ghqc/reference/ghqc_archive_app.md)
  : Archive file(s)

- [`ghqc_assign_app()`](https://a2-ai.github.io/ghqc/reference/ghqc_assign_app.md)
  : Assign file(s) to be reviewed for QC

- [`ghqc_config_path()`](https://a2-ai.github.io/ghqc/reference/ghqc_config_path.md)
  : The default install location for the ghqc custom configuration
  repository

- [`ghqc_example_setup()`](https://a2-ai.github.io/ghqc/reference/ghqc_example_setup.md)
  : Function to set up the ghqc environment, including writing to the
  .Renviron, custom configuration repository download, ghqc.app
  dependency installation, and ghqc.app installation if available, for
  use of the ghqc application suite

- [`ghqc_libpath()`](https://a2-ai.github.io/ghqc/reference/ghqc_libpath.md)
  : The default install location for the ghqc package and its
  dependencies. If it does not exist, it will be created.

- [`ghqc_notify_app()`](https://a2-ai.github.io/ghqc/reference/ghqc_notify_app.md)
  : Comment in an Issue to display file changes during QC

- [`ghqc_record_app()`](https://a2-ai.github.io/ghqc/reference/ghqc_record_app.md)
  : Generate a QC Record for one or more Milestones

- [`ghqc_setup()`](https://a2-ai.github.io/ghqc/reference/ghqc_setup.md)
  : Interactive function to set up the ghqc environment, including
  writing to the .Renviron, custom configuration repository download,
  and ghqc.app dependency installation/linking, for use of the ghqc
  application suite

- [`ghqc_sitrep()`](https://a2-ai.github.io/ghqc/reference/ghqc_sitrep.md)
  : Situation report for ghqc set-up

- [`ghqc_status_app()`](https://a2-ai.github.io/ghqc/reference/ghqc_status_app.md)
  : Status QC file(s)

- [`install_ghqcapp_dependencies()`](https://a2-ai.github.io/ghqc/reference/install_ghqcapp_dependencies.md)
  : install ghqc.app's dependencies into an isolated library

- [`is_shiny_ready()`](https://a2-ai.github.io/ghqc/reference/is_shiny_ready.md)
  : Shiny is "ready" if the download.file is able to serve the starting
  html, at this point, we will try to hit the shiny app and see if it
  downloads

- [`link_ghqcapp_dependencies()`](https://a2-ai.github.io/ghqc/reference/link_ghqcapp_dependencies.md)
  : symlink previously installed package library containing all ghqc.app
  dependencies to an isolated package library

- [`remove_ghqc_configuration()`](https://a2-ai.github.io/ghqc/reference/remove_ghqc_configuration.md)
  :

  Remove the downloaded custom configuration repository from
  `config_path`

- [`remove_ghqcapp_dependencies()`](https://a2-ai.github.io/ghqc/reference/remove_ghqcapp_dependencies.md)
  : Remove all content in the specified lib path. Optionally removes the
  cache as well.

- [`setup_ghqc()`](https://a2-ai.github.io/ghqc/reference/setup_ghqc.md)
  : setup_ghqc

- [`setup_ghqc_renviron()`](https://a2-ai.github.io/ghqc/reference/setup_ghqc_renviron.md)
  : helper function to setup/write Renviron file for ghqc
