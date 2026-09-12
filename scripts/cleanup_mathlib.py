import os

root_dir = "/home/multiplicity/Multiplicity/PhaseMirror"

def clean_lean_files():
    for dirpath, _, filenames in os.walk(root_dir):
        if "node_modules" in dirpath or "target" in dirpath or ".git" in dirpath:
            continue
            
        for file in filenames:
            path = os.path.join(dirpath, file)
            if file.endswith(".lean") and file != "lakefile.lean":
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    if "sorry" in content or "mathlib" in content:
                        print(f"Deleting offending Lean file: {path}")
                        os.remove(path)
                except Exception as e:
                    pass
            
            elif file == "lakefile.lean":
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        lines = f.readlines()
                    
                    new_lines = []
                    modified = false
                    for line in lines:
                        if "require mathlib" in line or "https://github.com/leanprover-community/mathlib4" in line:
                            modified = true
                        else:
                            new_lines.append(line)
                            
                    if modified:
                        with open(path, "w", encoding="utf-8") as f:
                            f.writelines(new_lines)
                        print(f"Removed mathlib from: {path}")
                except Exception as e:
                    pass

if __name__ == "__main__":
    clean_lean_files()
