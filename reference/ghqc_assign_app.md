# Assign file(s) to be reviewed for QC

This function provides an interface to assign one or more files for QC
in the form of a GitHub Issue(s) within a GitHub Milestone, with options
to assign a repository collaborator as the QCer and/or generate a
checklist of suggested review tasks during QC.

Each Issue created corresponds to a single file assigned to be reviewed
for QC. Issues are organized into Milestones as designated by the user.

**To assign file(s) for QC:**

1.  Input a name to create a new Milestone or select an existing
    Milestone.

2.  Optional: if creating a new Milestone, input a description.

3.  Optional: select one or more collaborators who will be assigned to
    perform the QC. The selected collaborator(s) will not be assignee(s)
    until explicitly assigned to one or more selected files (Step 5
    below).

4.  Select one or more files from the file tree. Click the + signs to
    expand directories in the file tree.

5.  Optional: select an assignee for each selected file.

6.  Select a checklist type for each selected file.

7.  Post the Milestone by clicking "Assign File(s) for QC" on the bottom
    of the pane.

At any time, the user can:

- Click the `Preview file contents` button below a selected file to view
  its contents.

- Click the `Preview checklist` button below a selected file to view the
  items in a its selected checklist.

## Usage

``` r
ghqc_assign_app(
  app_name = "ghqc_assign_app",
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

[ghqc_status_app](https://a2-ai.github.io/ghqc/reference/ghqc_status_app.md)
and
[ghqc_record_app](https://a2-ai.github.io/ghqc/reference/ghqc_record_app.md)
