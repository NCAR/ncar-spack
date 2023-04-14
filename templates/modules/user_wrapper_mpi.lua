{% extends "user_default.lua" %}
{% block footer %}

-- If wrapper is loaded, make sure mpi wrappers are removed at unload
local wrapper_path = os.getenv("NCAR_WRAPPER_MPI_PATH")

if wrapper_path then
    prepend_path("PATH", wrapper_path)
end

-- Finally, do BUILD_ENV here since Spack doesn't support pushenv
local compiler_env = os.getenv("NCAR_BUILD_ENV_COMPILER")
pushenv("NCAR_BUILD_ENV", compiler_env .. "-{{ spec.name }}-{{ spec.version }}")

{{ super() }}
{% endblock %}
