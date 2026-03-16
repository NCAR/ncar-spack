# Publishing Changes

Finally, assuming all goes well to this point and testing was a success, you can
publish the changes from the *build* environment to the *public* environment. A
helper script should handle all of this for you.

!!! danger
    You should rarely, if ever, need to manually make changes to the public
    environment!

All published changes get committed and pushed to a GitHub repo (if this is a
production deployment) called `spack-<cluster>` . This repo is publicly visible
and can be used by the community to report bugs and request new packages. Thus,
the publish script expects one argument - a commit message.

```
bin/publish "Installed latest emacs for benkirk in #4"
```

The `publish` script will describe all of the changes it makes, including
package installs, **spack.yaml** changes,  refreshing the module tree, and
postprocessing.

!!! tip
    The less changes to your YAML in a single publish, the more likely it is
    that the changes will successfully be propagated to the public environment.
    These scripts require that Spack concretize public the same way as build, to
    ensure that the binary cache is used.

    **Never install a new package in build and then change
    variants/require/prefer YAML on that package. Also, don't make any changes
    to the `package.py` recipe file for that package until existing changes are
    published.**

    If Spack does decide to concretize the package differently, you can activate
    each environment and run `spack spec -l <spec>` to investigate the source of
    the discrepancy.

## Resuming After an Error

Sometimes you will observe some failure in publishing (e.g., the Spack
concretizer did not solve packages in the same way, causing a cache failure)
that you think you can recover via some fixes in build. You can resume a failed
publish by running:

```bash
bin/publish --resume
```

The previous commit message will be used again, so that does not need to be
specified. The resume flag will allow you to proceed even if changes are already
detected in public, so use this wisely!

## Setting a Deployment Default

There can only be one default deployment per cluster type - the default is used
to initialize the module tree and presents the users with default modules. You
can switch the default to your current deployment by using the `--set-default`
flag to publish:

```bash
bin/publish --set-default "Setting default stack to 26.03"
```

Assuming that this is a production deployment, you will also want to change the
default branch in the associated **spack-[CLUSTER]** GitHub repo.
