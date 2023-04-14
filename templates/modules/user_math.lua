{% extends "user_default.lua" %}
{% block footer %}

-- Set family to indicate math routines
family("mathpack")

{{ super() }}
{% endblock %}
