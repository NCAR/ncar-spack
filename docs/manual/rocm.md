# Installing ROCm

ROCm is a pain to install correctly. In theory, all of the ROCm components are
installable via Spack. However, this is a huge pain to manage as the components
are very interconnected and seem to have been designed to be in a single path.
Thus, you will need to ensure some reasonable subset of modules are available
and concurrently loaded to get the proper behavior. If you want to see my
attempt at it, look at [this older ROCm cluster
definition](https://github.com/NCAR/ncar-spack/tree/0eefd92b39bd8b587cb22b01b0bdc30f628fc9d2/clusters/casper-amd).

Fortunately, in ROCm versions >= 6.4.x, AMD has provided a *runfile* installer
that allows us to install the unified ROCm package into a custom space with user
privileges. Before this version, the unified package can only be installed via
RPM, and we do not want too much of this massive kit in our compute image.

The unified toolkit can be installed using the script in `etc/manual`. The
modifications you may need to make should all be in the **USER CONFIG** section
of the file.

!!! warning
    ROCm has very specific OS compatibility that must be followed. For example,
    the [latest version](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html#supported-operating-systems)
    as of March 2026 only supports SUSE SP7.

!!! warning
    ROCm also has strict GLIBCXX symbol requirements. For example, ROCm 6.4.3
    requires libstdc++ from GCC 14 or newer, and so we define a "compat" version
    of GCC that is installed into the deployment, which may be newer than the
    "core" version of GCC. This requirement is very different from CUDA, for
    which GCC support often lags releases and limits us to older versions
    (unless you use the `+allow-unsupported-compilers` variant to CUDA).

## Adding to Spack

All components relevant to Spack can then be added as externals via the
`constraints.cfg` file. There is one section that is devoted to importing all
externals from a specific ROCm toolkit install.

Once these packages are added to your deployment as externals, you can install
the following packages explicitly:

- rocm-core
- llvm-amdgpu
- rocm-openmp-extras

In order to present the user with a single module for the entire toolkit, we use
**rocm-core** as a proxy for this, and project its module to the name **rocm**:

```
modules:
  default:
    lmod:
      projections:
        rocm-core: rocm/{version}
      rocm-core:
        template: ncar_wrapper_hip.lua
      ...
```

The module template allows us to wrap hipcc with the **ncarcompilers** wrapper,
making it easier for users to link their ROCm-using programs.

The **llvm-amdgpu** and **rocm-openmp-extras** packages are a real mess. The
former provides the C and C++ compilers that build HIP code. Meanwhile, the
rocm-openmp-extras provides OpenMP 5 support for ROCm devices, including Fortran
support. When installed via Spack, the latter package actually modifies the
prefix of the former package, which is problematic and makes using binary caches
difficult. See [here](https://github.com/spack/spack/pull/49026) for discussion.

!!! info
    ROCm 7 includes the new flang with LLVM 20, and so the whole aforementioned
    issue may be better. See
    [here](https://github.com/spack/spack-packages/pull/1655#issuecomment-3377938830)
    for discussion. That said, ROCm 7 is not supported on our SUSE version, so
    testing of this will need to wait until we are updated.

Unfortunately, in ROCm 6.4.3, we actually need to use these Spack builds even
though the two packages mentioned are included in the toolkit. This is because
Spack's compiler wrappers will not handle the Fortran components in the toolkit
version well, and you will get errors if trying to use GCC as a "host" compiler
while using the ROCm LLVM as a "device" compiler. This may not be the optimal
way to support ROCm, but given that the included flang is immature, it seems
best for now.

No other components (as externals) need to be explicitly installed. We have
provided them to Spack because many of them will serve as dependencies for other
packages (e.g., rocblas, rocrand, comgr, etc).

## Testing ROCm

A good initial test is to load your stack and simply run `amd-smi` and ensure
that devices are reporting properly. For MPI, **osu-micro-benchmarks** and then
**fasteddy** are good test cases.

## Auto-selection of Stacks

On Casper, we currently have two versions of the stack - the default which
provides NVIDIA GPU support and then the `-rocm` versions which provide AMD GPU
support.

To make things easier for users, we have an "entry" script that selects the
correct stack based on information in your login environment. As the CUDA stack
(the **casper** cluster definition) is the default, this entry script is
actually created by a postprocessing unit in that cluster. It relies on the
`lspci` utility being available in the compute image.

Here is the bash version for reference:

```bash
if /sbin/lspci -k |& grep -q "Kernel driver in use: amdgpu"; then
    export GPU_ARCH_TYPE=rocm
    . $rocm_path/localinit.sh
else
    export GPU_ARCH_TYPE=cuda
    . $util_path/localinit.sh
fi
```

This script is then used as the `localinit.[c]sh` script called by HSG's
`/etc/profile.d/z00_modules.[c]sh` scripts, and the "real" localinit scripts are
called depending on which GPU technology is available. If the user is not on a
node with GPUs, the default stack which includes CUDA is loaded.

Of course, this simply provides the default environment. Users can switch
bewteen the cuda and rocm stacks by switching their **ncarenv** module.
