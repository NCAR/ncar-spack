# Installing VAPOR

While VAPOR is now in maintenance mode, you may still need to make bugfix
installs from time to time or install it onto a new system. Scott Pearse has
traditionally been our point of contact for this - he will inform CSG that a new
version needs to be installed.

There is, in fact, a Spack recipe to build VAPOR, but the VAPOR team did not
want to support this fragile source build, so it's best to simply install their
AppImage (similar to Flatpak or Snap) version and import into Spack as an
external for module creation.

After you download the AppImage from Scott (or
[here](https://vapordocumentationwebsite.readthedocs.io/en/latest/downloads.html)),
you can run the installer in `etc/installers`. Simply modify the install prefix.
This installer will copy the AppImage to the prefix and also generate a wrapper
script. The wrapper starts the AppImage and also makes a few environment
modifications to avoid potential software conflicts.

## Adding to Spack

Once VAPOR is installed, it can be added to Spack as an external via the
`constraints.cfg` file and then "installed" into the cluster. By "installing" it
in Spack, we motivate Spack to generate a module for that VAPOR version.

VAPOR should require no other customizations of note.
