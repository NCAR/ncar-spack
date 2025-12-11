# This script takes an active production spack.yaml file and cleans it
# up so that it can be used within a cluster template by ncar-spack
# deployment scripts.
#
# This script should be called by templatize_yaml, which is a wrapper
# that sets up the environment.

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
import os, re, copy
from collections.abc import Iterable
from spack.vendor.ruamel.yaml.comments import CommentedMap, Comment

def check_cm(cm):
    if hasattr(cm, Comment.attrib):
        comment = getattr(cm, Comment.attrib)

        if comment.comment:
            print(f" >> Warning: {cm} will be deleted but has a comment attribute!")
            print(f"    '{comment}'")

def clean_view(data):
    if "root" in data:
        data["root"] = "%BASEROOT%/view"
    if "select" in data:
        data["select"] = []

# Packages to exclude when pruning externals
excluded_pkgs = ["openpbs", "cray-libsci", "cray-mpich", "miniconda3", "opengl"]

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_files = ["spack.yaml"]

try:
    for inc_file in os.listdir(f"{env_dir}/includes"):
        if inc_file not in ["constraints.yaml"]:
            yaml_files.append(f"includes/{inc_file}")
except FileNotFoundError:
    pass

for yaml_file in yaml_files:
    yaml_path = f"{env_dir}/{yaml_file}"
    temp_path = f"{env_dir}/templates/yaml/{yaml_file}"
    os.makedirs(f"{env_dir}/templates/yaml/includes", exist_ok = True)

    tmproot = os.environ["NCAR_SPACK_TMPROOT"]
    deployment = "{}/{}".format(os.environ["NCAR_SPACK_HOST"], os.environ["NCAR_SPACK_HOST_VERSION"])

    with open(yaml_path, 'r') as yaml_file:
        full_data = yaml.load_config(yaml_file)

    # We need to operate on a deep copy since we will modify the dictionary
    if yaml_file == "spack.yaml":
        orig_data = full_data
    else:
        orig_data = full_data

    data = copy.deepcopy(orig_data)

    # Make modifications to fields to generalize yaml file
    for key in orig_data:
        if key == "config":
            for subkey in orig_data[key]:
                if subkey == "template_dirs":
                    check_cm(data[key][subkey])
                    del data[key][subkey]
                elif subkey == "install_tree":
                    if "root" in orig_data[key][subkey]:
                        data[key][subkey]["root"] = "%INSTALLROOT%"
                    if "projections" in orig_data[key][subkey]:
                        data[key][subkey]["projections"] = dict(sorted(data[key][subkey]["projections"].items(), key=lambda item: item[0]))
                elif "_cache" in subkey or subkey == "test_stage":
                    data[key][subkey] = data[key][subkey].replace(tmproot, "%TMPROOT%").replace(deployment, "%DEPLOYMENT%")
                elif subkey == "build_stage":
                    data[key][subkey] = [item.replace(tmproot, "%TMPROOT%").replace(deployment, "%DEPLOYMENT%") for item in data[key][subkey]]
        elif key == "packages":
            for subkey in orig_data[key]:
                keep_pkg = False

                for pkgkey in orig_data[key][subkey]:
                    if pkgkey in ["externals", "buildable"]:
                        if subkey not in excluded_pkgs:
                            check_cm(data[key][subkey][pkgkey])
                            del data[key][subkey][pkgkey]
                        else:
                            keep_pkg = True
                    else:
                        keep_pkg = True

                        if pkgkey == "variants":
                            data[key][subkey][pkgkey] = sorted(data[key][subkey][pkgkey])

                if not keep_pkg:
                    check_cm(data[key][subkey])
                    del data[key][subkey]

            data[key] = dict(sorted(data[key].items(), key=lambda item: item[0]))
        elif key == "view":
            if "select" in orig_data[key]:
                clean_view(data[key])
            else:
                for subkey in orig_data[key]:
                    clean_view(data[key][subkey])
        elif key == "compilers":
            data[key] = []
        elif key == "modules":
            for mset in orig_data[key]:
                for subkey in orig_data[key][mset]:
                    if subkey == "roots":
                        data[key][mset][subkey]["lmod"] = "%MODULESROOT%"
                    elif subkey == "lmod":
                        for modkey in orig_data[key][mset][subkey]:
                            if modkey in ["exclude", "core_specs"]:
                                data[key][mset][subkey][modkey] = []
                            elif isinstance(data[key][mset][subkey][modkey], dict):
                                for var in ["environment", "filter"]:
                                    if var in data[key][mset][subkey][modkey]:
                                        for envkey in data[key][mset][subkey][modkey][var]:
                                            if var == "environment":
                                                data[key][mset][subkey][modkey][var][envkey] = dict(sorted(data[key][mset][subkey][modkey][var][envkey].items(), key=lambda item: item[0]))
                                            elif var == "filter":
                                                data[key][mset][subkey][modkey][var][envkey] = sorted(data[key][mset][subkey][modkey][var][envkey])

                        data[key][mset][subkey] = dict(sorted(data[key][mset][subkey].items(), key=lambda item: item[0]))
        elif key in ["mirrors", "specs", "upstreams", "toolchains"]:
            data[key] = CommentedMap()
        elif key in ["bootstrap"]:
            del(data[key])

    if yaml_file == "spack.yaml":
        full_data["spack"] = data
    else:
        full_data = data

    # Write modified yaml to template
    with open(temp_path, 'w') as temp_file:
        yaml.dump_config(full_data, temp_file)
