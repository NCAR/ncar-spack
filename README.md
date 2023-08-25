# ncar-spack

## What is ncar-spack?

This repository contains cluster configurations for NCAR HPC software stacks, a deployment script, and helper scripts that get installed into a cluster deployment to facilitate reproducible and consistent package management across the consulting team.

It is also important to note what this repository is **not**. It is not a fork of Spack itself - though a cluster *should* use the CSG Spack fork. It is also not for tracking a production cluster deployment. Rather, this repository contains the recipe and the tools for starting a deployment, which is then tracked in its own repo!

## Getting started

The following instructions describe cloning this repository and starting a new cluster deployment. If you want to know how to install a package into an existing deployment, create a new cluster recipe, or update a cluster recipe in this repository from changes made in production, see the appropriate section below.

To get started, simply clone this repository either as yourself or as *csgteam*. If you plan to produce a public production cluster deployment, you will need to run as *csgteam*.

```
git clone git@github.com:NCAR/ncar-spack.git
```
*The clone command above assumes SSH-key usage!*

#### Vim users: YAML configuration

Since Spack will output YAML lines with two-space indentation, the following Vim settings are recommended:
```
$ cat ~/.vim/after/ftplugin/yaml.vim
setlocal shiftwidth=2
setlocal tabstop=2
```

## Deploying a cluster from scratch
Cluster definitions are contained in the `clusters` subdirectory and typically contain the following components:
```
clusters/
├── casper
│   ├── constraints.cfg - external packages, and packages required to use the system GCC
│   ├── main.cfg        - top-level path, name, and version settings for the cluster deployment
│   ├── packages.cfg    - an inventory of packages to be built upon deployment (and beyond)
│   ├── postprocess     - a bash script that runs last and does cluster prep that Spack cannot
│   ├── repos.cfg       - any custom package repositories to include (i.e. ncar.hpcd recipes)
│   └── spack.yaml      - the Spack environment template that will become the cluster stack
...
```
Remember, these are simply templates! To generate a cluster deployment from one of these recipes, simply run the `deploy` script in the top-level directory. For example:
```
./deploy [--production] [--no-pkgs] casper
```
This command will clone csg-spack-fork and check out the branch specified in the cluster's **main.cfg** (or use the `ncar-mods` branch if left blank), copy the cluster recipe template and replace placeholders with proper paths and settings, set up a build cache mirror if one does not already exist, and (*if `--no-pkgs` is not set*) will build the packages specified in **packages.cfg**.

The `--production` flag can only be specified when running as *csgteam*. Without this flag, a *test* deployment will be created at the location configured in the cluster definition (probably your scratch directory). Doing a test deployment can be a good way to learn how this all works without breaking things, and is recommended! :thumbsup:

> *Keep in mind that changes made after you deploy a cluster will cause divergence from the recipe contained in this repo. This is expected, but if you wish to propagate those changes to a new version of the deployment, you should merge them into the recipe and push the changes to ncar-spack (see below)!*

## Installing a new package
As new versions of popular libraries (e.g., *netcdf*) are released, and users request new packages, consultants will need to augment cluster deployments. All of the tools to do this robustly are provided in a cluster deployment. Here, we will run through an example for a production install, and so these steps assume working as *csgteam*.

First, a word about how the deployment is structured. There should exist one Spack clone, and two Spack environments: a *build* environment and a *public* environment. The build environment is what you will interact with. Packages are build from source in the *build* environment, and any changes should not be visible to users. Only when you are happy with your changes in the *build* environment should you `publish` them into the *public* environment.

### Environment prep: `clean_bash` and `spacktivate`
Before doing anything with a cluster deployment, you should first launch a clean bash shell that has been scrubbed of personal settings and modules. Since this step is fundamental to using *ncar-spack*, a script called `clean_bash` is provided in the csg-spack-fork to do this for you. The script will also initialize Spack to run in your environment, and change your directory to the *build* environment.

The script can be found in the `bin` directory of the clone Spack, and it is also typically configured to run as a shell function when you are *csgteam* (via **.bashrc** settings).

Once you are in a sanitized bash shell, you can "activate" the *build* environment. This step is important, because otherwise Spack will make decisions based on the configuration in the Spack clone settings directory, rather than our environment settings contained in **spack.yaml**.

**For example:**
```
clean_bash
spacktivate -p .
```
Since `clean_bash` places you in the *build* directory, you can use `.` to indicate the environment path. The `-p` option provides a nice prompt decorator indicating the build environment is active.

### Updating the *builtin* repo to get new package versions
Unfortunately, some terminology is overloaded here. In addition to Spack itself being a Git repository, Spack stores its package recipes in a package repository. The default repo is called *builtin*, and is contained with Spack itself in the Spack Git repo. The problem is that checking out a newer version of Spack or its *builtin* repo will update many things - including the package API and package recipes. This can cause packages to concretize differently and reduce reproducibility, and in some cases can even break the whole deployment.

:rotating_light: **Updating the entire Spack clone should be avoided - consider this a scenario for creating a new deployment!** :rotating_light:

So let's say a user wants the latest and greatest version of a package, and the version you see provided by our Spack clone is older (use `spack info <package>` to check versions). In this scenario, aim for the least invasive changes possible. Typically, this means checking out only the desired package from the main Spack upstream. The `deploy` script will configure the cloned Spack to have an upstream remote to the main Spack repo.

