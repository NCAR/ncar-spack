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

# Pretty colors and other formatting
export GCOL=$(printf "\033[1;32m") BCOL=$(printf "\033[1;34m") PCOL=$(printf "\033[1;35m")
export RCOL=$(printf "\033[1;31m") FCOL=$(printf "\033[0;37m") DCOL=$(printf "\033[0m") SEP=$'\n'
export COLOR_LIST="GCOL BCOL PCOL RCOL FCOL DCOL"

# If we are running the deploy script, stop here
if [[ -n $NCAR_SPACK_SETUP_DEPLOY ]]; then
    return
fi

my_name=$(basename "$0")
. $my_dir/../main.cfg

if [[ ${NCAR_SPACK_UPSTREAM_MODULES:-true} == true ]]; then
    NCAR_SPACK_MODULE_FLAGS=--upstream-modules
fi

# Make sure all config variables are exported
for cfg_var in ${!NCAR_SPACK_*}; do
    export $cfg_var
done

#
## SHARED REGISTRY CONFIGURATION
#

# The following variables are shared among multiple scripts
# Note that shell arrays can't be exported, so we must define it here to be
# reinstantiated for each script
declare -A field_widths field_labels registry_entries
field_list=(    spec_hash install_date spack_commit "config[maxjobs]" "config[trust]"
                "config[cache]" "config[publish]" "config[register]" "config[source]"
                raw_spec spec   )

field_widths[spec_hash]=32              field_labels[spec_hash]="Package Hash"
field_widths[install_date]=19           field_labels[install_date]="Date Installed"
field_widths[spack_commit]=40           field_labels[spack_commit]="Spack Git Repo Commit"
field_widths["config[maxjobs]"]=4       field_labels["config[maxjobs]"]="Jobs"
field_widths["config[trust]"]=6         field_labels["config[trust]"]="Trust?"
field_widths["config[cache]"]=7         field_labels["config[cache]"]="Cached?"
field_widths["config[publish]"]=8       field_labels["config[publish]"]="Publish?"
field_widths["config[register]"]=9      field_labels["config[register]"]="Register?"
field_widths["config[source]"]=10       field_labels["config[source]"]="Keep Src?"
field_widths[raw_spec]=*                field_labels[raw_spec]="Raw Spec"
field_widths[spec]=                     field_labels[spec]="Spec"

install_params="cache|trust|maxjobs|access|register|source"
default_trust=no
default_cache=yes
default_publish=yes
default_source=no

function add_spec_to_registry {
    IFS='|' read -a registry <<< $1
    duplicate_value=${registry_entries[${registry[0]}]}
    unset registry_entries["${registry[0]}"]

    for n in ${!field_list[@]}; do
        if [[ ${field_widths[${field_list[n]}]} == \* ]]; then
            width=${spec_column_width:-$(($(wc -c <<< ${registry[$n]}) - 1))}

            if [[ $width -lt 20 ]]; then
                width=20
            fi
        fi

        if [[ $n -gt 0 ]]; then
            registry_entries[${registry[0]}]+=" | "
        fi

        registry_entries[${registry[0]}]+=$(printf "%-${field_widths[${field_list[n]}]}s" $width "${registry[$n]}")
        unset width
    done

    if [[ -n $duplicate_value ]]; then
        if [[ $duplicate_value == ${registry_entries[${registry[0]}]} ]]; then
            tsecho " >> Duplicate registry entry for /${registry[0]}; skipping"
            return
        else
            tsecho "Error: Two inconsistent registry entries for /${registry[0]}; cannot continue!"
            exit 1
        fi
    fi

    echo "${registry_entries[${registry[0]}]}" >> $2
}

function write_registry_header {
    rm -f $SPACK_ENV/.registry.tmp
    dash_width=0

    for var in ${field_list[@]}; do
        header="${header:+${header}|}${field_labels[$var]}"

        if [[ ${field_widths[$var]} == \* ]]; then
            dash_width=$((dash_width + ${spec_column_width:-20} + 3))
        else
            dash_width=$((dash_width + ${field_widths[$var]:-20} + 3))
        fi
    done

    add_spec_to_registry "$header" $SPACK_ENV/.registry.tmp
    printf "%*s\n" $dash_width | tr " " "-" >> $SPACK_ENV/.registry.tmp
}

function find_var_from_label {
    stripped_label=$(xargs <<< $1)

    for var in ${!field_labels[@]}; do
        if [[ ${field_labels[$var]} == $stripped_label ]]; then
            echo $var
            return
        fi
    done

    tsecho "Error: Existing label '$stripped_label' not found in registry configuration!"
    exit 1
}

function match_spec_column_width {
    IFS='|' read -a header_labels <<< $(head -n 1 $1)

    for n in ${!field_list[@]}; do
        if [[ ${field_list[$n]} == raw_spec ]]; then
            spec_index=$n
        fi
    done

    spec_column_width=$(($(wc -c <<< ${header_labels[$spec_index]}) - 3))
}

#
## SPACK ENVIRONMENT SETUP
#

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
