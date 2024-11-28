{% extends "ncar_default.lua" %}
{% block environment %}

conflict("ncarcompilers")

{{ super() }}
{% endblock %}
