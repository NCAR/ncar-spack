{% extends "ncar_default.lua" %}
{% block footer %}

-- Reload modules that depend on state to avoid intel switching issues
local mpi_name = os.getenv("LMOD_FAMILY_MPI")

if mpi_name then
    always_load(mpi_name .. "/" .. os.getenv("LMOD_FAMILY_MPI_VERSION"))
end

if isloaded("ncarcompilers") then
    always_load("ncarcompilers")
end
{% endblock %}
