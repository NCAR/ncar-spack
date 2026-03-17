# Debugging Spack Issues

Inevitably, you will run into issues when performing operations using Spack.
There are likely many ways to debug various problems, but the follow tips are
generally applicable to many situations:

1. The main spack command has a debug flag `-d`, which provides a lot of
   information and can be repeated for higher verbosity.
2. Running `spack spec -lN` and `spack find -lvN` can reveal a lot of
   information.
3. Spec and install logs are kept in `$SPACK_ENV/logs`. Once the install has
   finished, shortcuts are created to the latest logs as `latest.specs` and
   `latest.installs`.

## Debugging Package Installs

When you install a package with Spack, Spack should provide some information
about the temporary directory in which build commands were run if an error was
encountered with a build command. For example:

```
2026-03-15T22:56:22 - Installing spec spherepack@3.2 %gcc-152 ...
2026-03-15T22:56:26 -  >> active config = ([register]="" [cache]="yes" [trust]="no" [access]="" [source]="no" [maxjobs]="" ) ...
 [1:gust1] ==> spherepack: Executing phase: 'install'
 [1:gust1] ==> Error: ProcessError: Command exited with status 2:
 [1:gust1] ==> Installing spherepack-3.2-zqwsdheypanztr5pdmvwulzfppy65vps [65/589]
 [1:gust1]   /local_scratch/spack/gust/26.03/builds/csgteam/spack-stage-spherepack-3.2-zqwsdheypanztr5pdmvwulzfppy65vps/spack-build-out.txt
 ...
```

Other useful files are stored in that directory, including a dump of the
environment used at build time. Note that Spack uses it's own compiler wrapper
for builds, so values of CC/FC and the like may not match expectations.

Once an installation completes, the build logs are moved out of the temporary
staging directory into a hidden directory within the install prefix (e.g.,
`/path/to/spack/env/opt/package/.spack/`).

## Debugging in the Compilation Environment

After a build fails, it can be useful to recreate the build/compile environment
and run some of the build commands interactively. Spack has a command to do
this:

```bash
spack build-env <spec> -- /bin/bash
```
