#!/bin/bash

#   These tarballs are needed for this installer and can be found in
#   /glade/work/csgteam/build/ncl-spack
#
#   g2clib-1.6.0-patch.tar.gz
#   gsl-2.5.tar.gz
#   hdf-4.2.14.tar.gz
#   hdf5-1.12.2.tar.gz
#   hdf-eos-2.20.tar.gz
#   hdf-eos-5.1.16.tar.gz
#   jasper-1.900.2.tar.gz
#   ncl-6.6.2-triangle.tar.gz
#
#	Maintainer: Brian Vanderwende
#	Revised:   21:12, 17 Mar 2026
#

#
## USER INPUT
#

SWVERSION=6.6.2
MAKEJOBS=8

if [[ $(whoami) == csgteam ]]; then
    SWPREFIX=/glade/u/apps/opt/$SWNAME/$SWVERSION

    if [[ -d $SWPREFIX/bin ]]; then
        echo "Exists... gotta quit now"
        exit 1
    fi
else
    SWPREFIX=/glade/derecho/scratch/$USER/test/$SWNAME/$SWVERSION
    rm -rf $SWPREFIX
fi

# Define dependency directories from Spack
SWDEPS[0]=/glade/u/apps/casper/23.10/spack/opt/spack/libjpeg-turbo/3.0.0/gcc/7.5.0/erh5
SWDEPS[1]=/glade/u/apps/casper/23.10/spack/opt/spack/zlib/1.2.13/gcc/7.5.0/otgt
SWDEPS[2]=/glade/u/apps/casper/23.10/spack/opt/spack/libszip/2.1.1/gcc/7.5.0/vcy4
SWDEPS[3]=/glade/u/apps/casper/23.10/spack/opt/spack/curl/8.1.2/gcc/7.5.0/l7n5
SWDEPS[4]=/glade/u/apps/casper/23.10/spack/opt/spack/netcdf/4.9.2/packages/netcdf-c/4.9.2/gcc/7.5.0/vn3p
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
# MANUAL BUILD SCRIPT
#

SWNAME=ncl

# Prepare environment
module purge

# We need to manually get wrapper since it isn't there for system GCC
module load gcc ncarcompilers
WRAPPERDIR=$(dirname $(which gcc))
module purge
export PATH=$WRAPPERDIR:$PATH

# ===== BUILD CONFIGURATION

# Define build itinerary
SWPKGS[0]=hdf-4.2.14
SWPKGS[1]=hdf5-1.12.2
SWPKGS[2]=hdf-eos-2.20
SWPKGS[3]=hdf-eos-5.1.16
SWPKGS[4]=jasper-1.900.2
SWPKGS[5]=g2clib-1.6.0-patch
SWPKGS[6]=gsl-2.5
SWPKGS[7]=$SWNAME-6.6.2-triangle

echo -e "\n>>> BEGINNING BUILD [${SWNAME}-6.6.2]\n"
echo "Building with ${LMOD_FAMILY_COMPILER} compilers ..."

# ===== UNPACK SOURCE FILES AND PREPARE GLOBAL ENVIRONMENT

# Make directory for build using PID to avoid clobbers from multiple builds
echo "Preparing source files ..."
BDIR=$PWD/$$; mkdir $BDIR; cd $BDIR

for P in ${!SWPKGS[@]}; do
	PKG=${SWPKGS[$P]}

	# Unpackage source files
	if [[ -e ../${PKG}.tar.gz ]]; then
        tar -xf ../${PKG}.tar.gz
		SRCDIR=$(ls -1c --color=never | head -1)
        [[ $SRCDIR != $PKG ]] && mv $SRCDIR $PKG
	else
		echo -e "\n*** ERROR: source for $PKG does not exist! Exiting ..."
		exit 2
	fi
done

# ===== BUILD AND INSTALL SOFTWARE PACKAGES

function run_cmd {
	echo -e "\n>>> RUNNING COMMAND [${1}]\n"

	eval $1
	RETVAL=${PIPESTATUS[0]}

	if [[ $RETVAL != 0 ]]; then
		echo -e "\n*** ERROR: command exited with code ${RETVAL}! Exiting ..."
		exit 1
	fi
}

INCPATHS=$SWPREFIX/deps/include
LIBPATHS=$SWPREFIX/deps/lib
export NCAR_INC_DEPS=${SWPREFIX}/deps/include
export NCAR_LDFLAGS_DEPS=${SWPREFIX}/deps/lib

mkdir -p $INCPATHS $LIBPATHS

for DEP in ${SWDEPS[@]}; do
    PKGNAME=$(awk -F/ '{print $10}' <<< $DEP | tr -d '-')

    if [[ -d $DEP/include ]]; then
        INCPATHS="$INCPATHS $DEP/include"
        declare -x NCAR_INC_${PKGNAME^^}=$DEP/include
    fi

    if [[ -d $DEP/include/freetype2 ]]; then
        INCPATHS="$INCPATHS $DEP/include/freetype2"
        declare -x NCAR_INC_${PKGNAME^^}2=$DEP/include/freetype2
    fi

    if [[ -d $DEP/lib ]]; then
        LIBPATHS="$LIBPATHS $DEP/lib"
        declare -x NCAR_LDFLAGS_${PKGNAME^^}=$DEP/lib
    fi

    if [[ -d $DEP/lib64 ]]; then
        LIBPATHS="$LIBPATHS $DEP/lib64"
        declare -x NCAR_LDFLAGS_${PKGNAME^^}64=$DEP/lib64
    fi
done

