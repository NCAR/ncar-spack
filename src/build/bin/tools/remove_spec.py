# This script is only hopefully temporarily required - using the remove command has become
# problematic with toolchains being added. It just doesn't work!

# Hopefully this API doesn't change often...
import spack.util.spack_yaml as yaml
import os, sys

if len(sys.argv) != 2:
    raise TypeError("remove_spec.py takes 1 argument ({} given)".format(len(sys.argv) - 1))

# First get our package input
pkg_spec = sys.argv[1]

# Infer some settings from the environment
env_dir = os.environ["SPACK_ENV"]
yaml_path = "{}/spack.yaml".format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml.load(yaml_file)

data["spack"]["specs"].remove(pkg_spec)

# Write modified yaml to template
with open(yaml_path, 'w') as yaml_file:
    yaml_file.write(yaml.dump(data))
