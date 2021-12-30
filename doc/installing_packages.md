# Installing Packages
Installing a new package into an NCAR production Spack environment should be a multiple-stage process. The basic outline is as follows:

1. **(IMPORTANT)** Clean your shell environment by running `clean_bash` or `clean_tcsh`.
2. **(IMPORTANT)** Activate the build environment using `spacktivate -p /path/to/build_env`.
3. Inspect dependencies for correctness using `spack spec -I -N <pkg-spec>`.
4. Install the package using `spack install <pkg-spec>`.
5. Refresh module tree using `spack module lmod refresh -y` and validate installation.
6. Run `bin/populate_build_cache /path/to/mirror` to add new binary builds to mirror.
7. Verify that everything is as it should be in the build environment (install and modules)
8. Push to the public environment by running `/bin/publish "commit message"`

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
9. Updates public environment module files
10. Commits changes to `spack.yaml`, `spack.lock`, and `/util` to a git repository

Eventually, the publish script will also push these changes to GitHub, but this is not in place yet.

## Writing Package Specifications
Technically, Spack can take a simple package name and make educated guesses at what you want, based on both default preferences and those explicitly defined in YAML files. In practice, this can result in many surprises that aren't ideal in an HPC public software tree. This motivates the first guideline: **be explicit when defining a pkg-spec**. For example, use `spack install parallel-netcdf@1.12.0 %gcc@9.3.0 ^openmpi@4.1.1`.

### Verifying dependencies using `spack spec -I -N`
Spack has a great subcommand called `spec`, which will list the dependencies a pkg-spec will need. The `-I -N` flags are always recommended, as they will show whether dependencies are already installed and from which repository the package install recipe (`package.py`) will be grabbed.

The spec subcommand can save you many headaches. Here is an interesting example, which also shows why being explicit is recommended:
```
$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 | grep openmpi
 -  y5rmv26cuwitxxzwbfouxdvtbr3h6v77^builtin.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake

$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 ^openmpi@4.1.1%gcc@9.3.0 | grep openmpi
[+] xym6esxdbz7lvxzy4vbib3sovxl3re3x^ncar.hpcd.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake
```
If you look closely, there is no discernable difference in package options for the two specs, and yet, for the simple spec Spack uses a different repository for Open MPI  (the default `builtin` repo) than it does for the spec which explicitly provides the Open MPI version (here it uses our custom `ncar.hpcd` repo).  We want it to use the already-installed (as denoted by the `[+]` label version using our custom recipe. Note that we are using another option, `-L`, to display the full install hash; this makes it clear that our versions are different.

*As an aside, the behavior shown above is likely a bug in the Spack concretizer, as there is no logical reason for the preferred repositories to be different for each invocation!*
