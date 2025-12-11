# This script can be used to add external package definitions given
# by the constraints.cfg listing. It should get an external as command-line
# arguments from the add_constraints script.

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from spack.vendor.ruamel.yaml.comments import CommentedMap
import os, sys

if len(sys.argv) != 5:
    raise TypeError("add_external.py takes 4 arguments ({} given)".format(len(sys.argv) - 1))

# First get our package input
pkg_spec = sys.argv[1]
pkg_type = sys.argv[2]
pkg_path = sys.argv[3]
pkg_name = pkg_spec.split("@")[0]

# Scope determines while file to use
yaml_scope = sys.argv[4]

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]

if yaml_scope == "spack":
    yaml_path = f"{env_dir}/spack.yaml"
else:
    yaml_path = f"{env_dir}/includes/{yaml_scope}.yaml"

try:
    with open(yaml_path, 'r') as yaml_file:
        all_data = yaml.load(yaml_file)

        if yaml_scope == "spack":
            data = all_data["spack"]
        else:
            data = all_data
except FileNotFoundError:
    all_data = CommentedMap({"packages" : CommentedMap()})
    data = all_data

mod_yaml = False

# Create external definition for insertion if not found
ext_dict = [{ 'spec' : pkg_spec, 'prefix': pkg_path }]

if pkg_name in data["packages"]:
    if "externals" in data["packages"][pkg_name]:
        if not any(ext["spec"] == pkg_spec for ext in data["packages"][pkg_name]["externals"]):
            data["packages"][pkg_name]["externals"] += ext_dict
            mod_yaml = True
    else:
        data["packages"][pkg_name]["externals"] = ext_dict
        mod_yaml = True
else:
    data["packages"][pkg_name] = { "externals" :  ext_dict }
    mod_yaml = True

# Write modified yaml to template
if mod_yaml:
    # Set buildable status first
    data["packages"][pkg_name]["buildable"] = pkg_type == "buildable"

    with open(yaml_path, 'w') as yaml_file:
        yaml_file.write(yaml.dump(all_data))
else:
    sys.exit(1)
