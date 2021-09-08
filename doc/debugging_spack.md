# Debugging Spack Issues
Inevitably, you will run into issues when performing operations using Spack. There are likely many ways to debug various problems, but the follow tips are generally applicable to many situations:

1. The main spack command has a debug flag `-d`, which provides a lot of information and can be repeated for higher verbosity.
2. Running `spack spec` and `spack find` with the `-N -I` flags can reveal a lot of information, though they are best run before performing any installations.

## Debugging Package Installs
When you install a package with Spack, Spack should provide some information about the temporary directory in which build commands were run if an error was encountered with a build command. For example:
```
[build] > spack install mpileaks %gcc@9.3.0 ^openmpi@3.1.6
==> Installing mpileaks-1.0-r5kvggttnqvikvbkqrsuhxcwdezyiuh4
==> No binary for mpileaks-1.0-r5kvggttnqvikvbkqrsuhxcwdezyiuh4 found: installing from source
==> Using cached archive: /glade/scratch/$USER/spack/casper/build/cache/_source-cache/archive/2e/2e34cc4505556d1c1f085758e26f2f8eea0972db9382f051b2dcfb1d7d9e1825.tar.gz
==> No patches needed for mpileaks
==> mpileaks: Executing phase: 'autoreconf'
==> mpileaks: Executing phase: 'configure'
==> mpileaks: Executing phase: 'build'
==> Error: ProcessError: Command exited with status 2:
...
See build log for details:  
/glade/scratch/$USER/spack-stage/spack-stage-mpileaks-1.0-r5kvggttnqvikvbkqrsuhxcwdezyiuh4/spack-build-out.txt
```
The location of these staging log files will depend on the value of $TMPDIR, if set. Other useful files are stored in that directory, including a dump of the environment used at build time. Note that Spack uses it's own compiler wrapper for builds, so values of CC/FC and the like may not match expectations.

*Once an installation completes, the build logs are moved out of the temporary staging directory into a hidden directory within the install prefix (e.g., `/path/to/spack/env/opt/package/.spack/`).*

**Alternative:** you can also output build logs directly to the command-line by adding the `-v` flag to the install subcommand.

### Verbose output from build commands
For some build systems (e.g., *CMake*), Spack will automatically enable verbose build output, so if you inspect the logs you should get useful output. Unfortunately, for some build systems like *gmake* and *autotools*, Spack does not enable verbose output and provides no option to change that. There are two ways get such output - the first involves temporarily editing the `package.py` file to add such an option.

For example, let's say we wanted to display verbose `make install` output for HDF5's *autotools* build system. We would edit the recipe to add the following setting to `build_targets`:
```
$SPACK_ROOT/var/spack/repos/builtin/packages/hdf5/package.py:
build_targets = ['V=1']
```

### Manual building after a failure
Spack also allows you to recreate the build environment and run the build commands manually, at which point you could increase verbosity among other changes. The steps are as follows:
```
# Return to the build directory for the package
spack cd <pkg-spec>

# Run a command using the build environment for the package spec (assumes clean_bash in PATH)
spack build-env <pkg-spec> -- clean_bash

# Rerun build commands with adjustments as desired
./configure ...
make V=1
```
