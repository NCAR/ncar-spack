# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *
import os

class Ncarcompilers(MakefilePackage):
    """ncarcompilers provides a wrapper that sits in front of compiler binaries
    and MPI wrappers in the users PATH. The wrapper inserts header and library
    flags to each build command based on settings inserted into environment
    modules."""

    homepage = "https://github.com/NCAR/ncarcompilers"
    git      = "https://github.com/NCAR/ncarcompilers.git"
    url      = "https://github.com/NCAR/ncarcompilers/archive/refs/tags/v0.7.1.tar.gz"

    maintainers = ['vanderwb']

    version('main',  branch='main')
    version('1.0.0', sha256='99e08722cbfd7aeeb7dfaec18ae9753f9beeeeddfd37b9dc1b0ea7ed40b249d9')
    version('0.8.0', sha256='f9049ee4d63f52c3c971604b72e41d27a913e87b968b5c7f2cbcb08871affed9')
    version('0.7.2', sha256='f0a1b7a8bd271e2ec41eebdbb2bf2d0ae91f8e197dba06a9c7b67f671f41e819')
    version('0.7.1', sha256='88f23f89841b6e49a44b66d3a6afb3d8d817f51103cc07f3c8c48864a0215405')

    def setup_build_environment(self, env):
        # Make sure traditional intel compilers are in the path too
        with when('%oneapi'):
            env.append_path("PATH", join_path(ancestor(self.compiler.cc), 'intel64'))

    def build(self, spec, prefix):
        make()
        make('mpi')
    
    def install(self, spec, prefix):
        make('install', 'PREFIX={}'.format(prefix))

    def setup_run_environment(self, env):
        """Adds environment variables to the generated module file.
        from setting CC/CXX/F77/FC
        """

        env.set("CC", os.path.basename(self.compiler.cc))
        env.set("CXX", os.path.basename(self.compiler.cxx))
        env.set("F77", os.path.basename(self.compiler.f77))
        env.set("FC", os.path.basename(self.compiler.fc))
        env.set("NCAR_WRAPPER_MPI_PATH", join_path(self.prefix.bin, 'mpi'))
