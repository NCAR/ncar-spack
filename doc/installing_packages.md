# Installing Packages

If you need to install a new package into an existing deployment, you should
follow this general procedure. We will example each step in sequence.

## 0. Set up your environment

Before doing anything, you should ensure that your environment is:

* Cleaned of any loaded modules and unwanted shell variables
* Set up to use the correct Spack installation for your deployment
* Activated the build environment of your deployment

A script called `clean_bash` is provided to perform the first two steps for you.
In the **csg-spack-fork** repo, it is provided at `$SPACK_ROOT/bin/clean_bash`.

**TIP:** *If you are running as **csgteam** on the HPC systems, a shell function
should be in place to allow you to simply run `clean_bash` to load the current
default stack for the system you are on.*

**Setup commands:**
```
clean_bash
spacktivate -p .
```

## 1. Configure and confirm spec concretization

If you are installing something simple (and are lucky!), you can just specify
the package as a spec and let Spack figure everything else out. In any case, you
should always verify what Spack will do by running the `spec` subcommand:

```
$ spack spec -l zlib
 -   o4uq2ly  zlib@1.3.1%gcc@7.5.0+optimize+pic+shared build_system=makefile arch=linux-opensuse15-x86_64_v3
 -   nzt7gq7      ^gcc-runtime@7.5.0%gcc@7.5.0 build_system=generic arch=linux-opensuse15-x86_64_v3
[e]  dk74o57      ^glibc@2.31%gcc@7.5.0 build_system=autotools arch=linux-opensuse15-x86_64_v3
 -   s5jvccu      ^gmake@4.2.1%gcc@7.5.0~guile build_system=generic patches=ca60bd9,fe5b60d arch=linux-opensuse15-x86_64_v3
```

Often, you will need to customize the spec. The details of how to do this are
described well in the Spack documentation (using variants, specifying compilers,
setting requirements). For implementation, you have two options:

1. Customizing the spec directly
2. Implicitly customizing the spec via the `packages:` subsection of
   **spack.yaml**.

In general, use the direct customization if you only want this setting to apply
for a single spec (using a particular compiler) or you need to install a default
but wish to counter that default for this spec (e.g., use `+mpi` but the default
is `~mpi`. Otherwise, put your customizations in **spack.yaml**.

## 2. Add the spec to **packages.cfg**

At this point, you could install the spec using `spack install --add <spec>`,
but instead we use a custom script `install_packages` which provides a number of
advantages:

* Lets us add a matrix of packages without building for old compilers
* Tracks how specs compare to hashes to ensure consistent concretization
* Backs up critical database files to help restore the environment if Spack
  makes a mess of things

The `install_packages` script reads in specs from **packages.cfg**.

### Packages.cfg format

The packages config file is used to specify a list of specs to install when
running `install_packages`. If packages are already installed, they will be
skipped.

Packages should be contained within a section. There are three types of
sections:

- **singleton** - each listed spec is installed exactly once
- **by-compiler** - each listed spec is installed for all compilers defined in
  the **packages.cfg** file
- **by-mpi** - each listed spec is installed for all MPI libraries across all
  compilers defined in the **packages.cfg** file

Because these matrix sections use the compilers and/or MPIs defined in the
packages file, you can keep older matrices in the stack (via spack.yaml) without
adding new packages to them.

Additionally, each section or specific package can be customized by a number of
attributes. If specified on a section, the attribute will apply to all packages
contained within it. Attributes specified on a section are given as key=value
pairs after the section declaration:

```
by-compiler: key1=value1 key2=value2
```

Meanwhile, if specified on a single spec, the attribute should be given as a
key:value pair in angle-brackets <>:

```
spec <key:value>
```

Most attributes can be specified on either a spec or a section. These include:

* ****
