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
pushenv("LMOD_PACKAGE_PATH", "%UTILPATH%")
pushenv("LMOD_AVAIL_STYLE", "grouped:system")
pushenv("LMOD_SYSTEM_DEFAULT_MODULES", "ncarenv-basic/%VERSION%")

-- Ensure modules load in subshells
setenv("ENV", "/etc/profile.d/modules.sh")

-- Set number of GPUs (analogous to NCPUS)
if os.getenv("PBS_JOBID") then
    local num_gpus = subprocess("nvidia-smi -L |& grep -c UUID"):gsub("\n$","")
    setenv("NGPUS", num_gpus)

    if tonumber(num_gpus) > 0 then
        setenv("MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED", "1")
    end
end
