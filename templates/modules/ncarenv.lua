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
    mroot = pathJoin("/glade/work", user, "spack-downstreams/modules/%VERSION%")
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
setenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
setenv("LMOD_CONFIG_DIR",   "%UTILPATH%")
setenv("LMOD_AVAIL_STYLE",  "grouped:system")
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
setenv("CESMDATAROOT", "/glade/p/cesmdata")

-- Set user's TMPDIR if not already set
local is_set    = os.getenv("TMPDIR")
local was_set   = os.getenv("__NCARENV_TMPDIR")

if was_set or not is_set or not string.match(is_set, "^/glade") then
    local tmpdir = pathJoin("%TMPROOT%", user, "tmp")
    setenv("TMPDIR", tmpdir)
    setenv("__NCARENV_TMPDIR", 1)

    if not isDir(tmpdir) then
        execute { cmd = "mkdir -p " .. tmpdir, modeA = { "load" } }
    end
end

-- Set file-system variables (but do not clobber common ones)
setenv("CHEYENNE_SCRATCH",  pathJoin("/glade/cheyenne/scratch", user))
setenv("LARAMIE_SCRATCH",   pathJoin("/picnic/scratch", user))
setenv("DERECHO_SCRATCH",   pathJoin("/glade/derecho/scratch", user))
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
    setenv("SCRATCH", pathJoin("%TMPROOT%", user))
    setenv("__NCARENV_SCRATCH", 1)
end

-- Make sure localization is set
setenv("LC_ALL",    "en_US.UTF-8")
setenv("LANG",      "en_US.UTF-8")

-- Add base packages utilities to PATHS
prepend_path("PATH",            pathJoin(basepath, "utils/bin"))
append_path("PATH",             pathJoin(viewpath, "bin"))
append_path("MANPATH",          pathJoin(viewpath, "man"))
append_path("MANPATH",          pathJoin(viewpath, "share/man"))
append_path("INFOPATH",         pathJoin(viewpath, "share/info"))

setenv("NCAR_INC_0_COMMON",       pathJoin(viewpath, "include"))
setenv("NCAR_LDFLAGS_0_COMMON",   pathJoin(viewpath, "lib"))
setenv("NCAR_LDFLAGS_0_COMMON64", pathJoin(viewpath, "lib64"))

prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(viewpath, "lib64/pkgconfig"))

-- Make sure system versions come after Spack versions
append_path("PATH",             syspath)
append_path("MANPATH",          sysman)
append_path("INFOPATH",         sysinfo)

-- Add PERL library from the base
append_path("PERL5LIB", pathJoin(basepath, "perl/lib/perl5"))
