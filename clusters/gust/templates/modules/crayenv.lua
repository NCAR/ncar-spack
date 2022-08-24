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
    setenv("TMPDIR", pathJoin("/glade/gust/scratch", user))
end

-- Loading this module unlocks the CPE module tree
append_path("MODULEPATH", "%MODPATH%")
