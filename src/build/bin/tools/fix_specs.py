# This script can be used to "fix" the specs list in a spack.yaml
# file - use it to ensure that the specs are in "flow" style YAML
# and not "block" style

import _vendoring.ruamel.yaml as yaml
import os

env_dir = os.environ["SPACK_ENV"]
yaml_path = '{}/spack.yaml'.format(env_dir)
temp_path = '{}/temp.yaml'.format(env_dir)

with open(yaml_path, 'r') as yaml_file:
    data = yaml_file.read()

specs = yaml.safe_load(data)['spack']['specs']
lines = data.splitlines()

with open(temp_path, 'w') as temp_file:
    for line in lines:
        if line.strip().startswith('specs:'):
            if len(specs) > 0:
                temp_file.write('  specs:\n')
            break
        else:
            temp_file.write(f'{line}\n')

    for spec in specs:
        temp_file.write(f'  - {spec}\n')

os.replace(temp_path, yaml_path)
