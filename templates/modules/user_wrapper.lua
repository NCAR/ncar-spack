{% extends "user_default.lua" %}
{% block footer %}

if os.getenv("LMOD_FAMILY_MPI") then
    prepend_path("PATH", pathJoin("{{spec.prefix.bin}}", "mpi"))
end

-- Special logic for intel modules
local comp_name = os.getenv("LMOD_FAMILY_COMPILER")

if (comp_name == "intel") then
    setenv("FC",    "ifort")
    setenv("F77",   "ifort")
elseif (comp_name == "intel-classic") then
    setenv("CC",    "icc")
    setenv("CXX",   "icpc")
    setenv("FC",    "ifort")
    setenv("F77",   "ifort")
end

{{ super() }}
{% endblock %}
