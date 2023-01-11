require("posix")
family("env")

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

local syspath   = os.getenv("NCAR_DEFAULT_PATH")
local sysman    = os.getenv("NCAR_DEFAULT_MANPATH")
local sysinfo   = os.getenv("NCAR_DEFAULT_INFOPATH")

-- Utility locations
local viewpath      = "%VIEWROOT%"

-- System specific settings
setenv("NCAR_ENV_VERSION",  "%VERSION%")
setenv("NCAR_HOST",         "gust")
setenv("QSCACHE_SERVER",    "gust")

-- Loading this module unlocks the NCAR Spack module tree
append_path("MODULEPATH", "%MODPATH%")

-- Add Lmod settings
setenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
setenv("LMOD_AVAIL_STYLE", "grouped:system")
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "%DEFMODS%")

-- Ensure modules load in subshells
setenv("ENV", "/etc/profile.d/modules.sh")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

setenv("OMP_STACKSIZE", "64000K")

-- System-wide dask settings
-- setenv("DASK_ROOT_CONFIG", "/glade/u/apps/config/dask")

-- Model-specific settings
setenv("WRFIO_NCD_LARGE_FILE_SUPPORT", "1")

-- Set user's TMPDIR if not already set
if not tmpdir or not string.match(tmpdir, "^/glade") then
    setenv("TMPDIR", pathJoin("/glade/gust/scratch", user))
end

-- On CSEG's request (jedwards/mvertens@ucar.edu)
-- setenv("CESMDATAROOT",  "/glade/p/cesmdata/cseg")
-- setenv("CESMROOT",      "/glade/p/cesm")

-- Make sure localization is set
setenv("LC_ALL",    "en_US.UTF-8")
setenv("LANG",      "en_US.UTF-8")

-- Add view utilities to PATHS
append_path("PATH",             pathJoin(viewpath, "bin"))
append_path("MANPATH",          pathJoin(viewpath, "man"))
append_path("MANPATH",          pathJoin(viewpath, "share/man"))

setenv("NCAR_INC_COMMON",       pathJoin(viewpath, "include"))
setenv("NCAR_LDFLAGS_COMMON",   pathJoin(viewpath, "lib"))
setenv("NCAR_LDFLAGS_COMMON64", pathJoin(viewpath, "lib64"))

prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib64/pkgconfig"))

-- Make sure system versions come after Spack versions
append_path("PATH",             syspath)
append_path("MANPATH",          sysman)
append_path("INFOPATH",         sysinfo)
