# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *

class Netcdf(MakefilePackage):
    """NetCDF (network Common Data Form) is a set of software libraries and
    machine-independent data formats that support the creation, access, and
    sharing of array-oriented scientific data. This is a "meta" package that
    includes the C, C++, and Fortran distributions."""

    homepage = "https://www.unidata.ucar.edu/software/netcdf"
    url      = "/glade/work/csgteam/spack/tarballs/netcdf-4.8.1.tar.gz"

    maintainers = ['vanderwb']
    
    version('4.8.1', sha256='d45410057b29764ca2ccef79a21f558f9012fbd6686bdd6cc585bfb277241085')

    # Inherit relevant variants from netcdf-c package
    variant('mpi', default=True,
            description='Enable parallel I/O for netcdf-4')
    variant('parallel-netcdf', default=False,
            description='Enable parallel I/O for classic files')
    variant('hdf4', default=False, description='Enable HDF4 support')
    variant('dap', default=False, description='Enable DAP support')

    depends_on('netcdf-c +mpi', when='+mpi')
    depends_on('netcdf-c ~mpi', when='~mpi')
    depends_on('netcdf-c +dap', when='+dap')
    depends_on('netcdf-c ~dap', when='~dap')
    depends_on('netcdf-c +hdf4', when='+hdf4')
    depends_on('netcdf-c ~hdf4', when='~hdf4')
    depends_on('netcdf-c +parallel-netcdf', when='+parallel-netcdf')
    depends_on('netcdf-c ~parallel-netcdf', when='~parallel-netcdf')
    depends_on('netcdf-fortran')
    depends_on('netcdf-cxx4')

    depends_on('netcdf-c@4.8.1', when='@4.8.1')
    depends_on('netcdf-fortran@4.5.3', when='@4.8.1')
    depends_on('netcdf-cxx4@4.3.1', when='@4.8.1')

    def build(self, spec, prefix):
        ncroot      = self.spec['netcdf-c'].prefix
        nfroot      = self.spec['netcdf-fortran'].prefix
        ncxxroot    = self.spec['netcdf-cxx4'].prefix
        
        make('NC_ROOT=%s' % ncroot, 'NF_ROOT=%s' % nfroot, 'NCXX_ROOT=%s' % ncxxroot)

    def install(self, spec, prefix):
        make('install', 'PREFIX=%s' % prefix)
