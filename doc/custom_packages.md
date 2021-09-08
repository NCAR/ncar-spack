# Creating Custom Packages
For the most part, you can simply follow the detailed [Custom Packages](https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html) tutorial from the Spack documentation. A few modifications will need to be made to make it work in our environments - particularly,, it is recommended that you add the *mpileaks* package to your own custom repository, rather than putting it in the `tutorial` repository within $SPACK_ROOT or our `ncar.hpcd` repository.

### NCAR package considerations
When you create a real package that you intend to use for a production installation, you should add that package to `repos/ncar.hpcd/packages` so that it can be found by NCAR environments.

Note that if you supersede a `builtin` package with a custom version, it will produce a different hash and thus be an independent install. Consider the implications of this change carefully - **you could inadvertently build alternate versions of a lot of packages!** This side-effect is especially worrisome for provider packages like *mpi* and of course compiler packages.

### Missing build dependencies
Scenario: During development, you may have a version of your package that fails to build. In response, you add a dependency and some language that should fix the issue. But when you run `spack install <pkg-spec>` the new dependency is not found.

If this happens, it's likely that Spack is still trying to build the older version of your package spec when you run the new install. Since the DAG has changed from the new dependency, Spack considers them separate installs and will attempt to complete both upon running the install subcommand. The solution here is to first remove the spec from your environment, and then run install again:
```
spack rm <pkg-spec>
spack install <pkg-spec>
```
