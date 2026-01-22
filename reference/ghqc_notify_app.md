# Comment in an Issue to display file changes during QC

This function allows a user to insert a comment into a ghqc GitHub Issue
that displays changes in the version control information for the Issue’s
corresponding file. By default, the comment displays both the original
and current commits and hashes for the file. These versions are selected
by the user. The comment can optionally display the file difference
(“diff”) between the current and previous versions. These changes will
likely be implementations of QC feedback.

To use this app, first initialize one or more Issues with
[ghqc_assign_app](https://a2-ai.github.io/ghqc/reference/ghqc_assign_app.md).

**To comment in an Issue:**

1.  Optional: filter to the set of Issues within a Milestone.

2.  Select the Issue to be updated.

3.  Optional: provide a contextualizing message about the changes made
    to the file (e.g. “Implemented QC feedback for line 20”).

4.  Optional: insert the file difference display into the comment, by
    selecting “Show file difference”. If displaying the file difference,
    choose to either:

    - compare the original version with the current version or,

    - compare a previous version with the current version.

5.  Optional: preview the comment before posting to the Issue.

6.  Post the comment to the Issue.

## Usage

``` r
ghqc_notify_app(
  app_name = "ghqc_notify_app",
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
[ghqc_record_app](https://a2-ai.github.io/ghqc/reference/ghqc_record_app.md)
