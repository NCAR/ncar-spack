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

    tsecho "Activating Spack build environment"
    
    if [[ -f $my_dir/../spack.yaml ]]; then
        spack env activate $my_dir/..
    else
        echo "Error:  This $my_name script does not appear to be part of a cluster"
        echo -e "        build environment. Use \$SPACK_ENV/bin/$my_name instead.\n"
        exit 1
    fi

    tsecho "Testing whether user is owner of build env"
    spack_env_user=$(stat -c "%U" $SPACK_ENV)

    if [[ $USER != $spack_env_user ]]; then
        echo "Error:  This script must be run by the owner of the active build environment."
        echo -e "        $SPACK_ENV -> owned by $spack_env_user"
        exit 1
    fi
fi
