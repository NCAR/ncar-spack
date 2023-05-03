# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other                                                                                 
# Spack Project Developers. See the top-level COPYRIGHT file for details.                                                                                 
#                                                                                                                                                         
# SPDX-License-Identifier: (Apache-2.0 OR MIT)                                                                                                            
from spack.package import *


class PeakMemusage(AutotoolsPackage):
    """This utility is a wrapper around getrusage, which reports peak                                                                                     
    memory use of any executable. It is OpenMP and MPI aware and tries                                                                                    
    to report thread- and task- specific data. Of course, being OpenMP                                                                                    
    shared memory, that report cannot really separate thread-specific                                                                                     
    memory use."""

    homepage = "https://github.com/NCAR/peak_memusage"
    url = "https://github.com/NCAR/peak_memusage/archive/refs/tags/v2.1.0.tar.gz"

    maintainers = ["benkirk"]

    version("3.0.1", sha256="f689452752ba52df41900334dacf8ae7dca657fc39ca5b341aa65a85a5944b12")
    version("3.0.0", sha256="1c2d86be80cc30d2e3e65e249fe1f0b4092c9b5200d61d7b4edd9681ebb251df")
    version("2.1.0", sha256="6d4ea85a9d77144ba7e140e84466fa1e545fc280049d99ec77f763cb8ce82187")

    variant("openmp", default=True, description="Build OpenMP-enabled test suite")
    variant("doc", default=False, description="Build Documentation from source files (requires Doxygen")
    variant("fortran", default=True, description="Build Fortran API")
    variant("nvml", default=True, description="use Nvidia NVML to query GPU properties")
    #variant("mpi", default=False, description="Build MPI-enabled test suite")                                                                            

    depends_on("autoconf", type="build")
    depends_on("automake", type="build")
    depends_on("libtool", type="build")
    depends_on("m4", type="build")
    depends_on("doxygen", type="build", when="+doc")
    depends_on("pkgconfig")


    def autoreconf(self, spec, prefix):
        autoreconf("--install", "--verbose", "--force")

    def configure_args(self):
        args = [ "--disable-mpi" ]
        if "~openmp" in self.spec: args.append("--disable-openmp")
        if "+doc" in self.spec: args.append("--enable-doc")
        if "~fortran" in self.spec: args.append("--disable-fortran")
        if "~nvml" in self.spec: args.append("--disable-nvml")
        return args
