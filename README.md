# Creating a Stata project with automated Docker builds

[![Build docker image](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml)[![Compute analysis](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml)

## Purpose

This is a demonstration of using Stata, using Docker to robustly encapsulate the Stata environment, and using Github Actions to automatically run everything - the Docker build as well as the actual analysis.

You can also use a Github Action, for instance [labordynamicsinstitute/continuous-integration-stata](https://github.com/labordynamicsinstitute/continuous-integration-stata) or [ledwindra/continuous-integration-stata](https://github.com/ledwindra/continuous-integration-stata), they are different ways of achieving the same thing: continuously checking that your Stata-based analysis works.

## Requirements

You need a Stata license to run the image, and the license needs to be available to the Github Action as `STATA_LIC_BASE64` in "base64" format. From a Linux/macOS command line, you could generate it like this:

```bash
gh secret set STATA_LIC_BASE64 -b"$(cat stata.lic | base64)" -v all -o YOURORG
```

where `stata.lic` is your Stata license file, and `YOURORG` is your organization (can be dropped if running in your personal account).


## Dockerfile

The [Dockerfile](Dockerfile) contains the build instructions. A few things of note:

- The container will be based on a pre-configured Stata Docker image maintained at [Data Editors' Docker Hub](https://hub.docker.com/u/dataeditors). If you have your own favorite image, please feel free to adapt to use it.
- The build process will integrate all ado-file installs, using the `setup.do` file. You should NOT call `setup.do` during regular processing, all ado files should already be installed (and therefore version-locked).
- Because of this, you already **need the Stata license** during the build process. There's a convoluted part of the Dockerfile where the Stata license is pulled in, used, and then deleted: this is to ensure that you do not accidentally post your Stata license!

## Build

You can build the file yourself locally, see `build.sh`. You will need a valid Stata license file. 

You can also enable the Github Action, and use the cloud to build. 
This is configured in the [`.github/workflows/build.yml`](.github/workflows/build.yml) file.
For illustration purposes, the Docker image built through this mechanism can be found at [https://hub.docker.com/r/aeadataeditor/stata-project-with-docker](https://hub.docker.com/r/aeadataeditor/stata-project-with-docker).

In order to use the Github Action, you need to have configured a "Github Action secret" called "STATA_LIC_BASE64" which contains a Base64-encoded version of your Stata license. Again, this is to prevent posting your Stata license publicly. 

You can create this key on a Linux/macOS system by

```
gh secret set STATA_LIC_BASE64 -b$(cat ./stata.lic| base64) -v all
```

where `gh` is the Github command line utility. You will also need your Docker Hub login and token, in order to post the image, again using Github Actions secrets.

```
gh secret set DOCKERHUB_TOKEN -b"TOKEN VALUE" -v all
gh secret set DOCKERHUB_USERNAME -b"YOUR USER NAME" -v all
```

You only need to do this once for all of your repositories (if using the `-v all` scope flag). You can also manually encode the license variable using the Github Action secret configuration menu on github.com.

Note that we have configured the build to be triggered by either of two actions:

- Any change to the `Dockerfile`, and only the `Dockerfile`
- Manually, by going to the Actions menu of the Github repo.

Other triggers are possible.

## Using the image

The build should occur relatively seldomly. It is made available to the cloud-based Github Actions (and anybody else) by posting it to Docker Hub. We then configure Github Actions to pull it down.

Using a pre-built image on [Docker Hub](https://hub.docker.com/u/dataeditors) to run a program is encoded within the `run.sh` program. It takes one argument, the path to the license file (e.g., `stata.lic`).

`run.sh` can be run locally. To run it remotely, we again use Github Actions. This is configured in the [`.github/workflows/compute.yml`](.github/workflows/compute.yml) file. We re-use the same base64-encoded license file as before. 

- `run.sh` only runs the `main.do` file. All other Stata code needs to be called from there. 
- Note that the working directory within the Docker image changes to `/code`. 
- Note that we have configured the build to be triggered by either of two actions:
  - Any change to the `main` branch
  - Manually, by going to the Actions menu of the Github repo.

For instance, this means that you could experiment with changes to a branch `testing123` without triggering a build each time.

## Outputs

The outputs from the automated runs are posted to the [`results`](https://github.com/AEADataEditor/stata-project-with-docker/tree/results) branch. That is primarily for illustration. You could push changes back to the main repository, or to a `gh-pages` as part of a web page illustrating the results of your analysis, or something else. One advantage of posting to a different branch is that your main branch remains in sync with your Github Desktop client more easily.

One note: Stata does not properly provide exit codes, and thus *any* run of `main.do`, as it is configured here. In fact, it should indicate a failure. This is for future work, noted here in [Issue 1](https://github.com/AEADataEditor/stata-project-with-docker/issues/1), where a solution is sketched out.
