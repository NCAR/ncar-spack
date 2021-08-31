# ncar-spack

This repository contains scripts, configuration files, and documentation for installing, setting up, and using production Spack environments on NCAR clusters. The basic workflow for doing a new install is as follows:

 1. Clone this repository
 2. Change settings in global config as desired
 3. Run `install` 
 4. Change settings in cluster config as desired
 5. Run `deploy <cluster>`

We are using Spack "environments" for each cluster deployment, as they offer configuration isolation and collect all settings into a single YAML file for easy tracking. All systems share a single Spack installation at a global file mount.

*This specific repository should only be used for tracking system-wide configuration of Spack and initialization/deployment scripts. Actual deployments (Spack environments) should be version tracked by their `spack.yaml` files in separate repositories.*

## Spack usage rules

Please follow these rules when using Spack as CSG. Always:

1. **Sanitize your shell environment** before running any Spack commands. This repository contains helper scripts called `clean_bash` and `clean_tcsh`, which can be used in place of bash and tcsh respectively.
2. **Activate a Spack environment** before making any modifications using Spack commands. You can use the `-p` option to `spack env activate` / `spacktivate` to display a command-line prompt modifier.
3. **Install first into the build environment**. Software should only be installed into the public environment after being built and tested in the build environment and a binary created for the cache mirror.

The following recommendations are not necessarily required, but are strongly advised from experiences in testing Spack:

1. **Use explicit spec definitions.** In theory, package preferences are configured in `spack.yaml` that should allow you to use generic specs (e.g., `spack install parallel-netcdf`). In practice, Spack is very fickle when producing a DAG and will often do something you don't intend. If you explicitly specify dependencies, you will be much better off (e.g., `spack install parallel-netcdf %gcc@9.3.0 ^openmpi@4.1.1`).
2. **Always confirm dependencies .** Unless you are 100% sure Spack will do what you intend, don't simply run `spack install <spec>` blindly! First, confirm the DAG using `spack spec -I -N <spec>`.

## Getting Started
### Installing Spack
