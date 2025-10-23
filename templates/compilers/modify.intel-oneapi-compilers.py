# This script can be used to add extra environment modifications
# to compiler definitions in Spack API 1.0

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from spack.vendor.ruamel.yaml.comments import CommentedMap
import os, sys

if len(sys.argv) != 3:
    raise TypeError("Usage: modify.intel-oneapi-compilers.py COMPILER_SPEC COMPILER_ROOT")

#
## Environment Modifications
#

# First get our package input
comp_spec = sys.argv[1]
comp_root = sys.argv[2]

if "@" not in comp_spec:
    raise ValueError("Spec ({}) too general; should have version specifier".format(comp_spec))

spec_name, spec_version = comp_spec.split("@")
spec_version = spec_version.rsplit(".", 1)[0]

mods = CommentedMap()
mods["compilers"] = CommentedMap({  "c"         : f"{comp_root}/compiler/{spec_version}/bin/icx",
                                    "cxx"       : f"{comp_root}/compiler/{spec_version}/bin/icpx",
                                    "fortran"   : f"{comp_root}/compiler/{spec_version}/bin/ifx" })

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml.load(yaml_file)

try:
    for external in data["spack"]["packages"][spec_name]["externals"]:
        if external["spec"].startswith(comp_spec):
            external["extra_attributes"] = mods
except KeyError:
    sys.exit("Error: external {} not found in spack.yaml".format(spec_name))

# Write modified yaml to temporary file
with open(yaml_path, 'w') as yaml_file:
    yaml_file.write(yaml.dump(data))
