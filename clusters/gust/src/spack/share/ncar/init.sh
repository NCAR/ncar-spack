# The bashrc.local script will *always* be sourced for interactive
# bash shells, but not for script shells. Here we ensure consistent
# behavior.
if [[ $- != *i* ]]; then
    if [[ -f /etc/bash.bashrc.local ]]; then
        . /etc/bash.bashrc.local
    fi
fi

# If modules are present (Cray), make sure none are loaded
# (Spack will do this for properly configured compilers/externals)
if [[ -n $(type -t module) ]]; then
    module purge &> /dev/null
fi

# If left set, will contaminate Spack child shells
unset BASH_ENV

# Add unzip to path (to get around Spack luarocks bug)
export PATH=/glade/work/vanderwb/nwsc3/crayenv-22.02/test/bin:$PATH

# Initialize Bash Spack shell integration
. $NCAR_SPACK_STARTUP
