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
    
    # 1. Update lakefile.lean
    lakefile_path = os.path.join(adr_dir, "lakefile.lean")
    if os.path.exists(lakefile_path):
        with open(lakefile_path, "r") as f:
            lake_content = f.read()
        
        if "require sedona_spine_core" not in lake_content:
            new_lake_content = lake_content.replace(
                f"package «{snake_name}_adr» where\n",
                f"package «{snake_name}_adr» where\n\nrequire sedona_spine_core from \"../../../lean\"\n"
            )
            with open(lakefile_path, "w") as f:
                f.write(new_lake_content)
    
    # 2. Rewrite Core.lean
    core_path = os.path.join(adr_dir, f"{camel_name}Adr", "Core.lean")
    if os.path.exists(core_path):
        new_core_content = f"""/-!
# Core ADR Types for {model}
-/
import Core.ADR

namespace {camel_name}Adr

-- Using global ADR structures
abbrev ADRStatus := Core.ADR.ADRStatus
abbrev ArtifactLink := Core.ADR.ArtifactLink
abbrev ADR := Core.ADR.ADR
abbrev is_valid_entailment := Core.ADR.is_valid_entailment

end {camel_name}Adr
"""
        with open(core_path, "w") as f:
            f.write(new_core_content)
            
    # 3. Rewrite FFI.lean
    ffi_path = os.path.join(adr_dir, f"{camel_name}Adr", "FFI.lean")
    if os.path.exists(ffi_path):
        new_ffi_content = f"""/-!
# FFI Bindings for Rust
-/
import {camel_name}Adr.Core

namespace {camel_name}Adr

@[export {snake_name}_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  Core.ADR.checkAcyclic id supersedesId

end {camel_name}Adr
"""
        with open(ffi_path, "w") as f:
            f.write(new_ffi_content)

print("ADR promotion successful for all models.")
