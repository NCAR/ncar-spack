{% extends "ncar_default.lua" %}
{% block footer %}

-- Set prerequisites and conflicts
conflict("python")

-- Define paths for functions/aliases below
local basepath = "{{spec.prefix}}"
local binpath  = pathJoin(basepath, "condabin")
local initpath = pathJoin(basepath, "etc/profile.d")

-- Determine whether user already has miniconda initialized
local my_conda = os.getenv("NCAR_USER_CONDA")
local my_shell = myShellType()

if not my_conda then
    my_conda = os.getenv("CONDA_EXE") or ""

    if my_conda ~= "" then
        my_conda = my_conda:gsub("/bin/conda$", "")
    end
end

if my_conda ~= basepath then
    setenv("NCAR_USER_CONDA", my_conda)
end

-- If csh prompt is not set, we need to set it so conda init script doesn't break
if my_shell == "csh" then
    if not os.getenv("prompt") then
        setenv("prompt", "")
    end
end

-- Use NCAR conda while this module is loaded
prepend_path("PATH", binpath)

if my_shell == "sh" or my_shell == "csh" then
    source_sh(my_shell:gsub("^sh$","bash"), pathJoin(initpath, "conda." .. my_shell))
end

if my_conda ~= "" and my_conda ~= basepath then
    if my_shell == "sh" then
        execute { cmd = ". " .. pathJoin(my_conda, "etc/profile.d/conda.sh"), modeA = { "unload" }}
    elseif my_shell == "csh" then
        execute { cmd = "source " .. pathJoin(my_conda, "etc/profile.d/conda.csh"), modeA = { "unload" }}
    end
end
{% endblock %}
