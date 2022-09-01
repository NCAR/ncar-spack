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
    url      = "/glade/work/csgteam/spack/tarballs/ncarcompilers-0.6.0.tar.gz"

    maintainers = ['vanderwb']

    version('0.6.2', sha256='657648b82c21f5588ec6efb34bae910f797bbcd54a46b79b75a6cfb34b7e8ea5')
    version('0.6.1', sha256='fc1f5e3bcbb9575d105560ee070b228f478fa3bffc6b30bac27cb93e83ec7d18')
    version('0.6.0', sha256='97b625bc9014a4d7b670b5d51d542f4a04819072d59676f29a2dd7f13c119963')
    version('0.5.2', sha256='a5874785a867e929835d303cef3b1e1578db4a9bd48b41e729d68dbe6e917201')

    def setup_build_environment(self, env):
        # Make sure traditional intel compilers are in the path too
        with when('%oneapi'):
            env.append_path("PATH", join_path(ancestor(self.compiler.cc), 'intel64'))

    def install(self, spec, prefix):
        make('install', 'PREFIX=%s' % prefix)
    
    def setup_run_environment(self, env):
        """Adds environment variables to the generated module file.
        from setting CC/CXX/F77/FC
        """

        env.set("CC", os.path.basename(self.compiler.cc))
        env.set("CXX", os.path.basename(self.compiler.cxx))
        env.set("F77", os.path.basename(self.compiler.f77))
        env.set("FC", os.path.basename(self.compiler.fc))
