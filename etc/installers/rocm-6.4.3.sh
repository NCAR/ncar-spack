#!/bin/bash
#
#   Manual installer for ROCm 6.4.3
#
#   This is useful over the Spack installation because all of the ROCm
#   components get placed into the same root directory, and currently this
#   seems to be assumed by many of the ROCm runtime environment config
#   steps (e.g., ROCM_PATH variable)
#
#   Follows documentation from here:
#   https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.4.3/install/rocm-runfile-installer.html
#
#   Last Revised:   21:13, 17 Mar 2026
#

my_exe=$(readlink -f $0)

#
## USER CONFIG
#

# ROCm version
rocm_version=6.4.3

# File type info
os_name=sles
os_version=15.6

# ROCM runfile name
rocm_runfile=rocm-installer_1.1.3.60403-64-128~${os_name}${os_version//.}.run

# The runfile installer will place into $ROCM_PREFIX/rocm-version
rocm_prefix=/glade/u/apps/opt/rocm

#
## CLOBBER CHECKS
#

if [[ -d $rocm_prefix/rocm-$rocm_version ]]; then
    >&2 echo "Error: ROCm installation already exists at root $rocm_prefix/rocm-$rocm_version"
    exit 1
fi

#
## DOWNLOAD AND PREPARE FILES
#

if [[ ! -d rocm-installer ]]; then
    if [[ ! -f $rocm_runfile ]]; then
        echo "-> Downloading the $rocm_version runfile ..."
        # Get the runfile
        wget https://repo.radeon.com/rocm/installer/rocm-runfile-installer/rocm-rel-$rocm_version/${os_name}${os_version%%.*}/$rocm_runfile
    fi

    # Extract the runfile
    echo "-> Extracting the contents of the runfile ..."
    bash $rocm_runfile noexec
fi

if [[ ! -f rocm-installer/rocm-installer.orig ]]; then
    # Now, we need to make some hacks at the script so that we can use it for our purposes:
    #   1. Even though opensuse and sles are binary compatible as of 15.3, the script won't accept the former
    #   2. The script tries to use sudo even when not needed, so we need to hack that out too
    echo "-> Modifying the ROCm installer script for non-root usage ..."
    cd rocm-installer
    cp rocm-installer.sh rocm-installer.orig
    sed -i 's/sles)/sles|opensuse\*)/' rocm-installer.sh
    sed -i 's/^\(SUDO=\).*/SUDO=/' rocm-installer.sh
fi

#
## INSTALL AND BACKUP SCRIPTS
#

install_time=$(date +%y%m%dT%H%M)

echo "-> Installing ROCm $rocm_version into prefix $rocm_prefix ..."
mkdir -p $rocm_prefix/.build
bash rocm-installer.sh target=$rocm_prefix rocm |& tee $rocm_prefix/.build/log-6.4.3.$install_time

if [[ $? -eq 0 ]]; then
    echo -e "\n*** All done! ***\n"
    cp $my_exe $rocm_prefix/.build
else
    >&2 echo "Error: ROCm install failed. Log is stored at $rocm_prefix/.build/log-6.4.3.$install_time"
    exit 1
fi
