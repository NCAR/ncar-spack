{% extends "ncar_default.lua" %}
{% block autoloads %}

-- Require CUDA module
prereq("cuda")

{{ super() }}
{% endblock %}
