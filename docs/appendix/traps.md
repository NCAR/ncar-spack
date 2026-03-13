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

**This means you should either manually add the `cuda` external or fix the
version number after automatic detection!**

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
