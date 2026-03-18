#!/bin/bash

#
## USER INPUT
#

# Path to create the NCARG dependency collection
PREFIX=/glade/u/apps/opt/ncl/ncarglibs/6.6.2

# Dependencies to populate the collection with
# (should be the same as those used in NCL build)
SWDEPS[0]=/glade/u/apps/casper/23.10/spack/opt/spack/libjpeg-turbo/3.0.0/gcc/7.5.0/erh5
SWDEPS[1]=/glade/u/apps/casper/23.10/spack/opt/spack/zlib/1.2.13/gcc/7.5.0/otgt
SWDEPS[2]=/glade/u/apps/casper/23.10/spack/opt/spack/libszip/2.1.1/gcc/7.5.0/vcy4
SWDEPS[3]=/glade/u/apps/casper/23.10/spack/opt/spack/curl/8.1.2/gcc/7.5.0/l7n5
SWDEPS[4]=/glade/u/apps/casper/23.10/spack/opt/spack/netcdf/4.9.2/packages/netcdf-c/4.9.2/gcc/7.5.0/d5m5
SWDEPS[5]=/glade/u/apps/casper/23.10/spack/opt/spack/proj/5.2.0/gcc/7.5.0/axoz
SWDEPS[6]=/glade/u/apps/casper/23.10/spack/opt/spack/gdal/2.4.4/gcc/7.5.0/u3bj
SWDEPS[7]=/glade/u/apps/casper/23.10/spack/opt/spack/expat/2.5.0/gcc/7.5.0/jdvc
SWDEPS[8]=/glade/u/apps/casper/23.10/spack/opt/spack/udunits/2.2.28/gcc/7.5.0/3262
SWDEPS[9]=/glade/u/apps/casper/23.10/spack/opt/spack/freetype/2.10.2/gcc/7.5.0/5ugg
SWDEPS[10]=/glade/u/apps/casper/23.10/spack/opt/spack/libxrender/0.9.10/gcc/7.5.0/p6pn
SWDEPS[11]=/glade/u/apps/casper/23.10/spack/opt/spack/pixman/0.42.2/gcc/7.5.0/f5nq
SWDEPS[12]=/glade/u/apps/casper/23.10/spack/opt/spack/fontconfig/2.14.2/gcc/7.5.0/uddz
SWDEPS[13]=/glade/u/apps/casper/23.10/spack/opt/spack/cairo/1.16.0/gcc/7.5.0/yzdg
SWDEPS[14]=/glade/u/apps/casper/23.10/spack/opt/spack/libtirpc/1.2.6/gcc/7.5.0/rll2
SWDEPS[15]=/glade/u/apps/casper/23.10/spack/opt/spack/libx11/1.8.4/gcc/7.5.0/istz
SWDEPS[16]=/glade/u/apps/casper/23.10/spack/opt/spack/libxaw/1.0.13/gcc/7.5.0/p5gh
SWDEPS[17]=/glade/u/apps/casper/23.10/spack/opt/spack/libxext/1.3.3/gcc/7.5.0/vhld

#
## MAIN SCRIPT
#

echo "Creating NCAR graphics library collection in path:"
echo "    $PREFIX"
echo
echo "Copying files from:"

mkdir -p $PREFIX

for dep_dir in ${SWDEPS[@]}; do
    echo " - $dep_dir"
    rsync -a $dep_dir/ $PREFIX
done

echo
echo "Done!"
