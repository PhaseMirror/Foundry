import os
import re

valid_modules = set()
for root, dirs, files in os.walk('Core'):
    for f in files:
        if f.endswith('.lean'):
            path = os.path.join(root, f)
            mod_path = path[:-5].replace('/', '.')
            valid_modules.add(mod_path)

for root, dirs, files in os.walk('Core'):
    for f in files:
        if f.endswith('.lean'):
            path = os.path.join(root, f)
            with open(path, 'r') as fp:
                for line in fp:
                    if line.startswith('import '):
                        mod = line.split()[1]
                        if mod.startswith('Core.') and mod not in valid_modules:
                            print(f"{path} has bad import: {mod}")
