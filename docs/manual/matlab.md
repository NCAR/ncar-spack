# Installing Matlab

Matlab currently needs to be installed manually, as the Spack package only
offers very old versions. This install is also annoying because it uses a GUI
installer. Using a virtual desktop like FastX or VNC is recommended.

To install Matlab, you will need to first download the Linux installer from
their website either in the remote desktop, or locally and then upload it. You
need to have a Mathworks account to do this.

* [Matlab Download Page](https://www.mathworks.com/downloads)

I have typically stored these downloads in `/glade/work/csgteam/build/matlab`.
Once downloaded, unzip into a version-specific directory and run the installer
script `./install`.

!!! tip
    As you will need to run the installer as **csgteam**, you should ensure that
    you `sudo` to csgteam using X11 forwarding. You can do this with `sudox
    csgteam`.

The installer will also require you to log into a Mathworks account tied to our
license. It will then ask you to select a license to use; probably you will want
to select **Matlab Parallel Server**, as this will ensure the MPS is installed
along with other toolboxes. At some point, it may ask if you want to provide a
license file. You can point it to the `network.lic` file in the build directory
mentioned above.

It will then ask for a path - put it in `/glade/u/apps/opt/matlab/<version>`.

Turn off the "Improve..." checkbox, confirm and then expect it to run for 20-60
minutes.

## Adding to Spack

Once Matlab is installed, it can be added to Spack as an external via the
`constraints.cfg` file and then "installed" into the cluster. By "installing" it
in Spack, we motivate Spack to generate a module for that Matlab version.

Cluster definitions should already contain important module customizations for
Matlab. In particular, ensure that Matlab modules contain the following
configuration:

```yaml
matlab:
  environment:
    set:
      MW_FEATURE_MathworksServiceHostIsOnByDefault: '0'
```

This undocumented environment variable will tell Matlab (at least 2024-2025
versions) to not launch the *ServiceHost* background process. This process has
no tangible benefit for our users and in fact downloads ~1 GB of data into
their home directory.
