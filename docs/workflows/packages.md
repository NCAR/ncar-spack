## Installing a new package

As new versions of popular libraries (e.g., *netcdf*) are released, and users
request new packages, consultants will need to augment cluster deployments. All
of the tools to do this robustly are provided in a cluster deployment. Here, we
will run through an example for a production install, and so these steps assume
working as *csgteam*.

First, a word about how the deployment is structured. There should exist one
Spack clone, and two Spack environments: a *build* environment and a *public*
environment. The build environment is what you will interact with. Packages are
build from source in the *build* environment, and any changes should not be
visible to users. Only when you are happy with your changes in the *build*
environment should you `publish` them into the *public* environment.

In a new deployment, the `public` environment will not yet exist.

### Updating the *builtin* repo to get new package versions

Unfortunately, some terminology is overloaded here. In addition to Spack itself
being a Git repository, Spack stores its package recipes in a package
repository. The default repo is called *builtin*, and is contained with Spack
itself in the Spack Git repo. The problem is that checking out a newer version
of Spack or its *builtin* repo will update many things - including the package
API and package recipes. This can cause packages to concretize differently and
reduce reproducibility, and in some cases can even break the whole deployment.

**Updating the entire Spack clone should be avoided - consider this a scenario
for creating a new deployment!**

So let's say a user wants the latest and greatest version of a package, and the
version you see provided by our csg-spack-packages clone is older (use `spack info <package>`
to check versions). In this scenario, aim for the least invasive
changes possible. Typically, this means checking out only the desired package
from the main Spack upstream. The `deploy` script will configure the cloned
Spack to have an upstream remote to the main Spack repo.

### Example: Installing the latest ESMF

A user wants ESMF 8.9.1, but the deployed csg-spack-packages clone only provides
up to 8.9.0. Here is how you would obtain a newer version:

```
cd $NCAR_SPACK_ROOT_PACKAGES/repos/spack_repo/builtin/packages/
git fetch upstream develop
git checkout upstream/develop -- esmf
cd $SPACK_ENV
```

These commands will only check out the updated ESMF package recipe (including
the **package.py** and any new/modified patches). Note that sometimes you will
need to update dependencies too if your package has changes that are
incompatible with the current dependency recipe. But aim for the least number of
changes possible to get a successful build. And if the version the user wants is
provided already (or they don't care which version), then great, skip this
section!

## Configuring an optimal package build

Before installing any package, you should always run these two commands:

1. `spack info <spec>` - tells you which versions are availabe and which
   variants can be used to modify how the package will be built
2. `spack spec -I -l <spec>` - shows you exactly how the package will be built
   as currently configured, including the dependencies Spack will use; the `-I`
   flag will decorate the output with an indicator telling you whether the
   package is currently installed `[+]`, an external `[e]`, or needs to be
   installed `[-]`.

First, think about which variants you will need to configure to meet the user's
request. Also, consider whether the package should use the system compiler or be
built with our *module-loadable* compilers. It typically makes sense to use the
system compiler for lower level packages that get used as dependencies often
like *python* and *qt*. On the other hand, if a package depends on MPI you will
almost certainly want to built it using the module compilers.

The package build can be configured either in the *spec* or specifying
preferences and requirements in the **spack.yaml**. I prefer the latter, when
possible, as these settings will often influence how the package gets used as
dependencies, and will also help narrow the behavior if a user wants to use our
deployment as a Spack *upstream*.

!!! danger
    While I prefer `require` statements in YAML, recent versions of Spack have
    made these trickier to use. For example, if you set a requirement for
    `+variant`, but then the variant is removed in a future version of the
    package, many of your Spack commands will fail. Using `prefer:` can be
    safer, but note that the concretizer can **and will** ignore these settings
    from time to time.

If you wish to constrain any uninstalled dependencies of your package to use the
system compiler, add them to the **constraints.cfg** file in the *build*
environment and then run `bin/add_constraints`.

## Building the package

Once you are happy with the build configuration and have implemented any desired
constraints/preferences/requirements, you can install the package into the build
environment. You *could* do this with the following Spack command:

```
spack install --add <spec>
```

However, this method will not span multiple compilers/MPIs and also does not log
who performed the install. Instead, a helper script is provided to make complex
installs easier (and put logs in an easy to find location).

To install the package, add the `<spec>` into the **packages.cfg** file in an
appropriate subsection - packages can be one of the following:

* **singleton** - only a single configuration of this package is installed
* **cdep** - the package will be installed for every non-system compiler defined
  in **packages.cfg**
* **mdep** - the package will be installed for the matrix of compilers and MPIs
  defined in this file

Eventual user access to the package can be configured via the `access` tag. By
default, a new package will produce an environment module that can be loaded.
However, you can configure the package to appear in the *view* instead using
`access=view`. Any package in the *view* will be in the user environment by
default when the **ncarenv** module is loaded, as if it were a system package
installed using zypper/yum/apt-get.

There are many additional specifications that can be set on sections and
individual packages in the `packages.cfg` file. See existing listings for
inspiration and a full description of available settings by running:

```bash
bin/install_packages --help config
```

!!! note
    Compilers and MPIs installed into the **spack.yaml** but not listed in
    **packages.cfg** will NOT be used for cdep and mdep sections. This is
    another useful feature of using **packages.cfg** - think of it a record of
    the "actively updated" compiler and MPI stacks, while **spack.yaml**
    contains both active and inactive/deprecated versions.*

Once you have added the package `<spec>` to **packages.cfg**, you can begin the
source builds by running `bin/install_packages`. If all goes well, this should
install the package(s) and any necessary dependencies into the *build*
environment. 

## Testing the package

Once you have successfully built the package, you should run the following
additional steps to prepare the build environment for testing:

```bash
spack module lmod refresh -y
bin/postprocess
```

Even if your package does not produce a new environment module, it is good to
run these commands to get a sense of how the production environment will look to
users. Once this is ready, you can use a helper script to switch your
module environment from the default (production *public*) to your build stack:

```bash
bin/use_modules[.csh]
```

You should see your package binaries/libraries/headers either in the default
environment (if set to exist in the *view*) or in the module listing from
`module avail`. At this point, do whatever testing you need to do to ensure the
package seems robust.

!!! tip
    You can also ask users to run `use_modules` and they can provide you
    feedback, before you ever make the package available to other users!

