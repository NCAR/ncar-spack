-- The message printed by the module whatis command
whatis("debug-compile v%VERSION%")

-- The message printed by the module help command
help([[
This module will prompt the ncarcompilers wrapper to inject debug flags
into your application builds for as long as both modules are loaded. This
functionality is intended to make building with debug flags easier when
using applications with complex build systems.

Created on:     %DATE%
]])

-- Will only work with newer versions of ncarcompilers wrapper
depends_on(atleast("ncarcompilers", "1.2.0"))

-- These default debug flags can be overridden by other modules
setenv("NCAR_MFLAGS_DEBUG", "-g")
setenv("NCAR_WRAPPER_MFLAGS_DEBUG", "1")
