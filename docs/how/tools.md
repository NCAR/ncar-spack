# Adding NCAR-developed User Tools

A number of scripts and utilites have been developed by CSG and HSG members and
need to be present in the base **ncarenv** user environment. While some of these
scripts could be turned into Spack packages, the benefit to doing so is not
worth the effort. Many of these scripts:

- Do not have actual build systems
- Are simply bash or Python with no dependencies
- Are not open-sourced to the public

Since these are not tracked by Spack, we use a postprocessing unit -
**augment-view** to add them to the user environment.

## Configuring the Utilites List

The main piece of user input is the bash associative array `ncar_utils`. This
array maps each utility to a path in the `util_root`. Most of these paths are
actually repositories on GitHub, and so if the utility has not yet been cloned,
the script will do so by default (and also pull any submodules). The general
format of an entry is as follows:

```bash
ncar_utils[executable]=directory
```

The script expects the `executable` to be found in
`$util_root/directory/bin/executable`.

If the utility does not have a corresponding GitHub repository tracking it
(e.g., `gladequota`), you can list in in the `skip_clone` string. Alternatively,
if it is tracked by GitHub but you do not want the script to check out the
latest version automatically, add the directory to the `skip_update` string.

## Location in the Deployment

Most deployments will have configured a *view* - a collection of packages which
are linked into a single prefix. We use the default view as if it were OS
library analogous to `/usr/local`. Since the tools specified here are not
tracked by Spack, we cannot simply add them to the *view* via Spack.

We could add these utilities to the `bin` directory within the Spack *view*
after the view is regenerated, but is error-prone as our changes could be
clobbered by Spack without us knowing. So to avoid such an issue, these utilites
are placed in their own directory within the view:

- **View executables**: `$NCAR_SPACK_ROOT_BASE/view/bin` (produced by Spack)
- **Tool executables**: `$NCAR_SPACK_ROOT_BASE/utils/bin` (produced by
  augment-view)

## Making the Tools Available to Users

The tools added by this script are added to the user environment via the
top-level **ncarenv** module.

```lua
-- Base shell environment packages and utilities
local basepath = "/glade/u/apps/derecho/25.10/opt"
local viewpath = pathJoin(basepath, "view")

...

-- Add base packages utilities to PATHS
prepend_path("PATH", pathJoin(basepath, "utils/bin"))
```
