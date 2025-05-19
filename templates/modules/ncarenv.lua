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
local user      = capture("whoami"):gsub("\n$","")
local othreads  = os.getenv("OMP_NUM_THREADS")

local syspath   = os.getenv("NCAR_DEFAULT_PATH")
local sysman    = os.getenv("NCAR_DEFAULT_MANPATH")
local sysinfo   = os.getenv("NCAR_DEFAULT_INFOPATH")

-- Base shell environment packages and utilities
local basepath      = "%BASEROOT%"
local viewpath      = pathJoin(basepath, "view")

-- System specific settings
setenv("NCAR_ENV_VERSION",  "%VERSION%")
setenv("NCAR_HOST",         "%HOST%")
setenv("QSCACHE_SERVER",    "%HOST%")

-- Spack settings
local envpath = "%ENVROOT%"
setenv("NCAR_ENV_CONFIG",   pathJoin(envpath, "config"))
setenv("NCAR_ENV_SPACK",    pathJoin(envpath, "spack"))
setenv("NCAR_ENV_REGISTRY", pathJoin(envpath, "registry"))
setenv("NCAR_ENV_HASH",     "%GITHASH%")

-- Globus collection UUIDS
setenv("NCAR_GLOBUS_GLADE",     "d33b3614-6d04-11e5-ba46-22000b92c6ec")
setenv("NCAR_GLOBUS_CAMPAIGN",  "6b5ab960-7bbf-11e8-9450-0a6d4e044368")
setenv("NCAR_GLOBUS_AWS",       "3a1f3e98-1a93-11e9-9f9f-0a06afd4a22e")
setenv("NCAR_GLOBUS_QUASAR",    "58bc6c98-8bba-11e9-b808-0a37f382de32")
setenv("NCAR_GLOBUS_STRATUS",   "b9cf5e6c-9245-11eb-b7a4-f57b2d55370d")
setenv("NCAR_GLOBUS_DSS",       "dd1ee92a-6d04-11e5-ba46-22000b92c6ec")
setenv("NCAR_GLOBUS_GDRIVE",    "397f7166-9af5-402f-abfc-c3b184d609ba")

-- Enable modules from developer trees
local mroot_vars = os.getenv("NCAR_VARS_MODULEROOT")

if (mode() == "load") then
    if mroot_vars then
        setenv("__NCAR_VARS_MODULEROOT", mroot_vars)

        for var in string.gmatch(mroot_vars, "[^:]+") do
            local mroot = os.getenv(var)

            if mroot then
                setenv("__" .. var, pathJoin(mroot, "%VERSION%"))
            end
        end
    else
        unsetenv("__NCAR_VARS_MODULEROOT")
    end
end

-- Enable custom modules from downstreams
local is_set    = os.getenv("NCAR_MODULEROOT_USER")
local was_set   = os.getenv("__NCARENV_MODULEROOT_USER")
local old_value = os.getenv("__NCAR_MODULEROOT_USER")

if was_set or not is_set then
    mroot = pathJoin("/glade/work", user, "spack-downstreams/%HOST%/modules/%VERSION%")
    setenv("__NCARENV_MODULEROOT_USER", 1)
    
    -- Only unset if user has not changed value in the interim
    if (mode() == "load") or (is_set == old_value) then
        setenv("NCAR_MODULEROOT_USER", mroot)
    end
else
    mroot = is_set
end

append_path("NCAR_VARS_MODULEROOT", "NCAR_MODULEROOT_USER")

-- We need this variable to ensure modulepaths are unset correctly at swap
if (mode() == "load") then
    setenv("__NCAR_MODULEROOT_USER", mroot)
    append_path("__NCAR_VARS_MODULEROOT", "NCAR_MODULEROOT_USER")
end

-- Add custom Core paths
local mroot_vars = os.getenv("__NCAR_VARS_MODULEROOT")

if mroot_vars then
    for var in string.gmatch(mroot_vars, "[^:]+") do
        local mroot = os.getenv("__" .. var)

        if mroot then
            append_path("MODULEPATH", pathJoin(mroot, "Core"))
        end
    end
end

-- Loading this module unlocks the NCAR Spack module tree
append_path("MODULEPATH", "%MODPATH%")

-- Add Lmod settings
pushenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
pushenv("LMOD_CONFIG_DIR",   "%UTILPATH%")
pushenv("LMOD_AVAIL_STYLE",  "grouped:system")
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "%DEFMODS%")
pushenv("LMOD_MODULERCFILE", "%MODRC%")

