require("posix")
family("env")

-- The message printed by the module whatis command
whatis("ncarenv-basic v%VERSION%")

-- The message printed by the module help command
help([[
This module sets up a basic version of our NCAR environment. It
provides access to our module tree, but otherwise does not add
any utilities or base packages to your shell environment.

Based on CPE:   %VERSION%
Created on:     %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod","sticky")

-- System specific settings
setenv("NCAR_ENV_VERSION",  "%VERSION%")
setenv("NCAR_HOST",         "%HOST%")

-- Loading this module unlocks the NCAR Spack module tree
append_path("MODULEPATH", "%MODPATH%")

-- Add Lmod settings
setenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
setenv("LMOD_AVAIL_STYLE", "grouped:system")
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "ncarenv-basic/%VERSION%")

-- Ensure modules load in subshells
setenv("ENV", "/etc/profile.d/modules.sh")
