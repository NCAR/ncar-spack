# Installing IDL

IDL should be installed manually - there is a Spack package, but it is a
placeholder package designed purely for modulefile generation.

The IDL license is managed by Garth D'Attilo out of ACOM. Therefore, you will
need to access IDL downloads via this ACOM page:

https://www.acom.ucar.edu/idl/IDL86/

You will need to be on the UCAR VPN to access this page. If you encounter any
difficulties, contact NRIT.

In the `etc/installers` directory of this repository, you will find a sample
build script for IDL. Modify this script for the version of IDL you wish to
install, and then run it as *csgteam*. This script will perform the following
actions:

1. Install IDL into the desired prefix
2. Set up the license to use NRIT's server
3. Ensure that license data are not dumped to GLADE but rather `/tmp`
4. Add geography data from `geov-4.8f.tar.gz`

## Adding to Spack

Once IDL is installed, it can be added to Spack as an external via the
`constraints.cfg` file and then "installed" into the cluster. By "installing" it
in Spack, we motivate Spack to generate a module for that IDL version.

IDL should require no other customizations of note.
