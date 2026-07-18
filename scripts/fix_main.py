import os

models_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/models"
models = ["ataraxia", "coding-commander", "echobraid", "finton", "generalist", "the-examiner", "the-genius", "the-guardian", "the-publisher"]

def to_camel(s):
    return ''.join(word.capitalize() for word in s.split('-'))

def to_snake(s):
    return s.replace('-', '_')

for model in models:
    snake_name = to_snake(model)
    camel_name = to_camel(model)
    adr_dir = os.path.join(models_dir, model, f"{snake_name}_adr")
    
    main_path = os.path.join(adr_dir, "Main.lean")
    if os.path.exists(main_path):
        with open(main_path, "w") as f:
            f.write(f"""import {camel_name}Adr

def main : IO Unit :=
  IO.println "Loaded {camel_name}Adr."
""")

print("Fixed Main.lean for all models.")
