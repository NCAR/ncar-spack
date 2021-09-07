# Installing Packages
Installing a new package into an NCAR production Spack environment should be a multiple-stage process. The basic outline is as follows:

1. **(IMPORTANT)** Clean your shell environment by running `clean_bash` or `clean_tcsh`.
2. **(IMPORTANT)** Activate the build environment using `spacktivate -p /path/to/build_env`.
3. Inspect dependencies for correctness using `spack spec -I -N <pkg-spec>`.
4. Install the package using `spack install <pkg-spec>`.
5. Refresh module tree using `spack module lmod refresh -y` and validate installation.
6. Run `populate_build_cache /path/to/mirror` to add new binary builds to mirror.
7. Switch to public environment (`despacktivate; spacktivate -p /path/to/pub_env`).
8. Install the package using the same `pkg-spec`. Spack should use the built binaries.
9. Verify install using `spack find <pkg-spec>` and refresh module tree.
10. ***(future)** Commit changes to `spack.yaml` file and push to GitHub.*

More details on installing packages can be found in the Spack [basic installation tutorial](https://spack-tutorial.readthedocs.io/en/latest/tutorial_basics.html). 

## Writing Package Specifications
Technically, Spack can take a simple package name and make educated guesses at what you want, based on both default preferences and those explicitly defined in YAML files. In practice, this can result in many surprises that aren't ideal in an HPC public software tree. This motivates the first guideline: **be explicit when defining a pkg-spec**. For example, use `spack install parallel-netcdf@1.12.0 %gcc@9.3.0 ^openmpi@4.1.1`.

### Verifying dependencies using `spack spec -I -N`
Spack has a great subcommand called `spec`, which will list the dependencies a pkg-spec will need. The `-I -N` flags are always recommended, as they will show whether dependencies are already installed and from which repository the package install recipe (`package.py`) will be grabbed.

The spec subcommand can save you many headaches. Here is an interesting example, which also shows why being explicit is recommended:
```
$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 | grep openmpi
 -  y5rmv26cuwitxxzwbfouxdvtbr3h6v77^builtin.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake

$ spack spec -I -N -L parallel-netcdf@1.12.1 %gcc@9.3.0 ^openmpi@4.1.1%gcc@9.3.0 | grep openmpi
[+] xym6esxdbz7lvxzy4vbib3sovxl3re3x^common.openmpi@4.1.1%gcc@9.3.0~atomics+cuda~cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers~lustre~memchecker~pmi~singularity~sqlite3+static~thread_multiple+vt+wrapper-rpath fabrics=auto schedulers=tm arch=linux-centos7-skylake
```
If you look closely, there is no discernable difference in package options for the two specs, and yet, for the simple spec Spack uses a different repository for Open MPI  (the default **builtin** repo) than it does for the spec which explicitly provides the Open MPI version (here it uses our custom **common** repo).  We want it to use the already-installed (as denoted by the `[+]` label version using our custom recipe. Note that we are using another option, `-L`, to display the full install hash; this makes it clear that our versions are different.

*As an aside, the behavior shown above is likely a bug in the Spack concretizer, as there is no logical reason for the preferred repositories to be different for each invocation!*
