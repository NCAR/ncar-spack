# ncar-spack
Read the following for a quick introduction to this repository. Additional documentation is available in the `doc` subdirectory, mostly relating to interacting with existing deployments. The following topics are covered there in more detail:

 - [Installing new packages](doc/installing_packages.md)
 - [Creating a custom package](doc/custom_packages.md)
 - [Site customizations](doc/site_customizations.md)
 - [Debugging Spack issues](doc/debugging_spack.md)

## Overview
This repository contains scripts, configuration files, and documentation for installing, setting up, and using production Spack software trees on NCAR clusters. The basic workflow for doing a brand new install of **both Spack and an cluster deployment** is as follows:

 1. Clone this repository
 2. Change settings in cluster config as desired
 3. Run `./deploy <cluster>`

A `ncar-spack` cluster deployment generally consists of the following components:

```
deployment
├── config - directory of configuration files that users can leverage when using our stack as an upstream
├── envs
│   ├── build - a Spack environment for CSG to build & test packages and then generate binaries for the build cache
│   └── public - a Spack environment for production installs which are visible to and used by the users
├── mirror - source mirror and build cache, containing binary bundles for built packages for quick deployment and disaster recovery
├── modules - the user-visble tree of Lmod modules
│   ├── ...
├── spack - the clone of Spack for the deployment; Spack binaries, package recipes, and production package installs
│   ├── ...
└── util - contains scripts for user-facing setup (e.g., localinit scripts for module tree startup)
```

We are using Spack "[environments](https://spack.readthedocs.io/en/latest/environments.html)" for each cluster deployment, as they offer configuration isolation and collect all settings into a single YAML file for easy tracking via Git repositories. All deployments share a single Spack installation at a global path.

*This specific repository should only be used for tracking system-wide configuration of Spack and initialization/deployment scripts. Actual deployments (Spack installs and environments) should be version tracked by their `spack.yaml` files in their public repositories. **However, the initial spack.yaml and configuration settings files could be updated if a full redeployment is necessary.***

## Spack Usage Rules

Please follow these rules when using Spack as CSG. Always:

1. **Sanitize your shell environment** before running any Spack commands. This repository contains helper scripts called `clean_bash` and `clean_tcsh`, which can be used in place of bash and tcsh respectively.
2. **Activate a Spack environment** before making any modifications using Spack commands. You can use the `-p` option to `spack env activate` / `spacktivate` to display a command-line prompt modifier.
3. **Install first into the build environment**. Software should only be installed into the public environment after being built and tested in the build environment and a binary created for the cache mirror.

The following recommendations are not necessarily required, but are strongly advised from experiences in testing Spack:

1. **Use explicit spec definitions.** In theory, package preferences are configured in `spack.yaml` that should allow you to use generic specs (e.g., `spack install parallel-netcdf`). In practice, Spack is very fickle when producing a [DAG](https://spack-tutorial.readthedocs.io/en/latest/tutorial_basics.html#installing-packages) and will often do something you don't intend. If you explicitly specify dependencies, you will be much better off (e.g., `spack install parallel-netcdf %gcc@9.3.0 ^openmpi@4.1.1`).
2. **Always confirm dependencies .** Unless you are 100% sure Spack will do what you intend, don't simply run `spack install <spec>` blindly! First, confirm the DAG using `spack spec -I -N <spec>`.

## Getting Started
### Installing Spack
As we are using Spack environments for each cluster, we can install a single instance of Spack itself to service all globally-accessible systems. The `install` script will do this for you, based on the settings configured in `etc/global.cfg`. Currently, the following settings are available:

 - **NCAR_ROOT_SPACK** - the directory in which Spack will be installed
 - **NCAR_SPACK_VERSION** - the commit or tag of Spack which will be used in the install
 - **MAX_BUILD_JOBS** - a global Spack [configuration setting](https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs) which will limit the number of threads Spack may use for installs. This will apply to all environments. Limiting to 10 or less is recommended.

*While Spack could be deployed using the HEAD commit, this is not recommended because package definitions and default versions often change with new Spack tags/versions. Locking to a version ensures reproducibility.*

### Adding Spack to Your Shell Environment
Spack provides source-able scripts to add itself to your shell environment. These scripts will modify your `PATH` and add shell aliases. Note that Spack has Python version requirements for functionality - it is best to use a recent Python 3.x. On future systems this should not be an issue, but on Cheyenne and Casper, you should add a modern Python to your PATH first. For BASH:
```
export PATH=/glade/u/apps/<sys>/opt/python/3.7.9/gnu/9.1.0/bin:$PATH
source <NCAR_ROOT_SPACK>/share/spack/setup-env.sh
```

*Note: running `clean_bash` will take care of both of these steps for you, in addition to providing you with an otherwise pristine bash shell environment. The [t]c-shell does not have the required functionality to source the Spack setup script, but it will still clean the environment and add a modern Python.*

Since Spack will output YAML lines with two-space indentation, the following Vim settings are recommended:
```
$ cat ~/.vim/after/ftplugin/yaml.vim
setlocal shiftwidth=2
setlocal tabstop=2
```

The `clean_bash` script modifies your shell prompt to indicate that you are in a clean shell session. You can further customize the prompt by exporting `$NCAR_SPACK_PROMPT` in your environment before invoking `clean_bash`.

#### Using a Custom Spack Install
When testing Spack updates and/or debugging, it can be useful to use a non-default Spack installation. The clean_bash script can initialize a custom version instead of the one set in your startup files using the following environment setting:
```
CUSTOM_SPACK_ROOT=/glade/work/$USER/custom-spack clean_bash
```
### Deploying a New Spack Environment
An environment in Spack is simply a directory with a `spack.yaml` file, which contains the Spack settings that define compilers, package preferences, installations, modules and more. Many of the settings can be implemented interactively via Spack commands, but many others require direct editing of the YAML file. As such, this repository includes the `deploy` script, which handles both jobs. Usage is as follows:
```
./deploy [--nopkgs] <clustername>
```
Clusters are defined in the `clusters` subdirectory. Once run, this script does the following:

1. Sanitize the shell environment and make sure Spack is initialized
2. Copy the template `spack.yaml` for a particular cluster and modify paths for `opt` and `modules`
3. Create utility scripts like `localinit.*` for modules
4. Find and register [external package](https://spack.readthedocs.io/en/latest/build_settings.html#external-packages) installs
5. Create a [build cache/mirror](https://spack.readthedocs.io/en/latest/binary_caches.html) so that future installs are quick
6. Add custom NCAR package definitions via the `ncar.hpcd` [repository](https://spack.readthedocs.io/en/latest/repositories.html)
7. Find and register custom [module templates](https://spack-tutorial.readthedocs.io/en/latest/tutorial_modules.html#working-with-templates)
9. Build packages in the build environment as defined in `packages.cfg`
10. Create binary versions of installs and populate build cache
11. Generate Lmod [modules](https://spack-tutorial.readthedocs.io/en/latest/tutorial_modules.html#hierarchical-module-files) in the build environment

Notably, this script *does not* install packages into the production environment. It is assumed that the operator will sanity check the build environment before populating the public-facing stack. This script will copy a `publish` script into $SPACK_ENV/bin, which can be used to push changes from the build environment to the public environment. See [Installing new packages](doc/installing_packages.md) for more details on this script.
