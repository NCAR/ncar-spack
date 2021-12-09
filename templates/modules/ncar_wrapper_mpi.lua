{% extends "ncar_default.lua" %}
{% block footer %}
-- If compiler wrappers are loaded, prepend the path with MPI symlinks
if (isloaded("ncarcompilers")) then
    local ncarpath = os.getenv("NCAR_WRAPPER_MPI") or ""
    prepend_path("PATH", ncarpath)
end
{% endblock %}
