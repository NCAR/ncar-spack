# Make sure module environment is consistent regardless of whether
# we are working on a clean system or not!
if [[ -f /etc/bash.bashrc.local ]]; then
    . /etc/bash.bashrc.local
elif [[ -f /etc/profile.d/z00_modules.sh ]]; then
    . /etc/profile.d/z00_modules.sh 2> /dev/null

    if module --force purge >& /dev/null; then
        cray_module=$(module -t --show-hidden av crayenv |& tail -n1)

        if [[ -n $cray_module ]]; then
            module load $cray_module
        fi
    fi
fi

# If left set, will contaminate Spack child shells
unset BASH_ENV

# Config to use non-system core compiler
CORE_GCC_ROOT=

if [[ -n $CORE_GCC_ROOT ]]; then
    export PATH=$CORE_GCC_ROOT/bin:$PATH
    export LIBRARY_PATH=$CORE_GCC_ROOT/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}
    export LD_LIBRARY_PATH=$CORE_GCC_ROOT/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
fi

# Config to use specific Python with Spack
NCAR_SPACK_PYTHON_ROOT=

if [[ -e $NCAR_SPACK_PYTHON_ROOT/bin/python ]]; then
    export SPACK_PYTHON=$NCAR_SPACK_PYTHON_ROOT/bin/python
fi

# Initialize Bash Spack shell integration
. $NCAR_SPACK_STARTUP
