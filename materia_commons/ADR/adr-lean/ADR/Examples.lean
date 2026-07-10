import ADR.Core
import ADR.Proofs

open ADR

/--
  Three realistic ADR examples used by the test harness.
-/

def example1 : ADR :=
  { id := 1,
    title := "Preservation Engine Integration",
    status := .Accepted,
    context := "PhaseMirror‑Legal requires all ESI preservation alerts to be sourced from the Rust engine.",
    decision := "Introduce a thin TS/WASM SDK that forwards engine‑computed risk levels.",
    consequences := ["All UI components must call `engine.getRisk` via the SDK."],
    supersedes := none,
    links := [ArtifactLink.mk "Engine Spec" "file:///models/legalese-scopist/ENGINE.md"] }

def example2 : ADR :=
  { id := 2,
    title := "Policy‑Driven Variation Storage",
    status := .Proposed,
    context := "Domain‑specific legal variations should be declarative.",
    decision := "Store variations in `templates/*.yaml` and load them at runtime.",
    consequences := ["No hard‑coded conditional logic in UI."],
    supersedes := none,
    links := [ArtifactLink.mk "Template Dir" "file:///models/legalese-scopist/templates/"] }

def example3 : ADR :=
  { id := 3,
    title := "Superseding Deprecated ADR",
    status := .Superseded,
    context := "ADR 2 is outdated after policy overhaul.",
    decision := "Mark ADR 2 as Deprecated and supersede with ADR 3.",
    consequences := ["Clients must migrate to new template format."],
    supersedes := some 2,
    links := [] }

/-- A list containing all examples – used by the test suite. -/

def exampleSet : List ADR := [example1, example2, example3]
