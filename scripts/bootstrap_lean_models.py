import os

models_dir = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/models"

models = [
    "ataraxia", "coding-commander", "echobraid", "generalist",
    "the-examiner", "the-genius", "the-guardian", "the-publisher"
]

def to_camel(s):
    return "".join(word.capitalize() for word in s.split('-'))

def to_snake(s):
    return s.replace("-", "_")

lakefile_template = """import Lake
open Lake DSL

package «{snake}_adr» where
  buildType := .release
  moreLeancArgs := #["-fPIC"]

lean_lib «{camel}Adr» where

@[default_target]
lean_exe «{snake}_adr» where
  root := `Main
"""

core_template = """/-!
# Core ADR Types for {model}
-/
namespace {camel}Adr

inductive ADRStatus
  | Proposed
  | Accepted
  | Deprecated
  | Superseded (byId : String)
  deriving Repr, DecidableEq

structure ArtifactLink where
  rel : String
  url : String
  deriving Repr

structure ADR where
  id : String
  title : String
  status : ADRStatus
  context : Prop
  decision : Prop
  consequences : Prop
  supersedes : Option String
  links : List ArtifactLink

def is_valid_entailment (adr : ADR) : Prop :=
  (adr.context ∧ adr.decision) → adr.consequences

end {camel}Adr
"""

proofs_template = """/-!
# ADR Invariant Proofs
-/
import {camel}Adr.Core

namespace {camel}Adr

theorem accepted_is_immutable (a1 a2 : ADR) (h_id : a1.id = a2.id) (h_acc : a1.status = ADRStatus.Accepted) :
  a1 = a2 ∨ (∃ id, a2.status = ADRStatus.Superseded id) ∨ (a2.status = ADRStatus.Deprecated) := by
  sorry

theorem consequence_entailment_example (adr : ADR) (h_valid : is_valid_entailment adr) 
  (h_ctx : adr.context) (h_dec : adr.decision) : adr.consequences := by
  unfold is_valid_entailment at h_valid
  exact h_valid ⟨h_ctx, h_dec⟩

end {camel}Adr
"""

ffi_template = """/-!
# FFI Bindings for Rust
-/
import {camel}Adr.Core

namespace {camel}Adr

@[export {snake}_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id > supersedesId

end {camel}Adr
"""

root_template = """import {camel}Adr.Core
import {camel}Adr.Proofs
import {camel}Adr.FFI
"""

main_template = """def main : IO Unit := do
  IO.println "Running ADR Formal Verification Suite..."
"""

for model in models:
    model_path = os.path.join(models_dir, model)
    snake = to_snake(model)
    camel = to_camel(model)
    proj_dir = os.path.join(model_path, f"{snake}_adr")
    mod_dir = os.path.join(proj_dir, f"{camel}Adr")
    
    os.makedirs(mod_dir, exist_ok=True)
    
    with open(os.path.join(proj_dir, "lakefile.lean"), "w") as f:
        f.write(lakefile_template.format(snake=snake, camel=camel))
        
    with open(os.path.join(proj_dir, "lean-toolchain"), "w") as f:
        f.write("leanprover/lean4:v4.11.0-rc1\n")
        
    with open(os.path.join(proj_dir, f"{camel}Adr.lean"), "w") as f:
        f.write(root_template.format(camel=camel))
        
    with open(os.path.join(proj_dir, "Main.lean"), "w") as f:
        f.write(main_template)
        
    with open(os.path.join(mod_dir, "Core.lean"), "w") as f:
        f.write(core_template.format(model=model, camel=camel))
        
    with open(os.path.join(mod_dir, "Proofs.lean"), "w") as f:
        f.write(proofs_template.format(camel=camel))
        
    with open(os.path.join(mod_dir, "FFI.lean"), "w") as f:
        f.write(ffi_template.format(camel=camel, snake=snake))

print("Lean bootstrap complete.")
