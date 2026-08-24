/-
Copyright (c) 2026 Multiplicity Foundry. All rights reserved.
Released under the terms described in the repository LICENSE file.
-/
import Multiplicity.WordLove.Core

/-!
# Word Love Tag Attributes (ADR-0031)

This leaf module owns the two project tag attributes. It exists so that the
Rust-loaded shared-library closure (`Multiplicity.WordLove.FFI` and its
imports) contains **no** `initialize` blocks: environment extensions can only
be registered while Lean's initialization window is open, which holds for
Lake executables (`word_love_test`) but not for modules initialized through
the `lean-rs` host loader after `lean_io_mark_end_initialization`.

Every module that *applies* `@[wordlove_adr]` or `@[wordlove_proof]`
(`Proofs`, `Examples`, `Certified`, `Test`) reaches this module through its
imports, so elaboration-time tagging works exactly as before. The export
closure simply never initializes it.
-/

namespace Multiplicity.WordLove

/-- Tag attribute for formally registered Word Love artifacts (ADR-0031). -/
initialize wordloveAdrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `wordlove_adr "Word Love (ADR-0031) registry tag" (fun _ => pure ())

/-- Tag attribute for machine-checked Word Love theorems (ADR-0031). -/
initialize wordloveProofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `wordlove_proof "Word Love (ADR-0031) proof tag" (fun _ => pure ())

end Multiplicity.WordLove
