# *** This script should be sourced by deploy only! ***
#
# This repo provides a sparse clone of builtin, but it does not replace
# the built-in builtin! Use it to selectively add newer versions of package
# recipes by symbolically linking them into the packages directory.

my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd )"
return_dir=$(pwd)

cd $SPACK_ENV/repos
git clone -c feature.manyFiles=true --sparse --filter blob:none https://github.com/spack/spack.git $repo
cd $repo
git sparse-checkout set var/spack/repos/builtin/packages
git checkout ${NCAR_SPACK_BUILTIN_VERSION:-$NCAR_SPACK_CLONE_VERSION}
cp -r $my_dir/packages .
cat > repo.yaml << EOF
repo:
  namespace: 'future'
EOF

# Use this repo in the environment
spack repo add $SPACK_ENV/repos/$repo

cd $return_dir
