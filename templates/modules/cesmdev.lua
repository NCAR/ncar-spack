-- The message printed by the module whatis command
whatis("cesmdev v1.0")

-- The message printed by the module help command
help([[
This module will add a custom MODULEROOT to the user's visible
module tree - providing access to beta and debug versions of libraries
commonly used by CESM cases.

Created on:     %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod", "sticky")

-- Enable custom modules from CSEG downstream
append_path("NCAR_VARS_MODULEROOT", "NCAR_MODULEROOT_CSEG")
setenv("NCAR_MODULEROOT_CSEG", pathJoin("/glade/u/apps/cseg/modules"))
