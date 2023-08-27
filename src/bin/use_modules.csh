#!/bin/csh -v
#
#   This script allows you to easily switch to this software stack's
#   build (default) or public modules

set sourced = ($_)

if ("$sourced" == "") then
    echo "Error: I need to be sourced, not executed" > /dev/stderr
    exit 1
endif

# Perform script setup
set my_bin = `ls -l /proc/$$/fd | sed -e 's/^[^/]*//' | grep "/use_modules.csh"`
set my_dir = `dirname $my_bin`

# Hacky way to get bourne-style variables from config file
eval `bash -x $my_dir/../main.cfg |& grep --color=never 'NCAR_SPACK.*=' | sed 's/^+/set/'`

# Check that system matches what we are loading if possible
if ( $?NCAR_HOST ) then
    if ( $NCAR_HOST != $NCAR_SPACK_HOST ) then
        echo "Error: Module stack ($NCAR_SPACK_HOST) does not match identified host ($NCAR_HOST)." > /dev/stderr
        echo "       No changes will be made.\n" > /dev/stderr
        exit 1
    endif
else
    echo "Warning: System is not known (NCAR_HOST not set). Cannot verify stack compatibility." > /dev/stderr
endif

# Store old module tree for reversal
setenv NCAR_SPACK_RESET_SCRIPT `echo $LMOD_CONFIG_DIR | sed 's|\(.*envs/\).*|\1build/bin/use_modules.csh|'`
setenv NCAR_SPACK_RESET_TYPE `echo $LMOD_CONFIG_DIR | sed 's|.*/\([^/]*\)/util|\1|'`

if ( $#argv == 0 || $1 == "build" ) then
    echo "Switching to build module tree:"
    set mod_init = $NCAR_SPACK_ENV_BUILD/util/localinit.csh
else
    echo "Switching to public module tree:"
    set mod_init = $NCAR_SPACK_ENV_PUBLIC/util/localinit.csh
endif

if ( -e $mod_init ) then
    # First we clean the current instance
    if ( `alias module` != "" ) then
        module --force purge

        foreach lmod_var ( `env | grep -e ^LMOD -e ^__LMOD -e ^_ModuleTable | cut -d= -f1` )
            unsetenv $lmod_var
        end

        unsetenv MODULEPATH MODULEPATH_ROOT
    else
        exit 1
    endif

    # Now we use the new modules
    source $mod_init
    echo " -> $MODULEPATH_ROOT\n"
else
    echo "Error: localinit.sh does not exist. No changes will be made.\n" > /dev/stderr
    exit 1
endif

# Define alias to return to default
if ( `alias reset_modules` == "" ) then
    if ( -e $NCAR_SPACK_RESET_SCRIPT ) then
        alias reset_modules "source $NCAR_SPACK_RESET_SCRIPT $NCAR_SPACK_RESET_TYPE"
        echo 'Type "reset_modules" to return to system module stack\n'
    else
        unsetenv NCAR_SPACK_RESET_SCRIPT NCAR_SPACK_RESET_TYPE
    endif
else
    unsetenv NCAR_SPACK_RESET_SCRIPT NCAR_SPACK_RESET_TYPE
    unalias reset_modules
endif