# Global settings
export {CPPFLAGS,CFLAGS,CXXFLAGS,FFLAGS,FCFLAGS,F77FLAGS,F90FLAGS}=-fPIC
export PERL=
export {CFLAGS,CXXFLAGS}="-O2 -march=core-avx2 -fopenmp -fPIC $CFLAGS"
export FFLAGS="-O2 -fopenmp -march=core-avx2 $FFLAGS"
export F90FLAGS="-O2 -march=core-avx2 -fPIC -fopenmp"
export CPPFLAGS="-DNDEBUG"
export CXX=$(which g++)

function gen_input {
cat > conf.input << EOF

y
$SWPREFIX

y
y
y
y
y
y
y
y
y
y
n
y
y
y
y
$LIBPATHS
$INCPATHS
n
y
EOF
}

for (( N=0; N<${#SWPKGS[@]}; N++ )); do
    echo -e "\n$((N+1))) BUILDING PACKAGE [${SWPKGS[${N}]}] ...\n"
    cd ${SWPKGS[${N}]}

    # Define config/build options for package
    case ${SWPKGS[${N}]} in
        hdf5*)
            BUILDOPTS=" --with-zlib=${SWDEPS[1]}    \
                        --with-szlib=${SWDEPS[2]}"
            ;;
        hdf-4*)
            export LIBS=-ltirpc
            BUILDOPTS=" --with-zlib=${SWDEPS[1]}    \
                        --with-jpeg=$SWPREFIX/deps  \
                        --disable-netcdf"
            ;;
        hdf-eos-2*)
            BUILDOPTS=" CC=$SWPREFIX/deps/bin/h4cc    \
                        --with-hdf4=$SWPREFIX/deps    \
                        --with-zlib=${SWDEPS[1]}    \
                        --with-jpeg=$SWPREFIX/deps"
            cp  include/HdfEosDef.h \
                include/ease.h      \
                ${SWPREFIX}/deps/include
            ;;
        hdf-eos-5*)
            BUILDOPTS=" CC=$SWPREFIX/deps/bin/h5cc       \
                        --with-hdf5=$SWPREFIX/deps     \
                        --with-zlib=${SWDEPS[1]}         \
                        --with-szlib=${SWDEPS[2]}"

            # Hand copy two headers
            cp  include/HE5_GctpFunc.h  \
                include/HE5_HdfEosDef.h \
                include/cfortHdf.h      \
                ${SWPREFIX}/deps/include
            ;;
        *)
            unset LIBS LDFLAGS
            BUILDOPTS=
            ;;
    esac

    if [[ ${SWPKGS[${N}]} == g2clib* ]]; then
        sed -i "22 s|=.*|=-I${SWPREFIX}/deps/include|" makefile

        run_cmd "make all"
        mv libgrib2c.a ${SWPREFIX}/deps/lib
        cp grib2.h ${SWPREFIX}/deps/include
    elif [[ ${SWPKGS[${N}]} == ncl* ]]; then
        cd config

        run_cmd "make -f Makefile.ini"
        ./ymake -config $(pwd)
        cd ../

        gen_input
        ./Configure < conf.input

        # Make sure we use HDF5 1.10 API
        sed -i 's/\(#define CcOptions.*\)/\1 -DH5_USE_110_API/' config/LINUX

        # HDF4 needs libtirpc
        sed -i 's/\(#define HDFlib.*\)/\1 -ltirpc/' config/Site.local

        run_cmd "make Everything"
    else
        # Build the package using config-make
        run_cmd "./configure --prefix=$SWPREFIX/deps $BUILDOPTS"
        run_cmd "make -j $MAKEJOBS"

        # Test and install the package
        run_cmd "make install"
    fi

    cd ../
done

# Check for success
if [[ ! -f ${SWPREFIX}/bin/ncl ]]; then
    echo -e "\n*** ERROR: build did not produce main NCL binary! Exiting ..."
    exit 1
fi

# Add dependency includes to wrapper path
for DEP in 15 17 13 10 12 11 9 7 1; do
    LIB=${SWDEPS[$DEP]}

    if [[ -d $LIB/include ]]; then
        WRAPPERINCS="${WRAPPERINCS:+$WRAPPERINCS }-I$LIB/include"
    fi
done

for F in $(grep -l --color=no sysincdir $SWPREFIX/bin/*); do
    sed -i "s|\(set sysincdir =\).*|\1 \"$WRAPPERINCS\"|" $F
done

# Add dependency libraries to wrapper path
for DEP in 15 17 13 10 12 11 9 7 1; do
    LIB=${SWDEPS[$DEP]}

    if [[ -d $LIB/lib ]]; then
        WRAPPERLIBS="${WRAPPERLIBS:+$WRAPPERLIBS }-L$LIB/lib"
    elif [[ -d $LIB/lib64 ]]; then
        WRAPPERLIBS="${WRAPPERLIBS:+$WRAPPERLIBS }-L$LIB/lib64"
    fi
done

for F in $(grep -l --color=no syslibdir $SWPREFIX/bin/*); do
    sed -i "s|\(set syslibdir =\).*|\1 \"$WRAPPERLIBS\"|" $F
done

cd ../

# Find ESMF lib and add to install
ESMFDIR=/glade/u/apps/casper/23.10/spack/opt/spack/esmf/8.0.1/gcc/7.5.0/fkm2
cp $ESMFDIR/bin/ESMF_RegridWeightGen ${SWPREFIX}/bin

# ===== CLEAN FILES

echo -e "\n<<< BUILD COMPLETE!\n"
echo "Cleaning source files ..."
rm -rf $BPID
