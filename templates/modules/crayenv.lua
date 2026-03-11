require("posix")
family("env")

-- The message printed by the module whatis command
whatis("crayenv v%VERSION%")

-- The message printed by the module help command
help([[
This module sets up an unmodified Cray Programming Environment shell
with Cray modules only and no NCAR customizations.

Based on CPE:   %VERSION%
Created on:     %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod","sticky")

-- Detect environment settings
local user      = capture("whoami")
local tmpdir    = os.getenv("TMPDIR")
local othreads  = os.getenv("OMP_NUM_THREADS")

-- Default OpenMP environment
if not othreads then
    setenv("OMP_NUM_THREADS", "1")
end

-- Set user's TMPDIR if not already set
if not tmpdir or not string.match(tmpdir, "^/glade") then
    setenv("TMPDIR", pathJoin("%TMPROOT%", user))
end

-- Loading this module unlocks the CPE module tree
append_path("MODULEPATH", "%MODPATH%")

-- Add Spack-installed compilers for use with PrgEnvs
local spack_modules = "%SPACKMODS%"

if spack_modules then
    append_path("MODULEPATH", spack_modules)
end

-- Add Lmod settings
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "%DEFMODS%")
