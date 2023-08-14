{% extends "user_default.lua" %}
{% block environment %}

setenv("CUDA_MAJOR_VERSION", "{{spec.version.up_to(1)}}")

{{ super() }}
{% endblock %}
