# Hiding Packages and Modules

Sometimes it can make sense to create a module but then hide it from the list
shown by `module available`. For instance, perhaps a module will only exist
temporarily, needs to be tested by a large group but may have known limitations,
or it uses a license that is only available to a limited segment of the user
base.

The clusters have a postprocessing unit called **hidelist** that allows you to
hide modules that match given search strings. There are currently two methods
for specifying the modules to hide:

- `hide_list` - list paths to modules relative to the module deployment root to
  hide if found
- `find_list` - uses find to search for any file in the module tree that matches
  the given string, regardless of which directory or depth it occurs

## Hide Mechanism

Lmod allows you to hide modules using a given `hidden-modules` file. The file
uses a very simple format, with each module listed per line. For example, we
hide the `crayenv` top-level modules using this file:

```
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/22.12.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/25.03.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/23.09.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/24.03.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/23.12.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/23.03.lua
hide-modulefile /glade/u/apps/derecho/modules/environment/crayenv/23.02.lua
```

Unfortunately this file (as of March 2026) does not allow for operations such as
globbing, so keeping these files up to date for older deployments can be
challenging.

The `hidden-modules` file is specified to Lmod via the following environment
variable set in **ncarenv**:

```lua
pushenv("LMOD_MODULERCFILE", "/glade/u/apps/derecho/25.10/envs/public/util/hidden-modules")
```

!!! tip
    The `pushenv` method in Lmod is a way to override and environment variable
    only while the module is loaded. When the module is unloaded, any previously
    set value is restored. This can be quite handy over `setenv`, which leaves
    the variable unset when the module is unloaded, regardless of its previous
    value.

## Build-env Only Packages

Occasionally, during testing, you will want to install a package into the
**build** environment but for whatever reason you do not want it to end up in
the **public** environment. You could hide the module, but another approach is
to prevent it from being installed into **public** by the `publish` script. To
do this, use the following configuration setting in `packages.cfg` to mark
packages:

```
# DEBUG stack
mdep: compilers=nvhpc@25.9 mpis=cray-mpich@8.1.32 source=install publish=no
    parallel-netcdf@1.14.1 cppflags=-g
    netcdf+mpi+debug@4.9.3
    parallelio+logging@2.6.8 %TC% ^parallel-netcdf cppflags=-g ^netcdf-c +logging ^netcdf-fortran cppflags=-g
    esmf+mpi+debug@8.9.1 %TC% ^hdf5 %CMP% ^parallelio+logging ^parallel-netcdf cppflags=-g ^netcdf-c +logging ^netcdf-fortran cppflags=-g
```

In the example, all four debug packages are kept in the **build** environment
only by specifying `publish=no`. If, later, you wanted to change this, you could
remove `publish=no` from the section and run `bin/install_packages` again.
