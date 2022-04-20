# Root variables
export LMOD_SPACK_ROOT=%SPACKROOT%
export LMOD_SPACK_ENV_ROOT=%ENVROOT%

# Legacy variables
export INSTALLPATH_ROOT=$LMOD_SPACK_ENV_ROOT/opt
export MODULEPATH_ROOT=$LMOD_SPACK_ENV_ROOT/modules

# Lmod configuration
export LMOD_SYSTEM_NAME=%LMODSYS%
export LMOD_SYSTEM_DEFAULT_MODULES="%DEFMODS%"
export MODULEPATH=`echo $MODULEPATH_ROOT/Core`

# Get location of Lmod initialization scripts
LMOD_ROOT=$(. $LMOD_SPACK_ROOT/share/spack/setup-env.sh; spack env activate $LMOD_SPACK_ENV_ROOT; spack location -i lmod)

# Use shell-specific init
comm=`/bin/ps -p $$ -o cmd= |awk '{print $1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'`
shell=`/bin/basename $comm`

if [ -f $LMOD_ROOT/lmod/lmod/init/$shell ]; then
    . $LMOD_ROOT/lmod/lmod/init/$shell
else
    . $LMOD_ROOT/lmod/lmod/init/sh
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
