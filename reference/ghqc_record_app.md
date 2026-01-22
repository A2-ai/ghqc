# Generate a QC Record for one or more Milestones

This function allows the user to generate a QC Record for one or more
Milestones created with
[ghqc_assign_app](https://a2-ai.github.io/ghqc/reference/ghqc_assign_app.md).

**To Generate a QC Record:**

1.  Select one or more Milestones.

    - optional to include both open and closed Milestones by unchecking
      "Closed Milestones only".

2.  Optional: input a name for the PDF.

    - The default name is a hyphenated combination of the GitHub
      repository name and selected Milestone name(s).

3.  Optional: input the directory in which to generate the PDF.

    - The default directory is the root of the R project.

4.  Optional: indicate if the report should only include the Milestone
    and Issue summary tables by checking "Just tables". Else, the
    default setting will generate a Record that contains the summary
    tables up front as well as detailed descriptions for each Issue
    including version control information, users, datetimes, events,
    actions, comments and more.

5.  Create the PDF by clicking "Generate QC Record" at the bottom of the
    pane.

## Usage

``` r
ghqc_record_app(
  app_name = "ghqc_record_app",
  qc_dir = getwd(),
  lib_path = ghqc_libpath(),
  config_path = ghqc_config_path()
)
```

## Arguments

- app_name:

  the name of the app to run in the background

- qc_dir:

  the directory in which the app is run

- lib_path:

  the path to the ghqc package and its dependencies

- config_path:

  the path to the ghqc configuring information

## See also

[ghqc_assign_app](https://a2-ai.github.io/ghqc/reference/ghqc_assign_app.md)
and
[ghqc_status_app](https://a2-ai.github.io/ghqc/reference/ghqc_status_app.md)
