# This script should be sourced by other bin scripts

if [[ $1 == build ]]; then
    pkg_root=$SPACK_ENV/opt
    module_root=$SPACK_ENV/modules
else
    pkg_root=$NCAR_SPACK_ROOT_PUBLIC/default/spack/opt/spack
    module_root=$NCAR_SPACK_ROOT_PUBLIC/modules
fi

util_path=$SPACK_ENV/util

if [[ ${NCAR_SPACK_LMOD_VERSION:-latest} != latest ]]; then
    lmod_location=$(spack location -i lmod@$NCAR_SPACK_LMOD_VERSION 2> /dev/null || true)
else
    lmod_latest=$(spack find --format '{hash}' lmod 2> /dev/null | tail -n 1)

    if [[ -n $lmod_latest ]]; then
        lmod_location=$(spack location -i /$lmod_latest 2> /dev/null || true)
    fi
fi

if [[ -z $lmod_location ]]; then
tsecho "lmod (${NCAR_SPACK_LMOD_VERSION:-latest}) not installed; skipping module generation"
else
mkdir -p $util_path
tsecho "Generating localinit.sh and localinit.csh"
tm_file=$SPACK_ENV/.tempinit

cat > $tm_file << EOF
# Location variables
export INSTALLPATH_ROOT=$pkg_root
export MODULEPATH_ROOT=$module_root

# Lmod configuration
export LMOD_SYSTEM_NAME=$NCAR_SPACK_HOST
export LMOD_SYSTEM_DEFAULT_MODULES="$NCAR_SPACK_DEFMODS_NCAR"

case "\$MODULEPATH" in
    *"\${MODULEPATH_ROOT}"*)
        ;;
    *)
        export MODULEPATH=\$MODULEPATH_ROOT/environment
        ;;
esac

# Set defaults for Lmod behavior configuration
export LMOD_PACKAGE_PATH=$util_path
export LMOD_CONFIG_DIR=$util_path
export LMOD_AVAIL_STYLE=grouped:system

# Location of Lmod initialization scripts
export LMOD_ROOT=$lmod_location

# Use shell-specific init
comm=\`/bin/ps -p \$$ -o cmd= |awk '{print \$1}'|sed -e 's/-sh/csh/' -e 's/-csh/tcsh/' -e 's/-//g'\`
shell=\`/bin/basename \$comm\`

if [ -f \$LMOD_ROOT/lmod/lmod/init/\$shell ]; then
    . \$LMOD_ROOT/lmod/lmod/init/\$shell
else
    . \$LMOD_ROOT/lmod/lmod/init/sh
fi

unset comm shell

# Set system default stuff
export NCAR_DEFAULT_PATH=/usr/local/bin:/usr/bin:/sbin:/bin
export NCAR_DEFAULT_MANPATH=/usr/local/share/man:/usr/share/man
export NCAR_DEFAULT_INFOPATH=/usr/local/share/info:/usr/share/info

export PATH=\${PATH}:\$NCAR_DEFAULT_PATH
export MANPATH=\${MANPATH}:\$NCAR_DEFAULT_MANPATH
export INFOPATH=\${INFOPATH}:\$NCAR_DEFAULT_INFOPATH

# Set PBS workdir if appropriate
if [ -n "\$PBS_O_WORKDIR" ] && [ -z "\$NCAR_PBS_JOBINIT" ]; then
    if [ -d "\$PBS_O_WORKDIR" ]; then
        cd \$PBS_O_WORKDIR
    fi

    export NCAR_PBS_JOBINIT=\$PBS_JOBID
fi

# Load default modules
if [ -z "\$__Init_Default_Modules" -o -z "\$LD_LIBRARY_PATH" ]; then
  __Init_Default_Modules=1; export __Init_Default_Modules;
  module -q restore 
fi

# Hide specified modules
export LMOD_MODULERCFILE=$util_path/hidden-modules
EOF

mv $tm_file $util_path/localinit.sh

cat > $tm_file << EOF
# Location variables
setenv INSTALLPATH_ROOT $pkg_root
setenv MODULEPATH_ROOT $module_root

# Lmod configuration
setenv LMOD_SYSTEM_NAME $NCAR_SPACK_HOST
setenv LMOD_SYSTEM_DEFAULT_MODULES "$NCAR_SPACK_DEFMODS_NCAR"

if ( ! \$?MODULEPATH ) then
    setenv MODULEPATH \$MODULEPATH_ROOT/environment
else if ( \$MODULEPATH !~ *\${MODULEPATH_ROOT}* ) then
    setenv MODULEPATH \$MODULEPATH_ROOT/environment
endif

# Set defaults for Lmod behavior configuration
setenv LMOD_PACKAGE_PATH $util_path
setenv LMOD_CONFIG_DIR $util_path
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

# Set system default stuff
setenv NCAR_DEFAULT_PATH /usr/local/bin:/usr/bin:/sbin:/bin
setenv NCAR_DEFAULT_MANPATH /usr/local/share/man:/usr/share/man
setenv NCAR_DEFAULT_INFOPATH /usr/local/share/info:/usr/share/info

setenv PATH \${PATH}:\$NCAR_DEFAULT_PATH

if ( ! \$?MANPATH ) then
    setenv MANPATH \$NCAR_DEFAULT_MANPATH
else
    setenv MANPATH \${MANPATH}:\$NCAR_DEFAULT_MANPATH
endif

if ( ! \$?INFOPATH ) then
    setenv INFOPATH \$NCAR_DEFAULT_INFOPATH
else
    setenv INFOPATH \${INFOPATH}:\$NCAR_DEFAULT_INFOPATH
endif

# Set PBS workdir if appropriate
if ( \$?PBS_O_WORKDIR  && ! \$?NCAR_PBS_JOBINIT ) then
    if ( -d \$PBS_O_WORKDIR ) then
        cd \$PBS_O_WORKDIR
    endif

    setenv NCAR_PBS_JOBINIT \$PBS_JOBID
endif

# Load default modules
if ( ! \$?__Init_Default_Modules || ! \$?LD_LIBRARY_PATH ) then
  setenv __Init_Default_Modules 1
  module -q restore
endif

# Hide specified modules
setenv LMOD_MODULERCFILE $util_path/hidden-modules
EOF

mv $tm_file $util_path/localinit.csh
fi