-- Ensure modules load in subshells
setenv("ENV", "/etc/profile.d/modules.sh")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

setenv("OMP_STACKSIZE", "64000K")

-- qhist config file
setenv("QHIST_SERVER_CONFIG", "/glade/u/apps/config/qhist/%HOST%.json")

-- System-wide MPI settings
setenv("FI_CXI_RX_MATCH_MODE", "hybrid")

-- Model-specific settings
setenv("WRFIO_NCD_LARGE_FILE_SUPPORT", "1")
setenv("CESMDATAROOT", "/glade/campaign/cesm/cesmdata")

-- Set user's TMPDIR if not already set
local is_set    = os.getenv("TMPDIR")
local was_set   = os.getenv("__NCARENV_TMPDIR")
local scratch   = pathJoin("/glade/derecho/scratch", user)

if was_set or not is_set or not string.match(is_set, "^/glade") then
    local exists = subprocess("bash -c 'timeout 5 test -d " .. scratch .. " && echo yes'"):gsub("\n$","")

    if exists == "yes" then
        local tmpdir = pathJoin(scratch, "tmp")
        execute {cmd="mkdir -p " .. tmpdir, modeA={"load"}}
        setenv("TMPDIR", tmpdir)
        setenv("__NCARENV_TMPDIR", 1)
    end
end

-- Set file-system variables (but do not clobber common ones)
setenv("CHEYENNE_SCRATCH",  pathJoin("/glade/cheyenne/scratch", user))
setenv("LARAMIE_SCRATCH",   pathJoin("/picnic/scratch", user))
setenv("DERECHO_SCRATCH",   scratch)
setenv("GUST_SCRATCH",      pathJoin("/glade/gust/scratch", user))

local is_set    = os.getenv("WORK")
local was_set   = os.getenv("__NCARENV_WORK")

if was_set or not is_set then
    setenv("WORK", pathJoin("/glade/work", user))
    setenv("__NCARENV_WORK", 1)
end

local is_set    = os.getenv("SCRATCH")
local was_set   = os.getenv("__NCARENV_SCRATCH")

if was_set or not is_set then
    setenv("SCRATCH", scratch)
    setenv("__NCARENV_SCRATCH", 1)
end

-- Make sure localization is set
pushenv("LC_ALL",    "en_US.UTF-8")
pushenv("LANG",      "en_US.UTF-8")

-- Specify certificate behavior for curl
pushenv("CURL_SSL_BACKEND", "openssl")
pushenv("CURL_CA_BUNDLE", "/etc/ssl/ca-bundle.pem")

-- Add base packages utilities to PATHS
prepend_path("PATH",            pathJoin(basepath, "utils/bin"))
append_path("PATH",             pathJoin(viewpath, "bin"))
append_path("MANPATH",          pathJoin(viewpath, "man"))
append_path("MANPATH",          pathJoin(viewpath, "share/man"))
append_path("INFOPATH",         pathJoin(viewpath, "share/info"))
append_path("ACLOCAL_PATH",     pathJoin(viewpath, "share/aclocal"))

setenv("NCAR_INC_0_COMMON",       pathJoin(viewpath, "include"))
setenv("NCAR_LDFLAGS_0_COMMON",   pathJoin(viewpath, "lib"))
setenv("NCAR_LDFLAGS_0_COMMON64", pathJoin(viewpath, "lib64"))

prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib64/pkgconfig"))

-- Make sure system versions come after Spack versions (save aclocal)
append_path("PATH",             syspath)
append_path("MANPATH",          sysman)
append_path("INFOPATH",         sysinfo)
prepend_path("ACLOCAL_PATH",    "/usr/share/aclocal")

-- Add PERL library from the base
append_path("PERL5LIB", pathJoin(basepath, "perl/lib/perl5"))

-- Make sure Spack Vim uses system vim defaults
pushenv("VIM", "/glade/u/apps/config/vim")

-- Set number of GPUs (analogous to NCPUS)
if os.getenv("PBS_JOBID") then
    local num_gpus = subprocess("nvidia-smi -L |& grep -c UUID"):gsub("\n$","")
    setenv("NGPUS", num_gpus)

    if tonumber(num_gpus) > 0 then
        setenv("MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED", "1")
    end
end
