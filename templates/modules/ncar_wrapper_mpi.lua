{% extends "ncar_default.lua" %}
{% block footer %}

-- If wrapper is loaded, make sure mpi wrappers are removed at unload
local wrapper_path = os.getenv("NCAR_WRAPPER_MPI_PATH")

if wrapper_path then
    remove_path("PATH", wrapper_path)
end

-- If ncarcompilers is loaded, reload it to keep forward
if isloaded("ncarcompilers") then
    always_load("ncarcompilers")
end
{% endblock %}
