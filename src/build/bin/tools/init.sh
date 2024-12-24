# This helper script should *always* be sourced

function tsecho {
    if [[ $1 == Error:* ]]; then
        >&2 echo -e "$RCOL$1$DCOL"
    elif [[ ${log_verbosity:-0} -ge ${2:-0} ]]; then
        echo -e "$(date +%FT%T) - $1 ..."
    fi
}

function log_cmd {
cat << EOF

=====
$1
=====

EOF
}

function update_log_pointers {
    for log_type in $@; do
        log_name=log_$log_type
        log_src=${log_file:-${!log_name}}

        if [[ -f $log_src ]]; then
            rm -f $log_dir/latest.$log_type
            ln -s $log_src $log_dir/latest.$log_type
        fi
    done
}

export -f tsecho log_cmd update_log_pointers

my_name=$(basename "$0")
. $my_dir/../main.cfg

# Make sure all config variables are exported
for cfg_var in ${!NCAR_SPACK_*}; do
    export $cfg_var
done

# The following variables are shared among multiple scripts
# Note that shell arrays can't be exported, so we must define it here to be
# reinstantiated for each script
declare -A field_vars field_labels
field_widths=( 32 19 40 4 6 7 8 9 )
field_vars[32]=spec_hash
field_vars[19]=install_date
field_vars[40]=spack_commit
field_vars[4]="config[maxjobs]"
field_vars[6]="config[trust]"
field_vars[7]="config[cache]"
field_vars[8]="config[publish]"
field_vars[9]="config[register]"
field_labels[spec_hash]="Package Hash"
field_labels[install_date]="Date Installed"
field_labels[spack_commit]="Spack Git Repo Commit"
field_labels["config[maxjobs]"]="Jobs"
field_labels["config[trust]"]="Trust?"
field_labels["config[cache]"]="Cached?"
field_labels["config[publish]"]="Publish?"
field_labels["config[register]"]="Register?"

install_params="cache|trust|maxjobs|access|register"
default_trust=no
default_cache=yes
default_publish=yes

# Calling Python is much faster than calling spack python but needs some setup
pypath="$SPACK_ROOT/lib/spack/external:$SPACK_ROOT/lib/spack/external/_vendoring:$SPACK_ROOT/lib/spack"

# Make sure nobody else is publishing to public
if [[ -f $NCAR_SPACK_ENV_BUILD/.publock ]]; then
    if [[ $(cat $NCAR_SPACK_ENV_BUILD/.publock) != $NCAR_SPACK_LOCK_PID ]]; then
        >&2 echo "Error: Someone else is publishing changes; unsafe to proceed."
        exit 1
    fi
fi

if [[ $NCAR_SPACK_CLEAN != true ]]; then
    tsecho "Sanitizing user environment" ${quiet_mode:+9999}
    export TMPDIR=${NCAR_SPACK_TMPROOT}/$USER/temp; mkdir -p $TMPDIR
    NCAR_SPACK_CLEAN=true $NCAR_SPACK_ROOT_DEPLOYMENT/spack/bin/clean_bash $0 "$@"
    exit $?
elif [[ -z $SPACK_ENV ]]; then
    set -e
    export my_host=$(hostname)
    export my_env_type=${NCAR_SPACK_ENV_TYPE:-build}
    export start_time=${NCAR_SPACK_DEPLOY_TIME:-$(date +%y%m%dT%H%M)}

    # Pretty colors and other formatting
    export GCOL=$(printf "\033[1;32m") BCOL=$(printf "\033[1;34m") PCOL=$(printf "\033[1;35m")
    export RCOL=$(printf "\033[1;31m") FCOL=$(printf "\033[0;37m") DCOL=$(printf "\033[0m") SEP=$'\n'
    export COLOR_LIST="GCOL BCOL PCOL RCOL FCOL DCOL"

    tsecho "Activating Spack $my_env_type environment" ${quiet_mode:+9999}
    
    if [[ -f $NCAR_SPACK_ROOT_ENVS/$my_env_type/spack.yaml ]]; then
        spack env activate $NCAR_SPACK_ROOT_ENVS/$my_env_type
    else
        >&2 echo "Error: This $my_name script does not appear to be part of a cluster"
        >&2 echo -e "       $my_env_type environment. Use \$SPACK_ENV/bin/$my_name instead.\n"
        exit 1
    fi

    tsecho "Testing whether user is owner of $my_env_type env" ${quiet_mode:+9999}
    export spack_env_user=$(stat -c "%U" $SPACK_ENV)

    if [[ $USER != $spack_env_user ]]; then
        >&2 echo "Error: This script must be run by the owner of the active $my_env_type environment."
        >&2 echo -e "       $SPACK_ENV -> owned by $spack_env_user"
        exit 1
    fi

    tsecho "Ensure specs list is flow-style YAML" ${quiet_mode:+9999}

    if grep -q -E '^ +specs: +\[' $SPACK_ENV/spack.yaml; then
        spack python $my_dir/tools/fix_specs.py
    fi
fi
