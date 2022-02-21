#!/bin/tcsh

# Root variables
setenv NCAR_SPACK_ROOT=%SPACKROOT%
setenv NCAR_SPACK_ENV_ROOT=%ENVROOT%

# Legacy variables
setenv INSTALLPATH_ROOT ${NCAR_SPACK_ENV_ROOT}/opt
setenv MODULEPATH_ROOT ${NCAR_SPACK_ENV_ROOT}/modules

# Lmod configuration
setenv LMOD_SYSTEM_NAME %LMODSYS%
setenv LMOD_SYSTEM_DEFAULT_MODULES "%DEFMODS%"
setenv MODULEPATH `echo $MODULEPATH_ROOT/linux*/Core`

# Add spack to the user environment
source ${NCAR_SPACK_ROOT}/share/spack/setup-env.csh

# Load the spack environment to find Lmod scripts
spacktivate $NCAR_SPACK_ENV_ROOT
set NCAR_SPACK_LMOD_ROOT = `spack location -i lmod`
despacktivate

# Add shell settings so Lmod can be used in bash scripts
setenv PROFILEREAD true
setenv BASH_ENV ${NCAR_SPACK_LMOD_ROOT}/lmod/lmod/init/bash 

# Use shell-specific init
set comm = `/bin/ps -p $$ -o cmd= |awk '{print $1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'`
set shell = `/bin/basename $comm`

source /glade/u/apps/dav/opt/lmod/8.1.7/lmod/lmod/init/$shell
unset comm shell

# Load default modules
if ( ! $?__Init_Default_Modules || ! $?LD_LIBRARY_PATH ) then
  setenv __Init_Default_Modules 1
  module -q restore
endif

# Set system default stuff
setenv PATH ${PATH}:/usr/local/bin:/usr/bin:/sbin:/bin

if ( ! ($?MANPATH) ) then
    setenv MANPATH /usr/local/share/man:/usr/share/man
else
    setenv MANPATH ${MANPATH}:/usr/local/share/man:/usr/share/man
endif

if ( ! ($?INFOPATH) ) then
    setenv INFOPATH /usr/local/share/info:/usr/share/info
else
    setenv INFOPATH ${INFOPATH}:/usr/local/share/info:/usr/share/info
endif

# Set PBS workdir if appropriate
if ( $?PBS_O_WORKDIR  && ! $?NCAR_PBS_JOBINIT ) then
    if ( -d $PBS_O_WORKDIR ) then
        cd $PBS_O_WORKDIR
    endif

    setenv NCAR_PBS_JOBINIT $PBS_JOBID
endif
