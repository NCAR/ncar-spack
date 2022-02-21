function tsecho {
    echo -e "$(date +%FT%T) - $1 ..."
}

if [[ $NCAR_SPACK_CLEAN != true ]]; then
    tsecho "Sanitizing user environment"
    NCAR_SPACK_CLEAN=true clean_bash $0 "$@"
    exit $?
else
    # Even though clean_bash uses the spack activation script
    # as an RC file, this doesn't work when calling scripts
    tsecho "Activating Spack installation environment"
    . ${SPACK_STARTUP/.csh/.sh}
fi

tsecho "Activating Spack build environment"
if [[ -f $my_dir/../spack.yaml ]]; then
    spack env activate $my_dir/..
else
cat << EOF
Error:  This $my_name script does not appear to be part of a cluster
        build environment. Use \$SPACK_ENV/bin/$my_name instead.

EOF
exit 1
fi

tsecho "Testing whether user is owner of build env"
spack_env_user=$(stat -c "%U" $SPACK_ENV)
if [[ $USER != $spack_env_user ]]; then
cat << EOF
Error:  This script must be run by the owner of the active build environment.
        $SPACK_ENV -> owned by $spack_env_user

EOF
exit 1
fi
