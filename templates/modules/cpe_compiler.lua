{% extends "modules/modulefile.lua" %}
{% block footer %}

-- Conflict with PrgEnv-* modules that do not support this compiler
-- If block logic doesn't require updating for any new PRGENV-* modules added in future
local PE_MODULE = "PrgEnv-" .. os.getenv("PRGENV")

if os.getenv("LMOD_FAMILY_PRGENV") ~= nil then
    if (not isloaded(PE_MODULE)) then
        load(PE_MODULE)
    end
end
{% endblock %}
