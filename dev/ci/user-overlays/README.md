# Add overlays for your pull requests in this directory

_Overlays_ let you test pull requests that break the base version of
external projects by applying PRs of the external project during CI
testing (1 PR per broken external project).  Once Rocq CI's tests of the
external projects pass, the Rocq PR can be merged, then the assignee must
ask the external projects to merge their PRs (for example by commenting
in the external PRs).  External projects are then expected to merge their
PRs promptly.

## Typical workflow

Overlay files can be created automatically using the script
[`create_overlays.sh`](../../tools/create_overlays.sh).

- Observe that your changes breaks some external projects `<project1>` ... `<projectn>` in CI
  (`<projecti>` is the name of a project, without the `ci-` prefix.
  Note that some jobs run multiple projects, e.g. `plugin:ci-elpi_hb` runs `elpi` and `hb`)
- If necessary, fork the broken projects from their github pages.
  (Only needs to be done once per project for the lifetime of your github account)
  (Ask for help for projects not on github)
- Compile your PR locally (`make world`).
- Run `dev/tools/create_overlays.sh <account> <PR> <project1> ... <projectn>`
  where `<account>` is your github account name and `PR` is the PR number.
  This will download the given projects to `_build_ci` (and their dependencies),
  declare your fork (using the account name) as a remote
  and checkout a new branch for your fixes.
- For each broken project:
  - run `make ci-<project>`, e.g. `make ci-elpi`.
    This should produce the error observed in CI.
  - Make necessary changes, then rerun the script to verify they work.
  - From the `_build_ci/<project>` subdirectory, commit your changes to the current
    branch (it was created by create_overlays).
  - Push to your fork of the project and create a new PR.  Make sure you pick
    the correct base branch in the github GUI for the comparison
    (c.f. `dev/ci/ci-basic-overlay.sh`, e.g. `master` for elpi).
    If the fix is backwards compatible (preferred for library changes), open the PR as ready
    and ask for it to be merged (eg "Should be backwards compatible, please merge.").
    Otherwise (typical for plugin changes, including plugins with optional compilation to support multiple Rocq versions) the PR needs to be merged in sync with the Rocq PR, so open as draft.
  - link the overlay PR in the Rocq PR (at the end of the opening post add a list
    ~~~
    Overlays:
    - <PR1>
    - <PR2>
    ~~~
    )
- Commit the overlay file (`git add dev/ci/user-overlays && git commit`),
  push to the Rocq PR and run full CI
  (wait for the assignee to run full CI if you don't have the rights)
- When your PR is merged, the assignee notifies the maintainers of the
  external project to merge the changes you submitted.  This should happen
  promptly; the external project's CI will fail until the change is merged.
- Beer.

Notes:
- running `create_overlays` multiple times is fine
- running `make ci-foo` before `create_overlays` it's also fine

So for instance you can have an alternate workflow of

- run `make ci-project1`
- fix
- `dev/tools/create_overlays.sh <account> <PR> <project1>`
- commit, push and PR for project 1
- run `make ci-project2`
- fix
- `dev/tools/create_overlays.sh <account> <PR> <project1> <project2>`
- commit push and PR for project 2
- repeat until project `n` is done
- commit and push overlay file

## Overlay file specification

An overlay file specifies the external PRs that should be applied during CI.
A single file can cover multiple external projects.  Create your
overlay file in the `dev/ci/user-overlays` directory.
The name of the overlay file should start with a five-digit pull request
number, followed by a dash, anything (by convention, your GitHub nickname
and the branch name), then an `.sh` extension (`[0-9]{5}-[a-zA-Z0-9-_]+.sh`).

The file must contain a call to the `overlay` function for each
affected external project:
```
overlay <project> <giturl> <ref> <prnumber> [<prbranch>]
```
Each call creates an overlay for `project` using a given `giturl` and
`ref` which is active for `prnumber` or `prbranch` (`prbranch` defaults
to `ref`).

For example, an overlay for the project `elpi` that uses the branch `noinstance`
from the fork of `SkySkimmer` and is active for pull request `13128`:
```
overlay elpi https://github.com/SkySkimmer/coq-elpi noinstance 13128
```

The github URL and base branch name for each external project are listed in
[`ci-basic-overlay.sh`](../ci-basic-overlay.sh).  For example, the entry for
`elpi` is
```
project elpi "https://github.com/LPCIC/coq-elpi" "master"
```
But substitute the name of your fork into the URL, e.g. `SkySkimmer/coq-elpi`
rather than `LPCIC/coq-elpi`.  Use `#` to mark any comments.

If the branch name in the external project differs from the Rocq branch name,
include the external branch name as `[prbranch]` to apply it when you run
the test suite locally, e.g. `make ci-elpi`.

## Branching conventions

We suggest you use the convention of identical branch names for the
Rocq branch and the CI project branch used in the overlay. For example,
if your Rocq PR is in your branch `more_efficient_tc` and
breaks `ltac2`, we suggest you create an `ltac2` overlay with a branch
named `more_efficient_tc`.
