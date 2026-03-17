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
    many workflows in these scripts. See below for pointers on setting this up.

#### GitHub SSH keys

These scripts perform many pulls, pushes, and queries to- and from- GitHub, and
so we rely on the "ssh" form of git remotes to avoid repetitive authentications.
As a result, you should ensure that you have your GitHub SSH key configured for
personal use of this repo on each system of interest.

- [GitHub SSH Key Instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

When you are running as **csgteam**, you will need to set up the SSH key sudo
mechanism. First, this logic should already be in csgteam's `~/.bashrc` file:

```bash
# Configure Git to work as sudo-user
if [[ -n $SUDO_USER ]]; then
    my_name=$(getent passwd $SUDO_USER | awk -F[:,] '{print $5}')
    export GIT_SSH=/glade/u/home/csgteam/.ssh/gitwrap.ssh
    export {GIT_AUTHOR_NAME,GIT_COMMITTER_NAME}=$my_name
    export {GIT_AUTHOR_EMAIL,GIT_COMMITTER_EMAIL}=${SUDO_USER}@ucar.edu
fi
```

The `gitwrap.ssh` script looks like this:

```bash
#!/bin/bash

/usr/bin/ssh -i ~/.ssh/id_rsa.${SUDO_USER} $*
```

So for this to work for you, you'll simply need to add an SSH key to csgteam's
`~/.ssh` directory and append your username to the end of the `id.rsa` file.

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

## Setting up S3 Credentials

AWS S3 credentials should be configured for access to Boreas so that Spack build
caches can be accessed. These credentials are stored in a file in your/csgteam's
home directory - `~/.aws/credentials`. The credential will look as follows:

```
[boreas]
service_name = s3
aws_access_key_id = 
aws_secret_access_key = 
endpoint_url = https://boreas.hpc.ucar.edu:6443
```

If you cannot find an existing listing of the key and secret, reach out to HSG.

## Useful Resources

The following resources are essential for understanding how to use Spack well:

1. [Spack Documentation](https://spack.readthedocs.io/en/latest/)
2. [Spack Package Search](https://packages.spack.io/)
3. [Spack Slack](https://slack.spack.io/)

Remember that Spack is now split into two repositories:

1. [Spack the program](https://github.com/spack/spack)
2. [Spack's *builtin* package
   repository](https://github.com/spack/spack-packages)

Changes to Spack's functionlity come from the main Spack repo, whereas package
recipe changes and additions come from the `builtin` package repo.

Finally, remember that these cluster definitions contained in this repo use CSG
forks of both Spack itself and the builtin packages repository. These can be
found here:

1. [CSG Spack fork](https://github.com/NCAR/csg-spack-fork)
2. [CSG Spack builtin packages fork](https://github.com/NCAR/csg-spack-packages)
