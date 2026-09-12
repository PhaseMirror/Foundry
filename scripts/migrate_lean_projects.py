import os
import shutil
import re

projects_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/projects"
core_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Core"

def to_camel_case(s):
    # e.g. ACE_SCN_CSC -> AceScnCsc
    # e.g. ALPHA_FUNCTION -> AlphaFunction
    return ''.join(word.capitalize() for word in re.split(r'[-_\s]+', s.strip()))

def update_lean_file(filepath, project_camel):
    with open(filepath, 'r') as f:
        content = f.read()

    # We want to change namespace to Core.[ProjectCamel]
    # And we want to strip Mathlib imports
    
    lines = content.split('\n')
    new_lines = []
    in_namespace = False
    
    for line in lines:
        if line.startswith("import Mathlib"):
            # Strip mathlib, replace with local construct
            new_lines.append("-- Mathlib import removed per Sedona Spine mandate")
            continue
        
        # Check for namespace
        # We can just inject namespace Core.ProjectCamel if not present, but 
        # usually they have `namespace Formalization` or similar
        if line.startswith("namespace"):
            parts = line.split()
            if len(parts) > 1:
                # Replace with Core.ProjectCamel
                new_lines.append(f"namespace Core.{project_camel}")
            else:
                new_lines.append(line)
        elif line.startswith("end"):
            parts = line.split()
            if len(parts) > 1 and parts[1] == "Formalization": # heuristic
                new_lines.append(f"end Core.{project_camel}")
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    with open(filepath, 'w') as f:
        f.write('\n'.join(new_lines))

def main():
    if not os.path.exists(projects_dir):
        print(f"Directory {projects_dir} not found.")
        return

    for project_name in os.listdir(projects_dir):
        project_path = os.path.join(projects_dir, project_name)
        if not os.path.isdir(project_path) or project_name.startswith('.'):
            continue
        
        project_camel = to_camel_case(project_name)
        src_dir = os.path.join(project_path, "src")
        
        if os.path.isdir(src_dir):
            # It has a src/ dir
            target_dir = os.path.join(core_dir, project_camel)
            os.makedirs(target_dir, exist_ok=True)
            for root, _, files in os.walk(src_dir):
                for file in files:
                    if file.endswith(".lean"):
                        src_file = os.path.join(root, file)
                        dst_file = os.path.join(target_dir, file)
                        shutil.copy2(src_file, dst_file)
                        update_lean_file(dst_file, project_camel)
        else:
            # Check for formalization.lean
            form_file = os.path.join(project_path, "formalization.lean")
            if os.path.exists(form_file):
                dst_file = os.path.join(core_dir, f"{project_camel}.lean")
                shutil.copy2(form_file, dst_file)
                update_lean_file(dst_file, project_camel)
                
        print(f"Migrated {project_name} -> Core.{project_camel}")

if __name__ == "__main__":
    main()
