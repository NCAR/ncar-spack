#!/bin/bash
#
# ===== CUSTOM BUILD SCRIPT
#
#   This script installs IDL and geov files into /glade/u/apps/opt
#   for shared usage across systems. The HPCinstall build scripts then
#   create modules for use on each system. Installing in this manner
#   reduces duplication and saves space.
#
#   Note -  ACOM maintains a page for downloading IDL releases:
#           https://www.acom.ucar.edu/idl/IDL86/
#           (Must be on the VPN/internal)
#
#   Note - the geov-4.8f tarball can be found in
#          /glade/work/csgteam/build/idl
#
#	Maintainer:     Brian Vanderwende
#	Last Revised:   21:12, 17 Mar 2026

#   *** This script should be run as csgteam ***

#
## USER INPUT
#

SWVERSION=9.2.0
PREFIX=/glade/u/apps/opt/$SWNAME/$SWVERSION

#
## MAIN SCRIPT
#

if [[ $USER != csgteam ]]; then
    echo "Error: install script must be run as csgteam"
    exit 1
fi

SWNAME=idl
IDLSRC=idl-$SWVERSION
GEOSRC=geov-4.8f

function install_sw {
set -x

# Run IDL installer in silent mode
./install.sh -s << EOF
y
$PREFIX
y
y
EOF

# Set up license
cat > ${PREFIX}/license/lic_server.dat << EOF
http://license-idl.ucar.edu:4080
EOF

# Set license paths to symlinks to temp
cd $PREFIX/license
rm -rf flexera*
ln -s /tmp flexera
ln -s /tmp flexera-sv
cd - > /dev/null

# Get IDL dir
IDLDIR=$(basename $(readlink -f ${PREFIX}/idl))

cd ../

# Add geov files to install
mv $GEOSRC $PREFIX

# Add user-write permissions
chmod -R u+w $PREFIX

set +x
}

# Prepare environment
module purge

# Prepare build
mkdir -p $PREFIX/BUILD_DIR
tar -xf ${IDLSRC}.tar.gz
tar -xf ${GEOSRC}.tar.gz
cd $IDLSRC

# Run build
install_sw |& tee $PREFIX/BUILD_DIR/build.log

# Clean and preserve
cd ../
rm -rf $IDLSRC $GEOSRC
cp $0 ${IDLSRC}.tar.gz ${GEOSRC}.tar.gz $PREFIX/BUILD_DIR/
