# Design Choices

Many things can be accomplished in multiple ways using Spack, but from
experience some methods are fraught with issues for the NCAR HPC module tree. As
a reminder, here are basic design objectives we've tried to adhere to in order
to match user expectations:

1. Software stacks evolve over time, with new versions of packages being added
   as they become available.
2. Much of the software stack should be roughly the same on both the HPC system
   and the analysis system.

## Reducing Package Duplication

Certain packages do not need to be installed uniquely on both systems - most
notably vendor software. Many of these packages are indeed quite bloated, so
having multiple installs is wasteful of space as well (e.g.,
`intel-oneapi-compilers` and `nvhpc`).

To avoid duplication, we use a third cluster called **common**, which contains
these packages. The packages are then exposed to the production clusters (i.e.
**derecho** and **casper**) as externals, which are defined with the help of the
`add_constraints` script and the `constraints.cfg` file.

In theory, these packages could be installed into one of the cluster deployments
and then exposed to the other cluster, removing the need for **common**, but
this is not advisable for reasons described in the next section.

!!! info "Historical Information"
    The original reason for the **common** environment was to constrain how the
    concretizer would build packages by extensive use of externals. In old
    versions of Spack, the `require:` specifier was not available. By putting
    commonly-used dependencies into **common**, this mostly prevented Spack from
    wildly choosing to build new versions and use undesired compilers.
    Fortunately, this problem can be mitigated in cleaner ways now.

### Externals vs Upstream Packages

In theory, the **common** environment could be exposed in one of two ways to
cluster deployments:

1. Add packages from common to clusters as *externals*
2. Add the entire common deployment to each cluster as an upstream (or chained)
   installation of Spack

The second option has many advantages, but unfortunately is not workable at
present because Spack considers `sles` and `opensuse` to be distinct operating
systems, so if used as an upstream, the packages in **common** will only be used
on the system with the matching OS.

!!! note
    The Spack developers claim they want to eliminate the OS concept entirely
    from specs. If this happens, or if `os_compatible` can be made to work, the
    upstream approach would be recommended.

### The Downside of Externals

The major downside of externals is that they don't have any dependency
information. As a result, if you try to use source-built packages from another
Spack installation as externals in your deployment, you may get build errors
since Spack does not know what dependencies it needs to link in at compile time
for the external you are using. This can affect user usage as well as module
`depends_on` settings can be missing.

This is why we focus on vendor software for use as externals from **common**.
The one exception currently is `gcc`. As of v1.1, Spack's compiler support is
still in flux and if you install a compiler into the environment, it can be hard
to track and customize via YAML how the compiler is defined. Using externals to
bring in compilers from the **common** deployment helps constrain behavior.

## Non-buildable Externals

When you add an external, you can specify whether or not Spack can also build a
non-external version of the package using `buildable: [true/false]`. Most of the
time, we prefer non-buildable externals as this has the advantageous property of
constraining the concretizer behavior. Otherwise, it may decide to ignore your
external and reinstall a package, which is time consuming and annoying if the
package is something like `nvhpc`.

## User Packages in the View

On prior systems, we had HSG install many low-level packages into the image
directly using RPMs. With Derecho, HSG wanted to slim down the image and so many
fundamental packages (e.g., `tmux`, `imagemagick`, `parallel`) needed to be
installed with Spack by CSG instead.

These packages could all be modules, but it was decided instead to incorporate
them into a single directory using Spack's environment *view* capability, which
creates links (or if desired copies) of all requested package libraries,
binaries, man pages, etc in a single prefix. Essentially, we use it to mimic
what would traditionally go in `/usr/local` via RPM installs. The view is then
added to to the user environment via `ncarenv`, so it should be always available
for the majority of users.

The reasons for this choice vs using modules exclusively is as follows:

1. A large module list is visually intimidating
2. It imposes a burden on users to know what they might want, whereas with the
   view we can curate the "basic" experience
3. Since many packages depend on libraries like `zlib`, the `depends_on`
   conflicts in module loads could be severe
4. A simpler stack improves Lmod performance
