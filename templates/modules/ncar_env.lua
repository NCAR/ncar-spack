{% extends "ncar_default.lua" %}
{% block footer %}
-- Detect environment settings
local tmpdir    = os.getenv("TMPDIR")
local user      = os.getenv("HOME"):sub(15)
local othreads  = os.getenv("OMP_NUM_THREADS")

-- Utility locations
local gcibin    = "/glade/u/apps/opt/globus-utils"
local vncbin    = "/glade/u/apps/opt/vncmgr"

-- Put system utilities in PATH
prepend_path("PATH",    gcibin)     -- gci/gcert
prepend_path("PATH",    vncbin)     -- vncmgr

-- Convenience variables
setenv("ENV",           "/etc/profile.d/modules.sh")
setenv("NCAR_PBS_CH",   "chadmin1.ib0.cheyenne.ucar.edu")
setenv("NCAR_PBS_CA",   "casper-pbs")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

setenv("OMP_STACKSIZE", "64000K")

-- Application-specific settings
setenv("WRFIO_NCD_LARGE_FILE_SUPPORT", "1")
setenv("CESMDATAROOT",      "/glade/p/cesmdata/cseg")       -- Mariana/Jim
setenv("CESMROOT",          "/glade/p/cesm")
setenv("DASK_ROOT_CONFIG",  "/glade/u/apps/config/dask")    -- Joe Hamman

-- Set user's TMPDIR if not already set
if not tmpdir or not string.match(tmpdir, "^/glade") then
    setenv("TMPDIR", pathJoin("/glade/scratch", user))
end

-- System specific settings
setenv("NCAR_HOST",         "casper")
setenv("QSCACHE_SERVER",    "casper")

-- Make sure localization is set
setenv("LC_ALL",    "en_US.UTF-8")
setenv("LANG",      "en_US.UTF-8")

-- Add LD_LIBRARY_PATH for binaries
append_path("LD_LIBRARY_PATH", "/glade/u/apps/dav/opt/usr/lib64")

-- Cray PE container stuff
local cpebin = "/glade/u/apps/ch/opt/hpe-cpe/1.4.1/bin"
setenv("SENV_IMAGEROOT", "/glade/u/apps/ch/opt/hpe-cpe/1.4.1/1.4.1.sing")
append_path("PATH", cpebin)
append_path("PATH", "/glade/u/apps/ch/opt/hpe-cpe/21.09/bin")
{% endblock %}
