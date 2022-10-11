{% extends "ncar_default.lua" %}
{% block footer %}

-- If wrapper is loaded, make sure mpi wrappers are removed at unload
local wrapper_path = os.getenv("NCAR_WRAPPER_MPI_PATH")

if wrapper_path then
    prepend_path("PATH", wrapper_path)
end
{% endblock %}
