# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *

class Ncarenv(MakefilePackage):
    """ncarenv initializes an environment familiar to users of NCAR supercomputer
    resources. PBS scripts like qinteractive and execcasper are added to the PATH
    and sane defaults are given for values like TMPDIR and OpenMP resources."""

    homepage = "https://arc.ucar.edu/knowledge_base_documentation"
    url      = "/glade/work/csgteam/spack/tarballs/fakepkg-1.0.tar.gz"
    
    maintainers = ['vanderwb']
    
    version('1.3')

    def install(self, spec, prefix):
        make('install', 'PREFIX=%s' % prefix)
