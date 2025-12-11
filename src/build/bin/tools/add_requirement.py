# This script can be used to set requirements on packages defined
# in the constraints.cfg listing. It should get packages as command-line
# arguments from the add_constraints script.

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from spack.vendor.ruamel.yaml.comments import CommentedMap
import os, sys, copy

if len(sys.argv) < 4:
    raise TypeError("add_requirement.py takes 4+ arguments ({} given)".format(len(sys.argv) - 1))

# First get our package name input
new_req = sys.argv[1]
req_type = sys.argv[2]
yaml_scope = sys.argv[3]
pkg_list = sys.argv[4:]

if req_type not in ("require", "prefer"):
    raise "Requirement type must be either 'require' or 'prefer' ({} given)".format(req_type)

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

mod_list = []

for pkg_name in pkg_list:
    if pkg_name in data["packages"]:
        if req_type in data["packages"][pkg_name]:
            old_req = data["packages"][pkg_name][req_type]

            if isinstance(old_req, str):
                data["packages"][pkg_name][req_type] = [old_req]

                if old_req != new_req:
                    data["packages"][pkg_name][req_type].append(new_req)
                    mod_list.append(pkg_name)
            elif new_req not in data["packages"][pkg_name][req_type]:
                data["packages"][pkg_name][req_type].append(new_req)
                mod_list.append(pkg_name)
        else:
            data["packages"][pkg_name][req_type] = [new_req]
            mod_list.append(pkg_name)
    else:
        data["packages"][pkg_name] = { req_type : [new_req] }
        mod_list.append(pkg_name)

# Write modified yaml
if mod_list:
    with open(yaml_path, 'w') as yaml_file:
        yaml_file.write(yaml.dump(all_data))

    print(*mod_list)
