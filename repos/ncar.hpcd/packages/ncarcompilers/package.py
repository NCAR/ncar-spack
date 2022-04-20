# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *

class Ncarcompilers(MakefilePackage):
    """ncarcompilers provides a wrapper that sits in front of compiler binaries
    and MPI wrappers in the users PATH. The wrapper inserts header and library
    flags to each build command based on settings inserted into environment
    modules."""

    homepage = "https://github.com/NCAR/ncarcompilers"
    url      = "/glade/work/csgteam/spack/tarballs/ncarcompilers-0.5.2.tar.gz"

    maintainers = ['vanderwb']
    
    version('0.5.2', sha256='f822d4593ca33c5a547ba721aca1ba2a92d064489d32f77c1a2fa288d93af344')

    def install(self, spec, prefix):
        make('install', 'PREFIX=%s' % prefix)
