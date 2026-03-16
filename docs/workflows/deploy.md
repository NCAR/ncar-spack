# Deploying a Cluster From Scratch

This repository contains tooling to deploy new Spack clusters from scratch,
using predefined definitions. The contents of each cluster definition are
described in more detail in the next section.

!!! tip "When to deploy a new **ncarenv**"
    In general, we try to minimize new deployments as much as possible as they
    are disruptive to users. The following conditions are typically the
    motivating factors:

    - Spack has changed in a way that is no longer backward compatible with the
      current deployment, and so new package versions cannot be pulled from the
      upstream.
    - Something has broken in the current deployment and it is not easily
      recoverable.

## Cluster Definitions

Cluster definitions are contained in the `clusters` subdirectory and typically
contain the following components:

```
clusters/
├── casper
│   ├── constraints.cfg - external packages, and packages required to use the system GCC
│   ├── main.cfg        - top-level path, name, and version settings for the cluster deployment
│   ├── packages.cfg    - an inventory of packages to be built upon deployment (and beyond)
│   ├── postprocess     - postprocessing units (scripts) that make non-Spack additions/changes
│   ├── includes        - additional YAML config that can be shared across multiple clusters
│   └── spack.yaml      - the Spack environment template that will become the cluster stack
...
```

Remember, these are simply templates! To generate a cluster deployment from one
of these recipes, simply run the `deploy` script in the top-level directory. For
example:

```
./deploy [--production] casper
```

This command will clone the CSG fork of Spack and check out the branch specified
in the cluster's **main.cfg** (or default to ncar-mods), clone and check out the
desired branch of the CSG fork of
[spack-packages](https://github.com/spack/spack-packages), register GPG keys,
copy cluster settings including constraints and packages to install, set up a
mirror if the specified one does not already exist, and if desired detect
externals, set constraints, and install packages.

The `--production` flag can only be specified when running as *csgteam*. Without
this flag, a *test* deployment will be created at the location configured in the
cluster definition (probably your scratch directory). Doing a test deployment
can be a good way to learn how this all works without breaking things, and is
recommended! :thumbsup:

!!! note
    Keep in mind that changes made after you deploy a cluster will cause
    divergence from the recipe contained in this repo. This is expected, but if
    you wish to propagate those changes to a new version of the deployment, you
    should merge them into the recipe and push the changes to ncar-spack (see
    below)!*

One thing the `deploy.sh` script will not do is publish the new deployment to
users via a public environment. This is by design - you should inspect that
everything ran correctly before publishing.

!!! tip
    If you expect you will need to modify the constraints or packages before
    installing any packages, you can tell `deploy.sh` to skip these steps with
    the `--skip` flag.

## Sharing the Packages Repo

Many packages are shared between the different clusters, so it can make sense to
use the same clone of the CSG spack-packages fork for multiple clusters. For
example, version `25.10` of **derecho**, **casper**, and **common** all use the
clone of the packages repo at `/glade/u/apps/derecho/25.10/packages`.

To set up such sharing, follow these steps:

1. When creating the first deployment that will share a packages repo, have the
   `deploy.sh` script clone the CSG fork of **spack-packages** as normal.
2. For subsequent deployments, use the `--share-packages` argument to
   `deploy.sh` and provide the path to the first deployment's packages repo.
   This will create a symbolic link in this deployment to the original repo.

Generally, this sharing of package repositories only makes sense for deployments
created at the same or very similar times. And it is best practice to keep such
deployments using the same or very similar Spack versions (though deployments
cannot share Spack clones in our setup).

## Creating a Packages Branch for the Deployment

Let's say you use the default *ncar-mods* branch of **csg-spack-packages** for
your builtin packages repo clone. You may want to make changes to the builtin
that are independent of changes made to *ncar-mods* (which may need to be
prepared with updates for future deployments).

As best practice, I like to create a new branch of **csg-spack-packages** to
track changes (e.g., new package pulls from upstream) for this deployment and
any linked deployments. For example, if I deploy a new ncarenv/26.03, I would
create a branch in the packages repo called 26.03 and push to GitHub. This is
also helpful for keeping Derecho and Gust in sync, since they do not share a
filesystem and cannot have linked package repo clones.

## Environment prep: `clean_bash` and `spacktivate`

Before doing anything with a cluster deployment, you should first launch a clean
bash shell that has been scrubbed of personal settings and modules. Since this
step is fundamental to using *ncar-spack*, a script called `clean_bash` is
provided in the csg-spack-fork to do this for you. The script will also
initialize Spack to run in your environment, and change your directory to the
*build* environment.

The script can be found in the `bin` directory of the clone Spack, and it is
also typically configured to run as a shell function when you are *csgteam* (via
**.bashrc** settings).

Once you are in a sanitized bash shell, you can "activate" the *build*
environment. This step is important, because otherwise Spack will make decisions
based on the configuration in the Spack clone settings directory, rather than
our environment settings contained in **spack.yaml**.

```
clean_bash
spacktivate -p .
```

Since `clean_bash` places you in the *build* directory, you can use `.` to
indicate the environment path. The `-p` option provides a nice prompt decorator
indicating the build environment is active.
