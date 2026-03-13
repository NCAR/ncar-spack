# Traps and Potential Pitfalls

While it has gotten better, there are many "foot-guns" in Spack. Here we list
some of the commonly-encountered ones when using `ncar-spack`.

## Incorrect External Versions

Some packages have logic that allows for automatic detection using `spack
external find`. While this is very nice most of the time, it can produce
unexpected results. The `cuda` package suffers from this problem. Since it is
installed in the **common** deployment, it gets added to cluster deployments as
an external.

For whatever reason, the version detected by Spack can differ from the version
Spack claimed to install in the **common** environment, and if the external is
set to `buildable: false`, you'll probably get an error when you try to install
`cuda` using the version you think you want. For example:

| Deployment | CUDA version |
| ---------- | ------------ |
| Common     | 12.9.1       |
| Derecho    | 12.9.86      |

And then the resulting error:

```bash
$ spack install --add cuda@12.9.1
...
==> Error: failed to concretize `cuda@12.9.1 %[when='%c'] c=gcc@12.5.0 %[when='%cxx'] cxx=gcc@12.5.0 %[when='%fortran'] fortran=gcc@12.5.0 %[when='%blas'] blas=openblas@0.3.30 %[when='%lapack'] lapack=openblas@0.3.30` for the following reasons:
     1. Cannot build cuda, since it is configured `buildable:false` and no externals satisfy the request
```

As a result, you can use the `detection=manual` attribute in `constraints.cfg`
to tell the script to manually add the external. The version will be
auto-detected from the prefix, rather than via querying a binary or whatever
logic is used by the package.

## External Variants and Require

Similarly, you can run into trouble with externals if you require a package to
use a specific variant, but then provide that package via an external. The
external needs to specify that variant in its spec, otherwise the concretizer
will give the following error:

```bash
==> [2026-03-13-13:58:06.754749, 809817] Error: failed to concretize `cuda@12.9.1` for the following reasons:
     1. Cannot build cuda, since it is configured `buildable:false` and no externals satisfy the request
```

So again, the `cuda` package provides an illustrative example. Here, we are
constraining cuda via the following YAML:

```yaml
  packages:
    cuda:
      require:
      - +allow-unsupported-compilers
```

We can fix this by specifying the variant in our spec name in the external. This
can again be done using an attribute in `constraints.cfg`:

```
externals: gpu=cuda buildable=no detection=manual variants=+allow-unsupported-compilers {
    $COMMON_ROOT/spack/opt/spack/[cuda/*]/*
}
```

## Missing SHA Concretization Failures

In a `package.py` file, versions are specified as follows:

```python
    version("2.6.6", sha256="e32e018a521d38c9424940c7cfa7e9b1931b605f3511ee7ab3a718b69faeeb04")
    version("2.6.5", sha256="6ae51aa3f76e597a3a840a292ae14eca21359b1a4ea75e476a93aa2088c0677a")
    version("2.6.4", sha256="cba53e4ca62ff76195b6f76374fbd1530fba18649c975ae2628ddec7fe55fb31")
    version("2.6.3", sha256="a483eb1cfa88ace8c6266e02741771c984e846dd732e86c72c3fdeae942b4299")
```

In theory, you can install a package without a defined SHA simply by specifying it:

```bash
$ spack install --add parallelio@2.6.7
```

However, oddly, Spack will sometimes fail to concretize such a spec with
nonsensical concretization errors that can be hard to diagnose.

!!! tip
    If you need to install a new version, take the couple of minutes and find
    out the SHA of the version, and then add it to the `package.py` of the
    package before trying to install anything!

## Immutable Prefix Projections

Spack allows you to specify install prefix "projections" in the `spack.yaml`.
Here is an example from the v1.0 cluster templates:

```yaml
      projections:
        c: '{name}/{version}/{hash:4}'
        ^c: '{name}/{version}/{compiler.name}/{compiler.version}/{hash:4}'
        ^cxx: '{name}/{version}/{compiler.name}/{compiler.version}/{hash:4}'
        ^fortran: '{name}/{version}/{compiler.name}/{compiler.version}/{hash:4}'
        ^mpi: '{name}/{version}/{^mpi.name}/{^mpi.version}/{compiler.name}/{compiler.version}/{hash:4}'
        all: '{name}/{version}/{hash:4}'
```

Once you have installed anything into the deployment, it is best to consider
this configuration immutable. If you change the prefix projection, Spack will no
longer be able to find packages at the path it thinks it should from its
database, and you will likely have a broken deployment!

## Random Package Failures

A couple of packages have builds which just sometimes fail. The is observed most
often with the `qt` package, which is unfortunate as it takes a **long** time to
build.

For such packages, you may see better results if you limit the build to a low
number of build jobs - say 4-8 instead of 8+. Of course, the build time will
increase. Otherwise, your best bet is to just try repetition. If I encounter a
`qt` build failure, I will often run `install_packages` the next time as
follows:

```bash
$ bin/install_packages || bin/install_packages || bin/install_packages
```

That way, it will try three times and I don't have to keep a close eye on
things.

## Clobbering Prefer and Require Sections

Unfortunately, as of Spack v1.1, there is no way to inherit settings from the
`require:` and `prefer:` sections of the `all:` package while also customizing a
particular package. Any general customizations from `all:` will be clobbered in
the equivalent section.

An example can help illustrate:

```yaml
packages:
  all:
    require:
    - spec: cuda_arch=80
      when: ^cuda
  openmpi:
    require:
    - +cuda
    - fabrics=cma,ofi
```

Ideally, this would force openmpi to use the requested fabrics, enable cuda, and
use cc80 for the CUDA architecture. But the `require:` section for openmpi
clobbers the section from `all:`, and so you would need to repeat the
`cuda_arch` setting for openmpi.

One potential workaround is to intermix `require` and `prefer`. For example:

```yaml
packages:
  all:
    require:
    - spec: cuda_arch=80
      when: ^cuda
  openmpi:
    prefer:
    - +cuda
    - fabrics=cma,ofi
```

You could also use `variants:`, but this is merely a suggestion to the
concretizer and probably shouldn't be trusted for anything important!

## Pulling Package Updates

If you need to get new versions of package recipes from the upstream
[spack-packages]() GitHub repo, it is highly recommended to **only** pull what
you need, and not to update the entire clone. For example, if a new version of
NetCDF came out, this would be advised:

```bash
$ cd /glade/u/apps/derecho/default/packages/repos/spack_repo/builtin/packages
$ git fetch upstream develop
$ git checkout upstream/develop -- netcdf-c
```

If you pull all changes, it is much more likely that a package you didn't intend
to modify has had its variants changed, or worse, uses a new package API feature
that Spack doesn't support and causes Spack to error when running commands.