#### Example: Installing the latest ESMF
A user wants ESMF 8.6.0, but the deployed Spack clone only provides up to 8.5.2. Here is how you would obtain a newer version:

```
cd $SPACK_ROOT/var/spack/repos/builtin/packages
git fetch upstream develop
git checkout upstream/develop -- esmf
cd $SPACK_ENV
```

These commands will only check out the updated ESMF package recipe (including the **package.py** and any new/modified patches). Note that sometimes you will need to update dependencies too if your package has changes that are incompatible with the current dependency recipe. But aim for the least number of changes possible to get a successful build. And if the version the user wants is provided already (or they don't care which version), then great, skip this section!

### Configuring an optimal package build
Before installing any package, you should always run these two commands:
1. `spack info <spec>` - tells you which versions are availabe and which variants can be used to modify how the package will be built
2. `spack spec -I -l <spec>` - shows you exactly how the package will be built as currently configured, including the dependencies Spack will use; the `-I` flag will decorate the output with an indicator telling you whether the package is currently installed `[+]`, an external `[e]`, or needs to be installed `[-]`.

First, think about which variants you will need to configure to meet the user's request. Also, consider whether the package should use the system compiler or be built with our *module-loadable* compilers. It typically makes sense to use the system compiler for lower level packages that get used as dependencies often like *python* and *qt*. On the other hand, if a package depends on MPI you will almost certainly want to built it using the module compilers.

The package build can be configured either in the *spec* or specifying preferences and requirements in the **spack.yaml**. I prefer the latter, when possible, as these settings will often influence how the package gets used as dependencies, and will also help narrow the behavior if a user wants to use our deployment as a Spack *upstream*.

If you wish to constrain any uninstalled dependencies of your package to use the system compiler, add them to the **constraints.cfg** file in the *build* environment and then run `bin/add_constraints`.

### Building the package
Once you are happy with the build configuration and have implemented any desired constraints/preferences/requirements, you can install the package into the build environment. You *could* do this with the following Spack command:
```
spack install --add <spec>
```
However, this method will not span multiple compilers/MPIs and also does not log who performed the install. Instead, a helper script is provided to make complex installs easier (and put logs in an easy to find location).

To install the package, add the `<spec>` into the **packages.cfg** file in an appropriate subsection - packages can be one of the following:
* **singleton** - only a single configuration of this package is installed
* **cdep** - the package will be installed for every non-system compiler defined in **packages.cfg**
* **mdep** - the package will be installed for the matrix of compilers and MPIs defined in this file

Eventual user access to the package can be configured via the `access` tag. By default, a new package will produce an environment module that can be loaded. However, you can configure the package to appear in the *view* instead using `access=view`. Any package in the *view* will be in the user environment by default when the **ncarenv** module is loaded, as if it were a system package installed using zypper/yum/apt-get.

There are many additional specifications that can be set on sections and individual packages in this configuration file. See existing listings for inspiration (*full documentation TBD*).

> *Note that compilers and MPIs installed into the **spack.yaml** but not listed in **packages.cfg** will NOT be used for cdep and mdep  sections. This is another useful feature of using **packages.cfg** - think of it a record of the "actively updated" compiler and MPI stacks, while **spack.yaml** contains both active and inactive/deprecated versions.*

Once you have added the package `<spec>` to **packages.cfg**, you can begin the source builds by running `bin/install_packages`. If all goes well, this should install the package(s) and any necessary dependencies into the *build* environment. If something goes wrong, ask colleagues in **#spack** on the **hpc-ucar** Slack. :speech_balloon:

### Testing the package

Once you have successfully built the package, you should run the following additional steps to prepare the build environment for testing:
```
spack module lmod refresh -y
bin/postprocess
```
Even if your package does not produce a new environment module, it is good to run these commands to get a sense of how the production environment will look to users. Once this is ready, you can use a helper script to switch your environment from the default (production *public*) to the build stack:
```
bin/use_modules[.csh]
```
You should see your package binaries/libraries/headers either in the default environment (if set to exist in the *view*) or in the module listing from `module avail`. At this point, do whatever testing you need to do to ensure the package seems robust. **You can also ask the user to run `use_modules` and they can provide you feedback, before you ever make the package available to other users!**

### Publishing the package
Finally, assuming all goes well to this point and testing was a success, you can publish the changes from the *build* environment to the *public* environment. A helper script should handle all of this for you.

:rotating_light: **You should rarely, if ever, need to manually make changes to the public environment!** :rotating_light:

All published changes get committed and pushed to a GitHub repo (if this is a production deployment) called `spack-<cluster>` . This repo is publicly visible and can be used by the community to report bugs and request new packages. Thus, the publish script expects one argument - a commit message.

```
bin/publish "Installed latest emacs for benkirk in #4"
```

The `publish` script will describe all of the changes it makes, including package installs, **spack.yaml** changes,  refreshing the module tree, and postprocessing.

#### What if something went wrong?

Spack is finnicky and it is rather easy to get in a pickle, but *most* situations are recoverable if addressed early. If you are unsure about what to do, please ask for help in our **hpc-ucar #spack** Slack channel!

## Updating a cluster definition with production changes

TODO: document when and how to do this
