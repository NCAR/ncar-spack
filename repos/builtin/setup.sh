# *** This script should be sourced by deploy only! ***
#
# NOTE -    this repo *must* be called builtin as it replaces the
#           packaged builtin repo in the main spack clone. Some
#           packages reference builtin explicitly and so concretization
#           will fail otherwise!

return_dir=$(pwd)

cd $SPACK_ENV/repos
git clone -c feature.manyFiles=true --sparse --filter blob:none git@github.com:spack/spack.git $repo
cd $repo
git sparse-checkout set var/spack/repos/builtin/packages
git checkout ${NCAR_SPACK_BUILTIN_VERSION:-$NCAR_SPACK_CLONE_VERSION}
ln -s var/spack/repos/builtin/packages packages
cat > repo.yaml << EOF
repo:
  namespace: 'builtin'
EOF

# Make sure the repo *replaces* the standard builtin
spack repo add $SPACK_ENV/repos/$repo
sed -i 's/\([ ]*repos:\)$/\1:/' $SPACK_ENV/spack.yaml 

cd $return_dir
