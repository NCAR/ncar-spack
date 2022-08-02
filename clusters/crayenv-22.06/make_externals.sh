#!/bin/bash

# Common library
cl_path=/glade/u/apps/common/default/spack/opt/spack

# Packages to skip
skip_list="intel-oneapi-compilers nvhpc"

# Start with common externals
cp ../common/externals.cfg .

for pkg_path in $cl_path/*/*/gcc/7.5.0; do
    pkg_name=$(sed "s|${cl_path}/\([^/]*\).*|\1|" <<< $pkg_path)

    if [[ " $skip_list " != *" $pkg_name "* ]]; then
        echo "fixed       : $pkg_path $pkg_name" >> externals.cfg
    fi
done
