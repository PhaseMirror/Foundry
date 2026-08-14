import os
import re

valid_modules = set()
for d in ['Core', 'UOR', 'Governance']:
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.endswith('.lean'):
                path = os.path.join(root, f)
                mod_path = path[:-5].replace('/', '.')
                valid_modules.add(mod_path)

valid_prefixes = ['Init.', 'Std.']

for root, dirs, files in os.walk('Core'):
    for f in files:
        if f.endswith('.lean'):
            path = os.path.join(root, f)
            with open(path, 'r') as fp:
                for line in fp:
                    line = line.strip()
                    if line.startswith('import '):
                        mod = line.split()[1]
                        if not any(mod.startswith(p) for p in valid_prefixes):
                            if mod not in valid_modules:
                                print(f"{path} has bad import: {mod}")
