{% extends "ncar_default.lua" %}
{% block footer %}

-- Set prerequisites and conflicts
conflict("python")

-- Define paths for functions/aliases below
local initpath = pathJoin("{{spec.prefix}}", "etc/profile.d")
local ncarpath = pathJoin("{{spec.prefix}}", "ncarbin")

-- Update path variables in user environment
prepend_path("PATH",        pathJoin("{{spec.prefix}}", "condabin"))
prepend_path("MANPATH",     pathJoin("{{spec.prefix}}", "share/man"))
prepend_path("INFOPATH",    pathJoin("{{spec.prefix}}", "share/info"))

-- Add conda alias to allow activation when not init in current shell
-- This messy method ensures it works in shell scripts too
if myShellType() == "sh" then
    execute { cmd = "if type -t conda |& grep -q -v function; then function conda { . " .. ncarpath .. "/conda.sh ; }; fi", modeA = { "load" }}
    execute { cmd = "if type conda |& grep -q " .. ncarpath .. ' || [ -n "${NCAR_CONDA_INIT:+x}" ]; then unset -f conda; unset NCAR_CONDA_INIT; fi', modeA = { "unload" }}
    execute { cmd = "if type -t mamba |& grep -q -v function; then function mamba { . " .. ncarpath .. "/mamba.sh ; }; fi", modeA = { "load" }}
    execute { cmd = "if type mamba |& grep -q " .. ncarpath .. ' || [ -n "${NCAR_MAMBA_INIT:+x}" ]; then unset -f mamba; unset NCAR_MAMBA_INIT; fi', modeA = { "unload" }}
else
    execute { cmd = "alias conda |& grep -q source || alias conda 'source " .. initpath .. "/conda.csh'", modeA = { "load" }}
    execute { cmd = "alias conda |& grep -q " .. initpath .. " && unalias conda", modeA = { "unload" }}

    -- If prompt is not set, we need to set it so conda init script doesn't break
    local csh_prompt = os.getenv("prompt")
    
    if not csh_prompt then
        setenv("prompt", "")
    end
end
{% endblock %}
