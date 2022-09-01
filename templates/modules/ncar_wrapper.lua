{% extends "ncar_default.lua" %}
{% block footer %}

if os.getenv("LMOD_FAMILY_MPI") then
    prepend_path("PATH", pathJoin("{{spec.prefix.bin}}", "mpi"))
end
{% endblock %}
