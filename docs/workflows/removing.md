# Removing Things

Removing packages from a deployment is *typically* easy, though there are some
gotchas as always. For a simple example, let's say that you wanted to remove
hdf5@1.12 from a deployment. Assuming you have already activated the build
environment within a clean bash shell, run:

```bash
spack uninstall --remove --dependents [--all] hdf5@1.12
```

Use the `--all` flag if there are multiple installations of this package and you
wish to remove all of them (but be careful!).

This will remove the package from the build environment, but **will make no
changes to the public environment**. If you wish to propagate this change to
public, you should again run publish:

```bash
bin/publish "Remove HDF5 1.12 installs"
```

## Potential Pain Points

### Removing Externals

There are a few ways to get yourself in trouble when removing things from a
Spack environment. If a package is an "installed" external and you wish to
remove it, make sure you remove the package using the above command before you
remove the external definiton from the `packages:` section of `spack.yaml`, if
you intend to do that at all. Otherwise, Spack may have trouble understanding
what it is actually removing.

### Leftover Dependencies

If you install a package that requires a bunch of dependencies, but then remove
the package without having published the package, those dependencies will likely
be left over in build and can cause concretization differences between build and
public (where the dependencies won't exist) in the future.

Cleaning this up can be really tricky. Spack does offer some "unused package"
garbage collection, but I have not tested this much for fear of breaking
production stacks. It may be useful if properly vetted!
