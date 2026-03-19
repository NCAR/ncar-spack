# Adding a New Cray Programming Environment

Installing a new CPE version is a collaborative multi-step process. First, HSG
will need to install CPE - this is currently done through SquashFS layering and
so is not doable in user-space, but this may change in the future.

When HSG installs the CPE, we expect them to install the following components:

1. The base CPE
2. The NVIDIA, GCC, and INTEL support for cray-mpich and cray-libsci

Notably, the CPE does not include the following components, which come from
elsewhere and have different update frequencies:

1. libfabric in /opt/cray/libfabric
2. PALS in /opt/cray/pals

PALS currently (as of March 2026) comes in two packages, both of which need to
be installed. One provides development headers and libraries, and the other
contains the PALS launcher binaries. Both `libpals.so` and `mpiexec` should be
in the PALS install for it to be useful.

All other CPE components will be installed into `/opt/cray/pe`.

!!! warning
    CPE assumes a minimum version of GCC will be in your default environment.
    For recent versions of CPE, GCC 12 or higher is required, so we cannot use
    the system GCC 7.5.0 as the core compiler. There may be better ways to
    figure this version requirement out, but the best I've found is to get the
    version listed in this directory that contains your desired version of
    cray-mpich from the CPE of interest:

    /opt/cray/pe/lmod/modulefiles/comnet/gnu/??/ofi/1.0/cray-mpich

!!! warning
    CPE traditionally has wanted to set up an `/etc/bash.bashrc.local` file that
    initializes TCL environment modules from HPE. These modules conflict with
    our Lmod module tree and so HSG disables this file for us. Still, it can be
    good to check to make sure this file is disable/erased before proceeding
    after a new CPE install. The resulting errors can be confusing!

## Setting Up Externals

There are three CPE components we actually use in Spack as externals:

1. cray-mpich
2. cce
3. cray-libsci

We also need to add the Cray libfabric as an external. The *libfabric* and *cce*
installs are detected and added by the `bin/add_constraints` script and
configuration in `constraints.cfg`. Simply ensure the config file is set up to
detect the versions of interest and run before installing any packages.

Unfortunately, the *cray-mpich* and *cray-libsci* externals must be added
manually at present. Both packages have compiler-specific prefixes. As of Spack
v1.1, each external **must** match a specific compiler version you intend to
use. The YAML config for *cray-mpich* looks as follows:

```
packages:
  cray-mpich:
    externals:
    - spec: cray-mpich@8.1.32 %gcc@15.2.0
      prefix: /opt/cray/pe/mpich/8.1.32/ofi/gnu/12.3
      extra_attributes:
        environment:
          append_path:
            LD_LIBRARY_PATH: /opt/cray/libfabric/1.22.0/lib64
    - spec: cray-mpich@8.1.32 %cce@19.0.0
      prefix: /opt/cray/pe/mpich/8.1.32/ofi/cray/17.0
      extra_attributes:
        environment:
          append_path:
            LD_LIBRARY_PATH: /opt/cray/libfabric/1.22.0/lib64
```

You will need to add an external definition for each compiler you wish to use.
The `LD_LIBRARY_PATH` setting pointing to the Cray libfabric is needed because
externals traditionally have not had dependencies. This may now be possible in
Spack v1.1 and could be revisited.

!!! tip "CPE package compiler compatibility"
    CPE packages that have compiler-dependent versions will list a compiler
    version in their prefix - the 12.3 for gnu above, for example. This version
    indicates the minimum compiler version supported by that version of the
    package.

## Installing CPE Packages

Package installation works much the same way as other non-CPE packages. As
mentioned before, only *libfabric*, *cray-mpich*, and possibly *cce* and
*cray-libsci* get installed directly into the Spack environment to be used as
either packages or dependencies. Furthermore, most of these packages do not have
Spack-generated modules, as the Cray modules have too much complexity to
reproduce via Spack.

## Adding CPE Modules

Rather than try to recreate Cray environment modules, we instead import them
with some modification into the module tree using a postprocessing unit.
Fittingly, this unit is called **add-cpe-modules**.

If you want to add a new CPE version to a stack, you will need to modify this
postprocessing unit to grab desired versions of CPE components. Most likely, the
two things you will need to edit are the list of **core** components and the
**cdep** components.

For example:

```
# Specify core modules to import into the Spack module tree
core="  craype/2.7.34
        cce/19.0.0
        perftools-base/25.03.0
        atp/3.15.6
        cray-ccdb/5.0.6
        cray-dyninst/12.3.5
        cray-stat/4.12.5
        gdb4hpc/4.16.4
        cray-mrnet/5.1.5
        papi/7.2.0.1
        sanitizers4hpc/1.1.5
        valgrind4hpc/2.13.5"

# Specify compiler-dependent modules to import into the Spack module tree
cdep="  cray-libsci/25.03.0
        cray-mpich/8.1.32 default variants=debug
        cray-mpich/9.0.0 cpe=25.03"
```

These versions can be deduced from examination of the file located at
**/opt/cray/pe/cpe/VERSION/set_default_release_VERSION.sh**.

## Adding Spack Compilers to the crayenv

We also offer another top-level module that a user could load instead of the
**ncarenv** called the **crayenv**. This environment seeks to faithfully
reproduce the module tree from HPE as one would see it on a traditional Cray
system.

We do not officially support this environment, and we also do not traditionally
install additional software into the environment. The modules are hidden from
view and so can only be seen using the `--show-hidden` flag to the `module`
command.

Hwoever, starting with the **ncarenv/25.10** deployment, we can now incorporate
Spack-built compilers into the **crayenv** module tree. This allows the
*nvidia*, *intel*, and *gcc* `PrgEnv` modules to be loaded while using
**crayenv**, as they depend on having a compiler available and we don't install
any provided by HPE.

To enable this, a few additions have been made:

1. In the `include/cray.yaml` file, there is a *crayenv* module set defined. As
   Cray compiler support evolves, you will probably need to modify three
   variables set for gcc, intel-oneapi-compilers, and nvhpc: `MODULEPATH`,
   `COMPAT_VERSION`, and `CRAY_LMOD_COMPILER`.
2. Logic has been added to the **add_cpe_modules** postprocessing unit to
   regenerate the *crayenv* module set if it is defined in the deployment.

The primary motivation for adding this functionality was to support efforts like
[spack-stack](https://github.com/jcsda/spack-stack/wiki) which expects a
"native" CPE environment on their Cray deployment systems.
