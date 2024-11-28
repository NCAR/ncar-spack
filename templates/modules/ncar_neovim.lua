{% extends "ncar_default.lua" %}
{% block environment %}

-- Vim settings cause many issues for neovim
pushenv("VIM", "")

{{ super() }}
{% endblock %}
