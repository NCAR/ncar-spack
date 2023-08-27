# This script can be used to set requirements on packages defined
# in the constraints.cfg listing. It should get packages as command-line
# arguments from the add_constraints script.

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
import os, sys, copy

if len(sys.argv) < 3:
    raise TypeError("add_requirement.py takes 2+ arguments ({} given)".format(len(sys.argv) - 1))

# First get our package name input
new_req = sys.argv[1]
pkg_list = sys.argv[2:]

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml.load(yaml_file)

mod_list = []

for pkg_name in pkg_list:
    if pkg_name in data["spack"]["packages"]:
        if "require" in data["spack"]["packages"][pkg_name]:
            old_req = data["spack"]["packages"][pkg_name]["require"]

            if isinstance(old_req, str):
                data["spack"]["packages"][pkg_name]["require"] = [old_req]

                if old_req != new_req:
                    data["spack"]["packages"][pkg_name]["require"].append(new_req)
                    mod_list.append(pkg_name)
            elif new_req not in data["spack"]["packages"][pkg_name]["require"]:
                data["spack"]["packages"][pkg_name]["require"].append(new_req)
                mod_list.append(pkg_name)
        else:
            data["spack"]["packages"][pkg_name]["require"] = [new_req]
            mod_list.append(pkg_name)
    else:
        data["spack"]["packages"][pkg_name] = { "require" : [new_req] }
        mod_list.append(pkg_name)

# Write modified yaml
if mod_list:
    with open(yaml_path, 'w') as yaml_file:
        yaml_file.write(yaml.dump(data))

    print(*mod_list)
