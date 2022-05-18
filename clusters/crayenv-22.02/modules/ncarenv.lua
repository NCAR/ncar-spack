require("posix")

-- The message printed by the module whatis command
whatis("ncarenv v%VERSION%")

-- The message printed by the module help command
help([[
This module sets up default NCAR environment, adding our hierarchical module
tree, convenience features and tailored performance settings

Based on CPE:   %VERSION%
Created on:     %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod","sticky")

-- Detect environment settings
local user      = capture("whoami")
local tmpdir    = os.getenv("TMPDIR")
local othreads  = os.getenv("OMP_NUM_THREADS")

-- Utility locations
local vncbin    = "/glade/u/apps/opt/vncmgr"

-- Put system utilities in PATH
prepend_path("PATH",    vncbin)     -- vncmgr

-- Convenience variables
setenv("NCAR_ENV_VERSION",  "%VERSION%")
setenv("ENV",               "/etc/profile.d/modules.sh")
setenv("NCAR_PBS_CH",       "chadmin1.ib0.cheyenne.ucar.edu")
setenv("NCAR_PBS_CA",       "casper-pbs")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

setenv("OMP_STACKSIZE", "64000K")

-- System-wide dask settings from Joe Hamman
setenv("DASK_ROOT_CONFIG", "/glade/u/apps/config/dask")

-- Model-specific settings
setenv("WRFIO_NCD_LARGE_FILE_SUPPORT", "1")

-- Set user's TMPDIR if not already set
if not tmpdir or not string.match(tmpdir, "^/glade") then
    setenv("TMPDIR", pathJoin("/glade/scratch", user))
end

-- System specific settings
setenv("NCAR_HOST",         "gust")
setenv("QSCACHE_SERVER",    "gust")

-- On CSEG's request (jedwards/mvertens@ucar.edu)
setenv("CESMDATAROOT",  "/glade/p/cesmdata/cseg")
setenv("CESMROOT",      "/glade/p/cesm")

-- Make sure localization is set
setenv("LC_ALL",    "en_US.UTF-8")
setenv("LANG",      "en_US.UTF-8")

-- Loading this module unlocks the NCAR Spack module tree
append_path("MODULEPATH", "%MODPATH%")
