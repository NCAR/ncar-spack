# This script should be sourced by other bin scripts

if [[ $1 == build ]]; then
    pkg_root=$SPACK_ENV/opt
    module_root=$SPACK_ENV/modules
else
    pkg_root=$NCAR_SPACK_ROOT_PUBLIC/default/spack/opt/spack
    module_root=$NCAR_SPACK_ROOT_PUBLIC/modules
fi

util_path=$SPACK_ENV/util
lmod_location=$(spack location -i lmod 2> /dev/null || true)

if [[ $? != 0 ]]; then
tsecho "lmod is not installed; skipping module generation"
else
mkdir -p $util_path
tsecho "Generating localinit.sh and localinit.csh"

cat > $util_path/localinit.sh << EOF
# Location variables
export INSTALLPATH_ROOT=$pkg_root
export MODULEPATH_ROOT=$module_root

# Lmod configuration
export LMOD_SYSTEM_NAME=$NCAR_SPACK_HOST
export LMOD_SYSTEM_DEFAULT_MODULES="$NCAR_SPACK_DEFAULT_MODULES"
export MODULEPATH=$module_root/environment
export LMOD_PACKAGE_PATH=$util_path
export LMOD_AVAIL_STYLE=grouped:system

# Location of Lmod initialization scripts
LMOD_ROOT=$lmod_location

# Use shell-specific init
comm=\`/bin/ps -p \$$ -o cmd= |awk '{print \$1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'\`
shell=\`/bin/basename \$comm\`

if [ -f \$LMOD_ROOT/lmod/lmod/init/\$shell ]; then
    . \$LMOD_ROOT/lmod/lmod/init/\$shell
else
    . \$LMOD_ROOT/lmod/lmod/init/sh
fi

unset comm shell

# Load default modules
if [ -z "\$__Init_Default_Modules" -o -z "\$LD_LIBRARY_PATH" ]; then
  __Init_Default_Modules=1; export __Init_Default_Modules;
  module -q restore 
fi

# Set system default stuff
export PATH=\${PATH}:/usr/local/bin:/usr/bin:/sbin:/bin
export MANPATH=\${MANPATH}:/usr/local/share/man:/usr/share/man
export INFOPATH=\${INFOPATH}:/usr/local/share/info:/usr/share/info

# Set PBS workdir if appropriate
if [ -n "\$PBS_O_WORKDIR" ] && [ -z "\$NCAR_PBS_JOBINIT" ]; then
    if [ -d "\$PBS_O_WORKDIR" ]; then
        cd \$PBS_O_WORKDIR
    fi

    export NCAR_PBS_JOBINIT=\$PBS_JOBID
fi
EOF

cat > $util_path/localinit.csh << EOF
# Location variables
setenv INSTALLPATH_ROOT $pkg_root
setenv MODULEPATH_ROOT $module_root

# Lmod configuration
setenv LMOD_SYSTEM_NAME $NCAR_SPACK_HOST
setenv LMOD_SYSTEM_DEFAULT_MODULES "$NCAR_SPACK_DEFAULT_MODULES"
setenv MODULEPATH $module_root/environment
setenv LMOD_PACKAGE_PATH $util_path
setenv LMOD_AVAIL_STYLE grouped:system

# Get location of Lmod initialization scripts
setenv LMOD_ROOT $lmod_location

# Add shell settings so Lmod can be used in bash scripts
setenv PROFILEREAD true
setenv BASH_ENV \${LMOD_ROOT}/lmod/lmod/init/bash 

# Use shell-specific init
set comm = \`/bin/ps -p \$$ -o cmd= |awk '{print \$1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'\`
set shell = \`/bin/basename \$comm\`

source \$LMOD_ROOT/lmod/lmod/init/\$shell
unset comm shell

# Load default modules
if ( ! \$?__Init_Default_Modules || ! \$?LD_LIBRARY_PATH ) then
  setenv __Init_Default_Modules 1
  module -q restore
endif

# Set system default stuff
setenv PATH \${PATH}:/usr/local/bin:/usr/bin:/sbin:/bin

if ( ! (\$?MANPATH) ) then
    setenv MANPATH /usr/local/share/man:/usr/share/man
else
    setenv MANPATH \${MANPATH}:/usr/local/share/man:/usr/share/man
endif

if ( ! (\$?INFOPATH) ) then
    setenv INFOPATH /usr/local/share/info:/usr/share/info
else
    setenv INFOPATH \${INFOPATH}:/usr/local/share/info:/usr/share/info
endif

# Set PBS workdir if appropriate
if ( \$?PBS_O_WORKDIR  && ! \$?NCAR_PBS_JOBINIT ) then
    if ( -d \$PBS_O_WORKDIR ) then
        cd \$PBS_O_WORKDIR
    endif

    setenv NCAR_PBS_JOBINIT \$PBS_JOBID
endif
EOF
fi
