import os

models_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/models"
models = ["ataraxia", "coding-commander", "echobraid", "finton", "generalist", "the-examiner", "the-genius", "the-guardian", "the-publisher"]

def to_snake(s):
    return s.replace('-', '_')

for model in models:
    snake_name = to_snake(model)
    adr_dir = os.path.join(models_dir, model, f"{snake_name}_adr")
    
    # Update lakefile.lean
    lakefile_path = os.path.join(adr_dir, "lakefile.lean")
    if os.path.exists(lakefile_path):
        with open(lakefile_path, "r") as f:
            lines = f.readlines()
        
        new_lines = []
        for line in lines:
            if line.startswith("require sedona_spine_core"):
                continue # remove bad require
            if line.startswith(f"package «{snake_name}_adr» where"):
                new_lines.append(f"require sedona_spine_core from \"../../../lean\"\n")
            new_lines.append(line)
            
        with open(lakefile_path, "w") as f:
            f.writelines(new_lines)

print("Fixed lakefile.lean for all models.")
