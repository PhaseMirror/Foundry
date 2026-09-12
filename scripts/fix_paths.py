import os
import re

substrates_dir = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/substrates"
crates_dir = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/crates"

def fix_toml(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace ../../ensembles/name or ../ensembles/name
    # Wait, if they were in substrates, it's ../../ensembles/name
    def replacer(match):
        path_str = match.group(1)
        # e.g. ../../ensembles/mirror-dissonance
        parts = path_str.split('/')
        if 'ensembles' in parts:
            idx = parts.index('ensembles')
            if len(parts) > idx + 1:
                name = parts[idx+1]
                new_name = name.replace(" ", "_").lower()
                return f'path = "../{new_name}"'
        # also handle case where it's ../something and the something was renamed
        # but let's just do the ensembles replacements
        return match.group(0)

    # find all path = "..."
    new_content = re.sub(r'path\s*=\s*"([^"]+)"', replacer, content)
    
    # also fix path for umc-parom
    new_content = new_content.replace('"../umc-parom"', '"../parom"')
    new_content = new_content.replace('"../../ensembles/umc-parom"', '"../parom"')
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for root_dir in [substrates_dir, crates_dir]:
    if not os.path.exists(root_dir): continue
    for dirpath, _, filenames in os.walk(root_dir):
        if "Cargo.toml" in filenames:
            fix_toml(os.path.join(dirpath, "Cargo.toml"))

print("Path fix complete.")
