{% extends "ncar_default.lua" %}
{% block footer %}
conflict("{{ spec.name }}-mpi")
{% endblock %}
