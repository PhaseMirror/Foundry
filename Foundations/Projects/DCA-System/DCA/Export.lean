import DCA.Core

/-!
# DCA Export

Generates markdown and structured representations of verified DCA states.
Used for human-readable audit trails and CI/CD documentation generation.

Following the exact pattern of `ADR.Export` in the ADR-System sub-project.
-/

namespace DCA.Export

open DCA

/-- Generates a Markdown string for a DCA state. -/
def stateToMarkdown (s : DcaState) : String :=
  s!"# DCA State\n\n" ++
  s!"| Field | Value |\n" ++
  s!"|-------|-------|\n" ++
  s!"| was | {s.was} |\n" ++
  s!"| did | {s.did} |\n" ++
  s!"| is_ | {s.is_} |\n" ++
  s!"| root_pointer | {s.root_pointer} |\n" ++
  s!"| epsilon_g | {s.epsilon_g} |\n" ++
  s!"| is_valid | {s.is_valid} |\n"

/-- Generates a Markdown summary of a DCA transition proof. -/
def transitionToMarkdown (name : String) (s1 s2 : DcaState) : String :=
  s!"## Transition: {name}\n\n" ++
  s!"**Pre-state:** `{s1}`\n\n" ++
  s!"**Post-state:** `{s2}`\n\n" ++
  s!"### FIR Inverse Path\n\n" ++
  s!"- `is_` = {s2.is_}\n" ++
  s!"- `did` = {s2.did}\n" ++
  s!"- `was` = {s2.was}\n"

/-- Helper: enumerate a list with indices. -/
def enumerateAux {α : Type} : Nat → List α → List (Nat × α)
  | _, [] => []
  | n, a :: rest => (n, a) :: enumerateAux (n + 1) rest

def enumerate {α : Type} (l : List α) : List (Nat × α) :=
  enumerateAux 0 l

/-- Generates a Markdown summary of a DCA registry. -/
def registryToMarkdown (reg : DcaRegistry) : String :=
  let count := reg.states.length
  let valid := reg.validCount
  s!"# DCA Registry\n\n" ++
  s!"- **Total states:** {count}\n" ++
  s!"- **Valid states:** {valid}\n" ++
  s!"- **Invalid states:** {count - valid}\n\n" ++
  s!"## State List\n\n" ++
  String.join (enumerate reg.states |>.map (fun ⟨i, s⟩ =>
    s!"{i}. `{s}` (valid={s.is_valid})\n"))

/-- Generates a Markdown audit report for a complete DCA scenario. -/
def auditReport (title : String) (states : List DcaState) : String :=
  s!"# DCA Audit Report: {title}\n\n" ++
  s!"**States examined:** {states.length}\n\n" ++
  s!"## State Trace\n\n" ++
  String.join (enumerate states |>.map (fun ⟨i, s⟩ =>
    s!"### Step {i}\n\n" ++
    s!"- was={s.was}, did={s.did}, is_={s.is_}\n" ++
    s!"- root={s.root_pointer}, epsilon={s.epsilon_g}\n" ++
    s!"- valid={s.is_valid}\n\n"))

end DCA.Export
