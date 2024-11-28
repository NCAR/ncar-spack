require("posix")
family("env")

-- The message printed by the module whatis command
whatis("spack-stack v%VERSION%")

-- The message printed by the module help command
help([[
This module provides access to the JSDCA-EMC spack-stack suite of
modules. These modules are NOT maintained or supported by CISL.
See https://spack-stack.readthedocs.io for more information.

Created on:     %DATE%
]])

-- A meta-module should be harder to remove
add_property("lmod", "sticky")

