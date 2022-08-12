# Make sure module environment is consistent regardless of whether
# we are working on a clean system or not!
if [[ -f /etc/bash.bashrc.local ]]; then
    . /etc/bash.bashrc.local
else
    . /etc/profile.d/z00_modules.sh
    module --force purge
    module load crayenv
fi

# If left set, will contaminate Spack child shells
unset BASH_ENV

# Add common view to the path
export PATH=/glade/u/apps/common/default/opt/bin:$PATH

# Initialize Bash Spack shell integration
. $NCAR_SPACK_STARTUP
