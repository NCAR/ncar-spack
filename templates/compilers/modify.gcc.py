# This script can be used to add extra environment modifications
# to compiler definitions in Spack API 1.0

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from spack.vendor.ruamel.yaml.comments import CommentedMap
import os, sys

script_name = os.path.basename(__file__)

if len(sys.argv) != 4:
    raise TypeError(f"Usage: {script_name} COMPILER_SPEC COMPILER_ROOT SCOPE")

#
## Environment Modifications
#

# First get our package input
comp_spec = sys.argv[1]
comp_root = sys.argv[2]
yaml_scope = sys.argv[3]

if "@" not in comp_spec:
    raise ValueError(f"Spec ({comp_spec}) too general; should have version specifier")

spec_name, spec_version = comp_spec.split("@")

mods = CommentedMap()

if "gcc" in script_name:
    mods["compilers"] = CommentedMap({  "c"         : f"{comp_root}/bin/gcc",
                                        "cxx"       : f"{comp_root}/bin/g++",
                                        "fortran"   : f"{comp_root}/bin/gfortran" })
elif "llvm" in script_name or "aocc" in script_name:
    mods["compilers"] = CommentedMap({  "c"         : f"{comp_root}/bin/clang",
                                        "cxx"       : f"{comp_root}/bin/clang++",
                                        "fortran"   : f"{comp_root}/bin/flang" })
elif "intel-oneapi" in script_name:
    mods["compilers"] = CommentedMap({  "c"         : f"{comp_root}/compiler/{spec_version}/bin/icx",
                                        "cxx"       : f"{comp_root}/compiler/{spec_version}/bin/icpx",
                                        "fortran"   : f"{comp_root}/compiler/{spec_version}/bin/ifx" })
elif "nvhpc" in script_name:
    mods["compilers"] = CommentedMap({  "c"         : f"{comp_root}/Linux_x86_64/{spec_version}/compilers/bin/nvc",
                                        "cxx"       : f"{comp_root}/Linux_x86_64/{spec_version}/compilers/bin/nvc++",
                                        "fortran"   : f"{comp_root}/Linux_x86_64/{spec_version}/compilers/bin/nvfortran" })

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]

if yaml_scope == "spack":
    yaml_path = f"{env_dir}/spack.yaml"
else:
    yaml_path = f"{env_dir}/includes/{yaml_scope}.yaml"

with open(yaml_path, 'r') as yaml_file:
    all_data = yaml.load(yaml_file)

    if yaml_scope == "spack":
        data = all_data["spack"]
    else:
        data = all_data

try:
    for external in data["packages"][spec_name]["externals"]:
        if external["spec"].startswith(comp_spec):
            external["extra_attributes"] = mods
except KeyError:
    sys.exit(f"Error: external {spec_name} not found in {yaml_scope}.yaml")

# Write modified yaml to temporary file
with open(yaml_path, 'w') as yaml_file:
    yaml_file.write(yaml.dump(all_data))
