
# ncar-spack
This repository contains scripts, configuration files, and documentation for installing, setting up, and using production Spack software trees on NCAR clusters. The tools included within will:

1. Ensure that your environment has only what is needed to deploy software for the specified cluster. Shell environment contamination can produce unintended results when using Spack.
2. Standardize the process of deploying software stacks and individual packages on NCAR systems using Spack.
3. Track software stack changes via Git / GitHub integration.
4. Increase reproducibility (to the extent possible given development on Spack itself).

Read the rest of this README for a quick introduction to deploying software using this repository. Additional documentation is available in the `doc` subdirectory, mostly relating to interacting with existing deployments. The following topics are covered there in more detail:

 - [Installing packages](doc/installing_packages.md)
 - [Creating a custom package](doc/custom_packages.md)
 - [Site customizations](doc/site_customizations.md)
 - [Debugging Spack issues](doc/debugging_spack.md)

## Getting Started
Some terminology first: the tools provided allow you to create new software stack **deployments** for a specified **cluster**. The list of **clusters** can be found in the `clusters` subdirectory of this repository.

### Creating a new Spack software stack *deployment*
Clone this repository to a connected storage platform. This repository can be removed once the deployment is completed, though it will probably be useful to keep around.
```
git clone git@github.com:NCAR/ncar-spack.git
```
In the root directory of the repository you will find the `deploy` script. Run this script with the name of the **cluster** to initiate a deployment. There are *two* types of **deployments**, a testing deployment and a production deployment. In practice, the only real difference is that production deployments will have components installed in a user application path.
```
cd ncar-spack
./deploy [-p/--production] CLUSTER
```
The `deploy` script will now perform the following steps:
1. Create a clone of Spack using a specific commit/tag.
2. Copy convenience scripts from this repo.
3. Create a **build** *Spack* environment.
4. Create a binary cache mirror and set up custom *Spack* package repositories.
5. Configure the build environment to use the aforementioned customizations.
6. Run `install_packages` to build, from source, all packages specified in the **cluster's** `packages.cfg` file. (*unless --no-pkgs is specified to `deploy`*)
7. Run `populate_build_cache` to create binaries from built packages for quick reinstall.

Now you have a **build** environment. You should verify that everything appears as you expect within the **build** environment. Whenever you interact with Spack, you should first run the `clean_bash` script, which will ensure that various shell environment settings do not confuse Spack. This script will also *add* Spack to your shell environment, so you need not run Spack's `setup-env.sh` script.
```
$NCAR_SPACK_ROOT_DEPLOYMENT/spack/bin/clean_bash
cd $NCAR_SPACK_ENV_BUILD
spacktivate [-p] .
```
The above commands will activate the *Spack* environment, allowing you to run basic Spack commands like `spack find`, `spack spec`, and `spack info`.

Once you are satisfied that the **build** environment is correctly deployed, run `publish` to create the **public** environment. This environment is the one that should be visible to users via *environment modules*.
```
bin/publish "Initial deployment of this cluster"
```
The public environment should now be ready for integration into the startup process via `/etc/modules.sh`.

#### Contents of a production deployment
In a production deployment, there will typically be two relevant directories. First, there will be a private directory containing the *Spack environments*, helper scripts, and test builds of packages:
```
/glade/work/csgteam/spack-deployments
└── <cluster>
    └── <deployment>
        └── envs
            ├── build -> All packages are build and validated here
            └── public -> Contains YAML file for public stack along with tracking Git repo
```

The public user-facing directories will only contain aspects of the deployment with which users will directly interact:
```
/glade/u/apps/<cluster>
├── <deployment>
│   ├── config -> YAML settings broken into individual config files for users to leverage
│   ├── ncarenv -> Basic packages we always want in the user environment (e.g., ghostscript)
│   ├── spack -> The clone of Spack which also contains the production software stack
│   └── util -> Typical scripts to set up Lmod for various shells
├── default -> Symbolic link to current default deployment (mostly to select Lmod version)
├── mirror -> Package mirror used across all deployments to speed reinstall
│   └── build_cache
└── modules -> Module tree containing all deployments and "meta" modules
    ├── 22.02
    └── environment
```

### Installing new packages into an existing deployment
In theory, installing a new package into a deployment is easy, but in practice there are often complications. If you follow these guidelines and instructions, you should avoid most pitfalls.

**Never build packages from source in the public environment - always use the build environment!**

It is strongly encouraged (mandatory?) to analyze how Spack will *concretize* your new install before you actually build the package. To do so, activate the **build** environment and use the `spec` subcommand:
```
clean_bash
cd $NCAR_SPACK_ENV_BUILD
spacktivate [-p] .
spack spec -I -l -N <spec>
```
Keep an eye out for the following aspects of the dependencies:
1. Are we using the desired compiler for each dependency?
2. Are we using the correct package repository (typically *builtin* but not always)?
3. Are we reusing already installed dependencies when logical to do so? (*look for [+] to indicate reuse*)
4. Is the package and/or dependencies using desired variants?

If something doesn't seem right, it can be useful to examine the package recipe to look for any constraints the package maintainers are imposing on the concretizer. Do so by running `spack edit <package>`.

Once you are happy with the output of `spec`, you could simply run `spack install <spec>`. Consider instead adding the spec to `packages.cfg` and running `bin/install_packages`. This script will perform the install for you and log the entire process. It can also install a spec for multiple compilers and MPI libraries.

Assuming the install went correctly, you can then test the package, look at the resulting module file (if one was created) and finally publish the package to the **public** environment using `publish`.
```
vi packages.cfg (and add spec)
bin/install_packages
...
bin/publish "Installed new version of netCDF"
```

#### Retrieving new packages from the builtin package repo
If you want to install a newer version of a package, it may not be in the cloned version of the *builtin* repo. Most clusters will be configured to create a separate clone of *builtin* that can be advanced beyond the tag/commit of the main Spack repository. Note that if the Spack developers make an API change to packaging, this can cause things to break. Use caution!
```
cd $NCAR_SPACK_ENV_BUILD/repos/builtin/packages
git fetch
git merge <commit>
```
**Always make sure the build and public environments are in sync (using `publish`) before pulling new package updates from the Spack remote.**

## Usage Tips
### Using `clean_bash` to add Spack to your environment
Spack provides source-able scripts to add itself to your shell environment. These scripts will modify your `PATH` and add shell aliases. Running `clean_bash` will take care of these steps for you in addition to providing you with an otherwise pristine bash shell environment. There is a `clean_tcsh` script too, but the c-shell does not have the required functionality to source the Spack setup script. *It is recommended that you use the bash script!*

The `clean_bash` script is located in the `bin` directory of the **cluster deployment's** Spack clone. On a production system, it is recommended to add this `bin` directory to your bash `.profile` and/or `.bashrc`.

`clean_bash` modifies your shell prompt to indicate that you are in a clean shell session. You can further customize the prompt by exporting `$NCAR_SPACK_PROMPT` in your environment (or setting it at startup) before invoking `clean_bash`.

#### Using a Custom Spack Install
When using a test cluster deployment and/or debugging, it can be useful to use a non-default Spack installation. The `clean_bash` script can initialize a custom version instead of the one set in your startup files using the following environment setting:
```
CUSTOM_SPACK_ROOT=/glade/work/$USER/custom-spack clean_bash
```

### Configuring Vim
Since Spack will output YAML lines with two-space indentation, the following Vim settings are recommended:
```
$ cat ~/.vim/after/ftplugin/yaml.vim
setlocal shiftwidth=2
setlocal tabstop=2
```
