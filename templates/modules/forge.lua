{% extends "ncar_default.lua" %}
{% block environment %}

-- Forge Cray PALS launching fails when atp module is also loaded
conflict("atp")

{{ super() }}
{% endblock %}
