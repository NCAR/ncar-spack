# This script can be used to add extra environment modifications
# to compiler definitions in Spack API 1.0

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from spack.vendor.ruamel.yaml.comments import CommentedMap
import os, sys

def deep_merge(p: dict, a: dict):
    """Recursively merges dict a into dict p"""
    for k in a:
        if k in p:
            if type(a[k]) == type(p[k]):
                if isinstance(p[k], dict):
                    deep_merge(p[k], a[k])
                else:
                    p[k] = a[k]
            else:
                raise TypeError("Deep merge conflict for key {}: type(p) = {}, type(a) = {}".format(k, type(p[k]), type(a[k])))
        else:
            p[k] = a[k]

if len(sys.argv) != 2:
    raise TypeError("Usage: mods.common.py COMPILER_SPEC")

#
## Environment Modifications
#

mods = CommentedMap()
mods["set"] = CommentedMap({    "NVCCFLAGS"             : "-allow-unsupported-compiler",
                                "NVCC_PREPEND_FLAGS"    : "-allow-unsupported-compiler" })

# First get our package input
comp_spec = sys.argv[1]

if "@" not in comp_spec:
    raise ValueError("Spec ({}) too general; should have version specifier".format(comp_spec))

spec_name = comp_spec.split("@")[0] 

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml.load(yaml_file)

try:
    for external in data["spack"]["packages"][spec_name]["externals"]:
        if external["spec"].startswith(comp_spec):
            if "environment" in external["extra_attributes"]:
                deep_merge(external["extra_attributes"]["environment"], mods)
            else:
                external["extra_attributes"]["environment"] = mods
except KeyError:
    sys.exit("Error: external {} not found in spack.yaml".format(spec_name))

# Write modified yaml to temporary file
with open(yaml_path, 'w') as yaml_file:
    yaml_file.write(yaml.dump(data))
