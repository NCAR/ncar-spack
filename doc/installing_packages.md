# Installing Packages
Installing a new package into an NCAR production Spack environment should be a multiple-stage process. The basic outline is as follows:

1. **(IMPORTANT)** Clean your shell environment by running `clean_bash` or `clean_tcsh`.
2. **(IMPORTANT)** Activate the build environment using `spacktivate -p $NCAR_SPACK_ENV_BUILD`.
3. Inspect dependencies for correctness using `spack spec -I -N <pkg-spec>`.
4. Add the package spec to `packages.cfg`.
5. Run `bin/install_packages` to install the spec and regenerate (private) modules.
6. Verify that everything is as it should be in the build environment (install and modules)
7. Push to the public environment by running `/bin/publish "commit message"`

More details on installing packages can be found in the Spack [basic installation tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_basics.html). 

### The `publish` script in-depth
The publish script is written to ensure that a uniform process is followed for installing packages from the build environment into the public environment. The script handles a number of important steps for you and should be the *only* means by which packages are installed into the public environment. It does the following:

1. Sanitizes the compute environment by running clean_bash
2. Activates the global Spack installation
3. Ensures that the owner of the public environment is the only one modifying it
4. Activates the build environment and checks for unconcretized changes (if found, it exits)
5. Ensures that the build cache is fully populated
6. Converts the build `spack.yaml` into the public environment equivalent - thus propagating all changes, not just package installs
7. Checks for uncommitted changes in the public repository (via a git repo)
8. Concretizes and installs new packages
9. Updates public environment module files and postprocesses the environment (e.g., add Cray modules)
10. Commits changes to `spack.yaml`, `spack.lock`, and `/util` to a git repository
11. Pushes changes to GitHub repo

## Writing Package Specifications
Technically, Spack can take a simple package name and make educated guesses at what you want, based on both default preferences and those explicitly defined in YAML files. In practice, this can result in many surprises that aren't ideal in an HPC public software tree. This motivates the first guideline: **be explicit when defining a pkg-spec**. For example, use `spack install parallel-netcdf@1.12.0 %gcc@9.3.0 ^openmpi@4.1.1`.

### Verifying dependencies using `spack spec -L -I -N`
Spack has a great subcommand called `spec`, which will list the dependencies a pkg-spec will need. The `-L -I -N` flags are always recommended, as they will show the package hash, whether dependencies are already installed, and from which repository the package install recipe (`package.py`) will be grabbed.

The spec subcommand can save you many headaches. Here is an interesting example, which also shows why being explicit is recommended:
```
$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 | grep openmpi
 -  y5rmv26cuwitxxzwbfouxdvtbr3h6v77^builtin.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake

$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 ^openmpi@4.1.1%gcc@9.3.0 | grep openmpi
[+] xym6esxdbz7lvxzy4vbib3sovxl3re3x^ncar.hpcd.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake
```
If you look closely, there is no discernable difference in package options for the two specs, and yet, for the simple spec Spack uses a different repository for Open MPI  (the default `builtin` repo) than it does for the spec which explicitly provides the Open MPI version (here it uses our custom `ncar.hpcd` repo).  We want it to use the already-installed (as denoted by the `[+]` label version using our custom recipe.

*As an aside, the behavior shown above is likely a bug in that version of the Spack concretizer, as there is no logical reason for the preferred repositories to be different for each invocation!*

## The `packages.cfg` format
The `install_packages` script will use the contents of the `packages.cfg` file in a build environment to install any new packages. This file has the following syntactical rules:

* A line beginning with `#` is a comment
* Package specs are organized by sections, which have a `:` at the end of the identifier
* Sections may have modifiers that go after the `:`
* Certain special modifiers are possible for single specs in the form `<type:modifier>`
* `%CMP%` and `%MPI%` are placeholders which will be replaced by one or more compilers or MPI libraries; if the placeholder is not used, the relevant compiler(s) and MPI(s) will be appended to the end of the spec

The file will be processed in order - compilers thus should go first and dependencies should go before dependent packages.

| Section Type | Description |
|--|--|
| singleton | Packages are only installed for a single compiler (default -> system GCC) |
| cdep | Packages will be installed for all compilers defined in `packages.cfg` |
| mdep | Packages will be installed for all defined permuations of compilers and MPI libraries |

The following section modifiers are currently supported:

| Section Modifier | Values | Description |
|--|--|--|
| type | compiler,mpi | Describe the following packages as compilers or MPI libraries |
| build | false | If set, don't run `spack install` |
| external | module | Detect the package by loading an existing module (e.g., Cray) |
| exclude | *pkgname* | For cdep/mdep sections, exclude the specified compiler/MPI |
| compiler | *pkgname* | For singleton/mdep sections, se the mentioned compiler |
| mpi | *pkgname* | For singleton/cdep sections, use the mentioned MPI library |

Additional, packages may have modifiers as well. Currently, there are two possible modifiers:

* **<compiler/mpi:spec options>** - This allows you to provide specific spec options only for specific compilers or MPI libraries. Useful for cdep/mdep sections.
* **\<hash-ref:NAME>** - This option allows you to store the hash Spack generates for this package into a variable with the specified name. It can then be referenced in a later section's spec using %NAME%. 

*Note that using direct hash references to get around concretization difficulties can lead to problems down the line when publishing to the public repo!*

### Example `packages.cfg`
```
# Cray compiler definitions
singleton: type=compiler build=false external=module
    cce@13.0.1
    gcc@10.3.0
    gcc@11.2.0

# Cray MPI definitions (we exclude Intel since the Cray container MPI does not support it)
cdep: type=mpi exclude=intel
    cray-mpich@8.1.13

# Packages we will install with the system GCC
singleton:
    lmod
    cmake

singleton: compiler=gcc@10.3.0
    r@4.1.3

# Packages will be installed with CCE and GCC as defined above
cdep:
    ncarcompilers@0.5.2
    netcdf@4.8.1 %CMP% <nvhpc:cflags=-noswitcherror> ^hdf5%CMP% ^curl%gcc

# Packages will be installed with CCE, GCC, and will use cray-mpich MPI
mdep:
    parallel-netcdf@1.12.2 %CMP% ^perl%gcc
```
