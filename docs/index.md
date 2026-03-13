# ncar-spack

## What is ncar-spack?

`ncar-spack` is a git repository containing cluster configurations for NCAR HPC
software stacks, scripts for deploying and updating cluster configurations, and
a collection of helper scripts designed to facilitate reproducible and
consistent package management.

It is also important to note what this repository is **not**. It is not a fork
of Spack itself - though a cluster *should* use the CSG forks of
[Spack](https://github.com/NCAR/csg-spack-fork) as well as the [builtin package
repository](https://github.com/NCAR/csg-spack-packages). It is also not for
tracking a production cluster deployment. Rather, this repository contains the
recipe and the tools for starting a deployment, which is then tracked in its own
repo!

## Getting Started

To get started, simply clone this repository either as yourself or as *csgteam*.
If you plan to produce a public production cluster deployment, you will need to
run as *csgteam*.

```
git clone git@github.com:NCAR/ncar-spack.git
```

!!! Note
    The above command assumes SSH-key usage, which you will probably want to
    utilize over the HTTPS method as unattended GitHub commands are integral to
    many workflows in these scripts.

#### Vim users: YAML configuration

Since Spack will output YAML lines with two-space indentation, the following Vim settings are recommended:
```
$ cat ~/.vim/after/ftplugin/yaml.vim
setlocal shiftwidth=2
setlocal tabstop=2
```

## Setting up GPG keys

As these workflows rely heavily on Spack [build
caches](https://spack.readthedocs.io/en/latest/binary_caches.html), you will
need to set up GPG keys.

The `./deploy` script will create a new GPG key for you if you do not already
have one. The key is stored in `/glade/work/$USER/operations/spack-keys` by
default.

If you need to create a new GPG key, it will be pushed to the build caches
associated with the deployment (the mirrors in `spack.yaml`) assuming you are
the owner of those mirrors.
