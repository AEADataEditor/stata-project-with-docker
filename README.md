# Creating a Stata project with automated Docker builds

[![Build docker image](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml)[![Compute analysis](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml)

## Purpose

This repository serves as a demonstration and a template on how to use Docker together with Stata to 

a) encapsulate a project's computing for reliability and reproducibility and 
b) (optionally) leverage cloud resources to test that functionality every time a piece of code changes.

These short instructions should get you up and running fairly quickly.

## Requirements

You will need 

- [ ] Stata license file `stata.lic`. You will find this in your local Stata install directory.

To run this locally on your computer, you will need

- [ ] [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://github.com/sylabs/singularity/releases). 

To run this in the cloud, you will need

- [ ] A Github account, if you want to use the cloud functionality explained here as-is. Other methods do exist.
- [ ] A Docker Hub account, to store the image. Other "image registries" exist and can be used, but are not covered in these instructions.


## Steps

1. [ ] You should copy this template to your own personal space. You can do this in several ways:
   - Best way: Use the "[Use this template](https://github.com/AEADataEditor/stata-project-with-docker/generate)" button on the [main Github page for this project](https://github.com/AEADataEditor/stata-project-with-docker/). 
   - Good: [Fork the Github repository](https://github.com/AEADataEditor/stata-project-with-docker) by clicking on **Fork** in the top-right corner.
   - OK: [Download](https://github.com/AEADataEditor/stata-project-with-docker/archive/refs/heads/main.zip) this project and expand on your computer.

2. [ ] Adjust the `Dockerfile`
3. [ ] Adjust the `setup.do` file
4. [ ] Build the Docker image
5. [ ] Run the Docker image

If you want to leverage the cloud functionality,

6. [ ] Upload the image to Docker Hub
7. [ ] Sync your code with your Github repository (which you created in Step 1, by using the template or forking)
8. [ ] Configure your Stata license in the cloud (securely)
9. [ ] Verify that the code runs in the cloud

If you want to go the extra step

10. [ ] Setup building the Docker image in the cloud

## Details

### Adjust the Dockerfile

The [Dockerfile](Dockerfile) contains the build instructions. A few things of note:

You may want to adjust the following lines to the Stata version of your choice. For released versions and "tags", see [https://hub.docker.com/u/dataeditors](https://hub.docker.com/u/dataeditors). 
```
ARG SRCVERSION=17
ARG SRCTAG=2021-10-13
ARG SRCHUBID=dataeditors
```

If you already have a setup file that installs all of your Stata packages, you do not need to rename it, simply change the following line:

```
COPY setup.do /setup.do
```

to read

```
COPY your_fancy_name.do /setup.do
```

If your file name has spaces (not a good idea), you may need to quote the first part (YMMV).

### Adjust the setup.do file

The template repository contains a `setup.do` as an example. It should include all commands that are required to be run for "setting up" the project on a brand new system. In particular, it should install all needed Stata packages. For additional sample commands, see [https://github.com/gslab-econ/template/blob/master/config/config_stata.do](https://github.com/gslab-econ/template/blob/master/config/config_stata.do).

```
    local ssc_packages "estout"

    // local ssc_packages "estout boottest"
    
    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
            dis "Installing `pkg'"
            ssc install `pkg', replace
        }
    }
```

### Build the image

By default, the build process is documented in [`build.sh`](build.sh) and works on Linux and macOS, but all commands can be run individually as well. You should edit the contents of the [`init.config.txt`](init.config.txt):

```
VERSION=17
# the TAG can be anything, but could be today's date
TAG=$(date +%F) 
MYHUBID=larsvilhuber
MYIMG=projectname
```

You may want to adjust the `MYHUBID` and `MYIMG` variables. `MYHUBID` is your login on Docker Hub, and `MYIMG` is the name by which you will refer to this image. A very convenient `MYIMG` name might be the same as the Github repository name (replace `projectname` with `${PWD##*/}`), but it can be anything. You can version with today's date (which is what `date +%F` prints out), or anything else.

Once you have adjusted the [`init.config.txt`](init.config.txt), you can run [`build.sh`](build.sh) (needs a Stata license file!). This will leverage the existing Stata Docker image, add your project-specific details as specified in the [`Dockerfile`](Dockerfile), install any Stata packages as specified in the setup program, and store the project-specific Docker image locally on your computer. It will also write out the chosen configuration into `config.txt`

You can now use that image to run your project's code.


### Run the image

The script [`run.sh`](run.sh) will pick up the configuration information in `config.txt`, and run your project inside the container image. Of note:

- you need the Stata license again
- it maps the `code/` sub-directory in the sample repository into the image as `/code/`. Your Stata code will want to take that into account.
- it also maps the `data/` sub-directory into the image as `/data/`. 
- no other subdirectory is available inside the image!
- The sample code [`code/main.do`](code/main.do) can be used as a template for your own main file. 
- Your output will appear wherever Stata code writes it to. If that is within the mapped directories `/data/` and `/code`, it will be preserved once the Docker image is stopped (and deleted).
- If you need additional sub-directories availabe in the image, you will need to map them, using additional `-v` lines.
  - For best practice, you might want to map an additional `results` directory, e.g., `-v $(pwd)/results:/results` and instruct your Stata code to write to that. 

## Cloud functionality

Once you have ascertained that everything is working fine, you can let the cloud run the Docker image in the future. Note that this assumes that all data can be either downloaded on the fly, or is available in the `data/` directory within Github (only recommended for quite small data). There are other ways of accessing large quantities of data (Git LFS, downloading from the internet, leveraging Dropbox, Box, or Google Drive), but those are beyond the scope for these instructions. 

To run code in the cloud, we will leverage a Github functionality called "[Github Actions](https://docs.github.com/en/actions/quickstart)". Similar systems elsewhere might be called "pipelines", "workflows", etc. The terminology below is focused on Github Actions, but generically, this can work on any one of those systems.

### Setting up Github Actions and Configure the Stata license in the cloud

Your Stata license is valuable, and should not be posted to Github! However, we need it there in order to run the Docker image. Github and other cloud providers have the ability to store "secure" environment variables, that are made available to their systems. Github calls these "[secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)" because, well, they are meant to remain secret. However, secrets are text, not files. So we need a workaround to store our Stata license as a file in the cloud. You will need a Bash shell for the following step. You can either do it from the command line, using the [`gh` command line tool](https://github.com/cli/cli), or generate the text, and copy and paste it in the web interface, as described [here](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

To run the image,  the license needs to be available to the Github Action as `STATA_LIC_BASE64` in "base64" format. From a Linux/macOS command line, you can generate it like this:
 
```bash
 gh secret set STATA_LIC_BASE64 -b"$(cat stata.lic | base64)" -v all -o YOURORG
```

where `stata.lic` is your Stata license file, and `YOURORG` is your organization (can be dropped if running in your personal account).


### Publish the image 

In order to run this in the cloud, the "cloud" needs to be able to access the image you just created. You thus need to upload it to [Docker Hub](https://hub.docker.com/). You may need to login to do this.


```
source config.txt
docker push $MYHUBID/${MYIMG}:$TAG
```

### Sync your Git repository

We assume you created a Git repository. If not, do it now! Assuming you have committed all files (in particular, `config.txt`, `run.sh`, and all your Stata code), you should push it to your Github repository:

```
git push
```

Note that this also enables you to use that same image on other computers you have access to, without rebuilding it: Simply `clone` your Github repository, and run `run.sh`. This will download the image we uploaded in the previous step, and run your code. This might be useful if you are running on a university cluster, or your mother-in-law's laptop during Thanksgiving. However, here we concentrate on the cloud functionality.

### Getting it to work in the cloud

By default, this template repository has a pre-configured Github Actions workflow, stored in [`.github/workflows/compute.yml`](.github/workflows/compute.yml). There are, again, a few key parameters that can be configured. The first is the `on` parameter, which configures when actions are triggered. In the case of the template file,

```
on:
  push:
    branches:
      - 'main'
  workflow_dispatch:
```

which instructs the Github Action (run Stata on the code) to be triggered either by a commit to the `main` branch, or to be manually triggered, by going to the "Actions" tab in the Github Repository. The latter is very helpful for debugging!

### Results

If you only run the code for testing purposes, you may simply be interested in whether or not the tests run successfully, and not in the outputs per se. However, if you wish to use this to actually run your code and retain meaningful results, then the last part of the [`.github/workflows/compute.yml`](.github/workflows/compute.yml) is relevant:

```
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3.8.0
        with:
           github_token: ${{ secrets.GITHUB_TOKEN }}
           publish_dir: .
           publish_branch: results 
           keep_files: true
```
In this case, once the code has run, the entire repository is pushed back to the "[results](https://github.com/AEADataEditor/stata-project-with-docker/tree/results)" branch. Alternatives consist in building and displaying a web page with results (in which case you might want to use the standard `gh-pages` branch), or actually compiling a LaTeX paper with all the results. 

If you are not interested in the outcomes, then simply deleting those lines is sufficient.

If you want to be really fancy (we are), then you show a badge showing the latest result of the `compute` run (which in our case, demonstrates that this project is reproducible!): [![Compute analysis](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/compute.yml). 

## Going the extra step

If we can run the Docker image in the cloud, can we also create the Docker image in the cloud? The answer, of course, is yes. 


### Configurating Docker builds in the cloud

This is pre-configured in [`.github/workflows/build.yml`](.github/workflows/build.yml). Reviewing this file shows a slightly different trigger:

```
on:
  push:
    branches:
      - 'main'
    paths:
      - 'Dockerfile'
  workflow_dispatch: 
```

Here, only changes to the `Dockerfile` trigger a rebuild. While that may seem reasonable, we might also want to include `setup.do`, or other files that affect the Docker image. However, we can also manually trigger the rebuild in the "Actions" tab.

### Additional secrets

We will need two additional  "secrets", in order to be able to push to the Docker Hub from the cloud.

```
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

See [the Docker Hub documentation](https://docs.docker.com/docker-hub/access-tokens/) on how to generate the latter.

### Running it

The [`.github/workflows/build.yml`](.github/workflows/build.yml) workflow will run through all the necessary steps to publish an image. Note that there's a slight difference in what it does: it will always create a "latest" tag, not a date- or release-specific tag. However, you can always associate a specific tag with the latest version manually. And because we are really fancy, we also have a badge for that: 
[![Build docker image](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml/badge.svg)](https://github.com/AEADataEditor/stata-project-with-docker/actions/workflows/build.yml).

### Not running it

If you do not wish to build in the cloud, simply deleting [`.github/workflows/build.yml`](.github/workflows/build.yml) will disable that functionality.

## Other options

We have described how to do this in a fairly general way. However, other methods to accomplish the same goal exist. Interested parties should check out the [ledwindra](https://github.com/ledwindra/continuous-integration-stata) and [labordynamicsinstitute](https://github.com/labordynamicsinstitute/continuous-integration-stata) versions of a pre-configured "Github Action" that does not require the license file, but instead requires the license information (several more secrets to configure). If "continuous integration" is not a concern but a cloud-based Stata+Docker setup is of interest, both [CodeOcean](https://codeocean.com) and (soon) [WholeTale](https://wholetale.org) offer such functionality.

## Conclusion

The ability to conduct "continuous integration" in the cloud with Stata is a powerful tool to ensure that the project is reproducible at any time, and to learn early on when reproducibility is broken. For small projects, this template repository and tutorial is sufficient to get you started. For more complex projects, running it locally based on this template will also ensure reproducibility. 

## Comments

For any comments or suggestions, please [create an issue](https://github.com/AEADataEditor/stata-project-with-docker/issues/new/choose) or contact us on [Twitter as @AeaData](https://twitter.com/AeaData).