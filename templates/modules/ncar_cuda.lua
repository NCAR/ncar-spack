{% extends "ncar_default.lua" %}
{% block environment %}

local cuda_major = {{spec.version.up_to(1)}}

setenv("CUDA_MAJOR_VERSION", cuda_major)

if cuda_major > 11 then
    conflict("cray-mpich/8.1.25")
end

{{ super() }}
{% endblock %}
