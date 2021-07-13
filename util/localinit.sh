#!/bin/bash

# Root variables
export NCAR_SPACK_ROOT=%SPACKROOT%
export NCAR_SPACK_ENV_ROOT=%ENVROOT%

# Legacy variables
export INSTALLPATH_ROOT=$NCAR_SPACK_ENV_ROOT/opt
export MODULEPATH_ROOT=$NCAR_SPACK_ENV_ROOT/modules

# Lmod configuration
export LMOD_SYSTEM_NAME=%LMODSYS%
export LMOD_SYSTEM_DEFAULT_MODULES="%DEFMODS%"
export MODULEPATH=`echo $MODULEPATH_ROOT/linux*/Core`

# Add Spack to the user environment
. $NCAR_SPACK_ROOT/share/spack/setup-env.sh

# Load the spack environment to find Lmod scripts
spacktivate $NCAR_SPACK_ENV_ROOT
NCAR_SPACK_LMOD_ROOT=`spack location -i lmod`
despacktivate

# Use shell-specific init
comm=`/bin/ps -p $$ -o cmd= |awk '{print $1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'`
shell=`/bin/basename $comm`

if [ -f $NCAR_SPACK_LMOD_ROOT/lmod/lmod/init/$shell ]; then
    . $NCAR_SPACK_LMOD_ROOT/lmod/lmod/init/$shell
else
    . $NCAR_SPACK_LMOD_ROOT/lmod/lmod/init/sh
fi

unset comm shell

# Load default modules
if [ -z "$__Init_Default_Modules" -o -z "$LD_LIBRARY_PATH" ]; then
  __Init_Default_Modules=1; export __Init_Default_Modules;
  module -q restore 
fi

# Set system default stuff
export PATH=${PATH}:/usr/local/bin:/usr/bin:/sbin:/bin
export MANPATH=${MANPATH}:/usr/local/share/man:/usr/share/man
export INFOPATH=${INFOPATH}:/usr/local/share/info:/usr/share/info

# Set PBS workdir if appropriate
if [ -n $PBS_O_WORKDIR ] && [ -z $NCAR_PBS_JOBINIT ]; then
    if [ -d $PBS_O_WORKDIR ]; then
        cd $PBS_O_WORKDIR
    fi

    export NCAR_PBS_JOBINIT=$PBS_JOBID
fi
