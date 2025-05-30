{% extends "user_default.lua" %}
{% block environment %}

conflict("chapel")

{{ super() }}
{% endblock %}
{% block footer %}

if os.getenv("LMOD_FAMILY_MPI") then
    prepend_path("PATH", pathJoin("{{spec.prefix.bin}}", "mpi"))
end

-- Special logic for intel modules
local comp_name = os.getenv("LMOD_FAMILY_COMPILER")
local comp_major = {{spec.compiler.version.up_to(1)}}

if comp_major < 2025 then
    if (comp_name == "intel") then
        pushenv("FC",    "ifort")
        pushenv("F77",   "ifort")
    elseif (comp_name == "intel-classic") then
        pushenv("CC",    "icc")
        pushenv("CXX",   "icpc")
        pushenv("FC",    "ifort")
        pushenv("F77",   "ifort")
    elseif (comp_name == "intel-oneapi") then
        pushenv("FC",    "ifx")
        pushenv("F77",   "ifx")
    end
end

{{ super() }}
{% endblock %}
