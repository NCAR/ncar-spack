# This helper script should *always* be sourced

function tsecho {
    echo -e "$(date +%FT%T) - $1 ..."
}

. $my_dir/../main.cfg

if [[ $NCAR_SPACK_CLEAN != true ]]; then
    tsecho "Sanitizing user environment"
    export CUSTOM_SPACK_ROOT=$NCAR_SPACK_PUBLIC_ROOT/spack NCAR_SPACK_CLEAN=true

    $CUSTOM_SPACK_ROOT/bin/clean_bash $0 "$@"
    exit $?
elif [[ -z $SPACK_ENV ]]; then
    set -e
    my_name=$(basename "$0")
    my_host=$(hostname)
    my_env_type=${NCAR_SPACK_ENV_TYPE:-build}

    tsecho "Activating Spack $my_env_type environment"
    
    if [[ -f $NCAR_SPACK_ENV_ROOT/$my_env_type/spack.yaml ]]; then
        spack env activate $NCAR_SPACK_ENV_ROOT/$my_env_type
    else
        echo "Error:  This $my_name script does not appear to be part of a cluster"
        echo -e "        $my_env_type environment. Use \$SPACK_ENV/bin/$my_name instead.\n"
        exit 1
    fi

    tsecho "Testing whether user is owner of $my_env_type env"
    spack_env_user=$(stat -c "%U" $SPACK_ENV)

    if [[ $USER != $spack_env_user ]]; then
        echo "Error:  This script must be run by the owner of the active $my_env_type environment."
        echo -e "        $SPACK_ENV -> owned by $spack_env_user"
        exit 1
    fi
fi
