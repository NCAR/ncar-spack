# This script takes an active production spack.yaml file and cleans it
# up so that it can be used within a cluster template by ncar-spack
# deployment scripts.
#
# This script should be called by templatize_yaml, which is a wrapper
# that sets up the environment.

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
import os, re, copy

# Packages to exclude when pruning externals
excluded_pkgs = ["openpbs", "cray-libsci", "cray-mpich", "miniconda3"]

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)
temp_path = "{}/templates/yaml/spack.yaml".format(env_dir)
os.makedirs("{}/templates/yaml".format(env_dir), exist_ok = True)

tmproot = os.environ["NCAR_SPACK_TMPROOT"]
deployment = "{}/{}".format(os.environ["NCAR_SPACK_HOST"], os.environ["NCAR_SPACK_HOST_VERSION"])

with open(yaml_path, 'r') as yaml_file:
    raw = yaml.load_config(yaml_file)

# We need to operate on a deep copy since we will modify the dictionary
data = copy.deepcopy(raw)

# Make modifications to fields to generalize yaml file
for key in raw["spack"]:
    if key == "config":
        for subkey in raw["spack"][key]:
            if subkey == "template_dirs":
                del data["spack"][key][subkey]
            elif subkey == "install_tree":
                if "root" in raw["spack"][key][subkey]:
                    data["spack"][key][subkey]["root"] = "%INSTALLROOT%"
                if "projections" in raw["spack"][key][subkey]:
                    data["spack"][key][subkey]["projections"] = dict(sorted(data["spack"][key][subkey]["projections"].items(), key=lambda item: item[0]))
            elif "_cache" in subkey or subkey == "test_stage":
                data["spack"][key][subkey] = data["spack"][key][subkey].replace(tmproot, "%TMPROOT%").replace(deployment, "%DEPLOYMENT%")
            elif subkey == "build_stage":
                data["spack"][key][subkey] = [item.replace(tmproot, "%TMPROOT%").replace(deployment, "%DEPLOYMENT%") for item in data["spack"][key][subkey]]
    elif key == "packages":
        for subkey in raw["spack"][key]:
            keep_pkg = False

            for pkgkey in raw["spack"][key][subkey]:
                if pkgkey in ["externals", "buildable"]:
                    if subkey not in excluded_pkgs:
                        del data["spack"][key][subkey][pkgkey]
                    else:
                        keep_pkg = True
                else:
                    keep_pkg = True

                    if pkgkey == "variants":
                        data["spack"][key][subkey][pkgkey] = sorted(data["spack"][key][subkey][pkgkey])

            if not keep_pkg:
                del data["spack"][key][subkey]

        data["spack"][key] = dict(sorted(data["spack"][key].items(), key=lambda item: item[0]))
    elif key == "view":
        for subkey in raw["spack"][key]:
            if "root" in raw["spack"][key][subkey]:
                data["spack"][key][subkey]["root"] = "%BASEROOT%/view"
            if "select" in raw["spack"][key][subkey]:
                data["spack"][key][subkey]["select"] = ["git"]
    elif key == "compilers":
        data["spack"][key] = []
    elif key == "modules":
        for mset in raw["spack"][key]:
            for subkey in raw["spack"][key][mset]:
                if subkey == "roots":
                    data["spack"][key][mset][subkey]["lmod"] = "%MODULESROOT%"
                elif subkey == "lmod":
                    for modkey in raw["spack"][key][mset][subkey]:
                        if modkey == "exclude":
                            data["spack"][key][mset][subkey][modkey] = ["lmod"]
                        elif isinstance(data["spack"][key][mset][subkey][modkey], dict):
                            for var in ["environment", "filter"]:
                                if var in data["spack"][key][mset][subkey][modkey]:
                                    for envkey in data["spack"][key][mset][subkey][modkey][var]:
                                        if var == "environment":
                                            data["spack"][key][mset][subkey][modkey][var][envkey] = dict(sorted(data["spack"][key][mset][subkey][modkey][var][envkey].items(), key=lambda item: item[0]))
                                        elif var == "filter":
                                            data["spack"][key][mset][subkey][modkey][var][envkey] = sorted(data["spack"][key][mset][subkey][modkey][var][envkey])

                    data["spack"][key][mset][subkey] = dict(sorted(data["spack"][key][mset][subkey].items(), key=lambda item: item[0]))
    elif key in ["mirrors", "repos", "specs", "bootstrap"]:
        del data["spack"][key]

# Write modified yaml to template
with open(temp_path, 'w') as temp_file:
    yaml.dump_config(data, temp_file)
