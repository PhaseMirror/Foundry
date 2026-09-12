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
    
    proofs_path = os.path.join(adr_dir, f"{camel_name}Adr", "Proofs.lean")
    if os.path.exists(proofs_path):
        with open(proofs_path, "r") as f:
            content = f.read()
        
        # Replace the namespace for ADRStatus
        content = content.replace(f"{camel_name}Adr.ADRStatus.Accepted", "Core.ADR.ADRStatus.Accepted")
        content = content.replace(f"{camel_name}Adr.ADRStatus.Proposed", "Core.ADR.ADRStatus.Proposed")
        content = content.replace(f"{camel_name}Adr.ADRStatus.Deprecated", "Core.ADR.ADRStatus.Deprecated")
        content = content.replace(f"{camel_name}Adr.ADRStatus.Superseded", "Core.ADR.ADRStatus.Superseded")
        
        with open(proofs_path, "w") as f:
            f.write(content)

print("Fixed ADRStatus namespaces in Proofs.lean for all models.")
