# This script can be used to add extra environment modifications
# to compiler definitions in Spack API 1.0

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
from _vendoring.ruamel.yaml.comments import CommentedMap
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

num_args = len(sys.argv)

if num_args < 3:
    raise TypeError("Usage: define.toolchain.py TOOLCHAIN COMPILER [BLAS] [LAPACK]")
else:
    toolchain = sys.argv[1]
    comp_spec = sys.argv[2]

    if num_args > 3:
        blas_spec = sys.argv[3]
        lapack_spec = sys.argv[3]
    else:
        blas_spec = None

    if num_args == 5:
        lapack_spec = sys.argv[4]

#
## Environment Modifications
#

virtuals_list = []

for virtual in ("c", "cxx", "fortran", "blas", "lapack"):
    if virtual in ("blas", "lapack") and blas_spec:
        virtuals_list.append(CommentedMap({ "spec" : f"%{virtual}={blas_spec if virtual == 'blas' else lapack_spec}",
                                            "when" : f"%{virtual}"}))
    else:
        virtuals_list.append(CommentedMap({ "spec" : f"%{virtual}={comp_spec}",
                                            "when" : f"%{virtual}"}))

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml.load(yaml_file)

try:
    data["spack"]["toolchains"][toolchain] = virtuals_list
except KeyError:
    data["spack"]["toolchains"] = CommentedMap({toolchain:virtuals_list})

# Write modified yaml to temporary file
with open(yaml_path, 'w') as yaml_file:
    yaml_file.write(yaml.dump(data))
