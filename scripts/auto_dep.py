import subprocess
import re
import os

cargo_toml_path = "/home/multiplicity/Multiplicity/Phase Mirror/Prime/Cargo.toml"

def run_cargo_check():
    result = subprocess.run(["cargo", "check", "--workspace"], capture_output=True, text=True, cwd=os.path.dirname(cargo_toml_path))
    return result.stderr

def add_dependency(dep):
    with open(cargo_toml_path, 'r') as f:
        content = f.read()
    
    # Check if already there
    if f"\n{dep} = " in content:
        return
        
    new_content = content + f'{dep} = "*"\n'
    with open(cargo_toml_path, 'w') as f:
        f.write(new_content)

while True:
    err = run_cargo_check()
    match = re.search(r"error inheriting `([^`]+)` from workspace root manifest's `workspace.dependencies", err)
    if match:
        dep = match.group(1)
        print(f"Adding missing dependency: {dep}")
        add_dependency(dep)
    else:
        # Check for other errors
        if "No such file or directory" in err or "failed to load manifest" in err:
            print("Other error:", err)
            break
        print("Success or non-dependency error")
        break
