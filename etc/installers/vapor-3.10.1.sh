#!/bin/bash
#
#   Manual installer for VAPOR 3.10.1
#
#   VAPOR team prefers to support AppImage version of VAPOR instead of the
#   source-build Spack version.
#
#   More documentation is available here:
#   https://vapordocumentationwebsite.readthedocs.io/en/latest/downloads.html
#
#   Last Revised:   21:13, 17 Mar 2026
#

#
## USER CONFIG
#

vapor_version=3.10.1
vapor_prefix=/glade/u/apps/opt/vapor/$vapor_version

#
## CLOBBER CHECKS
#

if [[ -d $vapor_prefix ]]; then
    >&2 echo "Error: VAPOR installation already exists at root $vapor_prefix"
    exit 1
fi

#
## DOWNLOAD AND PREPARE FILES
#

set -e
my_exe=$(readlink -f $0)
app_image=VAPOR-${vapor_version}-x86_64.AppImage
vapor_download=https://github.com/NCAR/VAPOR/releases/download/${vapor_version}/$app_image

if [[ ! -f $app_image ]]; then
    echo "-> Downloading VAPOR as $app_image ..."
    wget $vapor_download
fi

#
## INSTALL AND BACKUP SCRIPTS
#

install_time=$(date +%y%m%dT%H%M)

echo "-> Installing VAPOR $vapor_version into prefix $vapor_prefix ..."
mkdir -p $vapor_prefix/.build $vapor_prefix/bin

cp $app_image $vapor_prefix/bin/

# Create wrapper to run AppImage
cat > $vapor_prefix/bin/vapor << EOF
#!/bin/bash

# These applications and settings interfere with the AppImage
# and so must be removed from the user environment
export PATH=\$(sed "s|/glade/u/apps/\$NCAR_HOST/\$NCAR_ENV_VERSION/opt/view/bin:||" <<< \$PATH)
unset PYTHONSTARTUP TMPDIR

exec $vapor_prefix/bin/VAPOR-3.10.1-x86_64.AppImage \$@
EOF

chmod +x $vapor_prefix/bin/*

echo -e "\n*** All done! ***\n"
cp $my_exe $vapor_prefix/.build
