# Updating Cluster Recipes

Once a cluster is deployed, the YAML, postprocessing and configuration files are
likely to become substantially different from the original cluster recipe over
time. When it is time to deploy a new version of that cluster, you will probably
want to sync up the production changes to the recipe.

This repo contains a helper - `util/find_changes`, that you can use to identify
files that have been changed in a deployment with the cluster recipe as the
reference. This script will also check for changes to scripts, so that new
functionality added or bugs fixed will also be ported back to this repo.

## Cleaning up the YAML Files

Before you run `find_changes`, you will want to scrub the deployment YAML files
of any settings that don't need to be kept in the template - i.e. deployment
paths, mirror locations, installed specs, etc. In the deployment itself, there
is a helper script to create YAML templates based off of the build environment's
`spack.yaml` file and any additional YAML in the `include` directory. Simply run
the following:

```bash
cd $NCAR_SPACK_ENV_BUILD
bin/templatize_yaml
```

This will create cleaned-up versions of YAML files and place them into
`$NCAR_SPACK_ENV_BUILD/templates/yaml`.

!!! bug
    Actions on YAML files can sometimes cause comment lines to be lost. Despite
    multiple investigations into the **ruamel** package, I have not been able to
    eliminate this bug. Just keep in mind that you may need to restore comments
    that have been lost in the templates.
    
## Backporting Changes to the Recipe

You can now run the `find_changes` script as follows:

```bash
ncar-spack/util/find_changes [-b] [-d] BUILD_ROOT
```

If you use the `-b` flag, you will only see files that have changes. If you use
the `-d` flag, a diff will be shown for each file that has been changed.

In any case, keep in mind that the file in the cluster recipe may in fact have
changes as well that you wish to keep. Don't simply copy the deployed version
into the recipe - think of it as a merge.

!!! tip
    The `find_changes` script will also check the deployment's `main.cfg` file.
    In most cases, the changes here are not ones you would want to backport and
    can be ignored, but occasionally there is a setting you might wish to
    preserve in the recipe, and so it is included.
