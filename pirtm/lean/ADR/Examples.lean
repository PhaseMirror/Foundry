
import ADR.Core

namespace ADR

/--
Join a list of strings with newline separators.
-/
def unlines (lines : List String) : String :=
  lines.foldl (fun acc s => if acc.isEmpty then s else acc ++ "\n" ++ s) ""

/-! ## Example 0: Deprecated Prototype -/

/--
A deprecated ADR prototype.
-/
def adr0999 : ADR := {
  id := ⟨999⟩,
  title := "Deprecated Prototype",
  status := ADRStatus.Deprecated,
  context := "Early prototype",
  decision := "Superseded by formal system",
  consequences := ["Legacy code removed"],
  supersedes := none,
  links := []
}

/-! ## Example 1: Control Flow & Functions (Phase A) -/

/--
ADR-1001: Add control flow and function definitions to the PIRTM/MOC compiler.

This ADR proposes extending the AST and visitor to support `if`/`else`,
`while`, `for`, and `fn` definitions, lowering to MLIR's `scf` and `func`
dialects.
-/
def adr1001 : ADR := {
  id := ⟨1001⟩,
  title := "Add Control Flow and Function Definitions",
  status := ADRStatus.Accepted,
  context := unlines
    [ "The compiler currently supports arithmetic, let-bindings, blocks,"
    , "prime operators, and tensor contractions.  Users cannot express"
    , "branching or reusable subroutines, limiting PIRTM/MOC to mathematical"
    , "kernels rather than full software modules."
    , ""
    , "MLIR already provides `scf.if`, `scf.for`, `scf.while`, and"
    , "`func.func`/`func.call` operations, so the lowering target is mature."
    ],
  decision := unlines
    [ "1. Extend the parser to recognize `if`/`else`, `while`, `for`."
    , "2. Add AST nodes: `If`, `Loop`, `FnDef`, `FnCall`."
    , "3. Lower to MLIR `scf.if`, `scf.for`, `scf.while`, `func.func`."
    , "4. Prove contractivity of loops via Lean (bounded iteration)."
    ],
  consequences := [
    "Parser gains 4 new node types without breaking existing grammar",
    "MLIR lowering pipeline extended by ~200 LOC in visitor",
    "Lean proofs guarantee loop termination for bounded `for` loops",
    "Test suite expanded with control-flow programs"
  ],
  supersedes := none,
  links := [
    ArtifactLink.leanDecl "PiLang.Parser.parseIf",
    ArtifactLink.gitCommit "abc1234",
    ArtifactLink.testFile "tests/control_flow.irt"
  ]
}

/-! ## Example 2: User-Defined Data Types (Phase B) -/

/--
ADR-1002: Introduce struct and enum declarations with field access and pattern matching.

This ADR proposes extending the type system to support user-defined structs
and enums, lowering to MLIR's `llvm.struct` and `llvm.ptr` types.
-/
def adr1002 : ADR := {
  id := ⟨1002⟩,
  title := "Add Struct and Enum Types",
  status := ADRStatus.Accepted,
  context := unlines
    [ "General-purpose programming requires aggregate data types."
    , "Current PIRTM/MOC only has scalar and tensor types."
    , "MLIR's LLVM dialect supports `llvm.struct` and tagged unions via"
    , "`llvm.ptr` with discriminator metadata."
    ],
  decision := unlines
    [ "1. Add `struct` and `enum` declarations to the parser."
    , "2. Extend the type checker with monomorphic struct/enum types."
    , "3. Lower structs to `llvm.struct` and field access to `llvm.extractvalue`."
    , "4. Lower enums to `llvm.ptr` with a tag field."
    ],
  consequences := [
    "Struct definitions compile to LLVM-compatible layouts",
    "Enum pattern matching lowers to switch on discriminator",
    "Type checker extended with ~150 LOC",
    "No runtime overhead for zero-sized structs"
  ],
  supersedes := none,
  links := [
    ArtifactLink.leanDecl "PiLang.TypeChecker.checkStruct",
    ArtifactLink.gitCommit "def5678",
    ArtifactLink.testFile "tests/data_types.irt"
  ]
}

/-! ## Example 3: Standard Library Foundation (Phase C) -/

/--
ADR-1003: Establish the standard library modules and FFI boundary.

This ADR proposes creating `io`, `file`, `net`, and `collections` modules
with an `extern` FFI declaration system, and requiring Lean contractivity
proofs or documented exceptions for every public function.
-/
def adr1003 : ADR := {
  id := ⟨1003⟩,
  title := "Standard Library and FFI Foundation",
  status := ADRStatus.Accepted,
  context := unlines
    [ "A language without a standard library cannot be used for real systems."
    , "PIRTM/MOC needs I/O, collections, file, and network primitives."
    , "Reimplementing everything in Lean is infeasible; we need FFI."
    ],
  decision := unlines
    [ "1. Create `PiLang.Std` namespace with `Io`, `File`, `Net`, `Collections`."
    , "2. Introduce `extern` declarations to call C/Rust libraries."
    , "3. Require each public function to have a Lean contractivity proof."
    , "4. Document exceptions where proof is deferred (e.g., syscalls)."
    ],
  consequences := [
    "Standard library modules loadable via `import PiLang.Std.Io`",
    "FFI boundary is ABI-stable and auditable",
    "Every public function has a machine-checked or documented contract",
    "Package manager deferred to post-MVP"
  ],
  supersedes := none,
  links := [
    ArtifactLink.leanDecl "PiLang.Std.Io",
    ArtifactLink.leanDecl "PiLang.Std.Collections",
    ArtifactLink.gitCommit "ghi9012",
    ArtifactLink.testFile "tests/std_library.irt"
  ]
}

/-! ## Supersession Example -/

/--
ADR-1004 supersedes ADR-1001 to refine the control-flow implementation.

This demonstrates the supersession mechanism in action.
-/
def adr1004 : ADR := {
  id := ⟨1004⟩,
  title := "Refine Control Flow: Add `loop` Expression",
  status := ADRStatus.Accepted,
  context := unlines
    [ "ADR-1001 added `while` and `for`, but users requested a more"
    , "expressive `loop { ... } break` construct similar to Rust."
    ],
  decision := unlines
    [ "Add a `loop { body }` expression with an explicit `break` keyword."
    , "Lower to `scf.while` with a boolean condition derived from `break`."
    ],
  consequences := [
    "`loop` expression lowers to `scf.while` with break condition",
    "Parser extended with `loop` and `break` keywords",
    "ADR-1001 implementation updated to support `loop`"
  ],
  supersedes := some ⟨1001⟩,
  links := [
    ArtifactLink.leanDecl "PiLang.Parser.parseLoop",
    ArtifactLink.gitCommit "jkl3456",
    ArtifactLink.testFile "tests/loop_break.irt"
  ]
}

/-! ## Roadmap ADR (ADR-014) -/

/--
ADR-014: Roadmap for General-Purpose Language Expansion.

This ADR formally defines the roadmap for turning PIRTM/MOC into a general-purpose programming language.
It adopts a phased expansion (Phases A-D) and supersedes ADR-012.
-/
def adr014 : ADR := {
  id := ⟨14⟩,
  title := "Roadmap for General-Purpose Language Expansion",
  status := ADRStatus.Accepted,
  context := unlines
    [ "The substrate is proven; we now need to support imperative and modular constructs."
    , "PIRTM/MOC needs to evolve into a general-purpose programming language."
    ],
  decision := unlines
    [ "Adopt a phased expansion as outlined in Phases A-D:"
    , "Phase A: Control flow and functions."
    , "Phase B: User-defined data types."
    , "Phase C: Standard library foundation."
    , "Phase D: Advanced modularity and tooling."
    ],
  consequences := [
    "The language will become Turing-complete (with bounded loops)",
    "Require new Lean proofs for each construct",
    "Increase developer adoption"
  ],
  supersedes := some ⟨12⟩,
  links := [
    ArtifactLink.leanDecl "ADR.adr1001",
    ArtifactLink.leanDecl "ADR.adr1002",
    ArtifactLink.leanDecl "ADR.adr1003"
  ]
}

/-! ## QMHES Integration ADR (ADR-033) -/

/--
ADR-033: Quantum-Multiplicity Hybrid Encryption System (QMHES) Integration.

Formalizes the integration of the QMHES cryptographic protocol into the
PIRTM/MOC compiler as a governed cryptographic extension.  The five QMHES
stability theorems are proven in `ADR/QMHESStability.lean`.
-/
def adr033 : ADR := {
  id := ⟨33⟩,
  title := "Quantum-Multiplicity Hybrid Encryption System (QMHES) Integration",
  status := ADRStatus.Accepted,
  context := unlines
    [ "QMHES (Van Gelder, April 2026) unifies post-quantum cryptography"
    , "ML-KEM/ML-DSA/SLH-DSA, QKD (BB84/E91), and Multiplicity Theory"
    , "adaptive feedback via the multiplicity operator M_t and coupling"
    , "tensor T_t.  The PIRTM/MOC compiler requires a governed, auditable"
    , "cryptographic extension."
    ],
  decision := unlines
    [ "1. Formalize the QAHES v1.0.1 wire protocol as AST nodes and"
    , "   MLIR operations with the same strict governance as the core."
    , "2. Port the five QMHES stability theorems (A.4, C.2, D.3, E.2, F.4)"
    , "   to Lean 4 in lean/ADR/QMHESStability.lean."
    , "3. Expose extern FFI functions to liboqs (ML-KEM, ML-DSA, SLH-DSA)"
    , "   and a QKD simulator in pirtm-engine/src/ffi.rs."
    , "4. Add a `pirtm qahes` CLI subcommand with the QAHES handshake"
    , "   and AEAD transport under Small-Gain enforcement."
    , "5. Integrate the Multiplicity feedback loop with the WardMonitor."
    ],
  consequences := [
    "Unified security model: post-quantum secure communication with audit receipts",
    "Machine-checked stability: QMHES stability proofs in the Lean proof suite",
    "Real-world applicability: secure data channels, AI-to-AI communication",
    "Byte-exact interoperability: QAHES wire protocol is language-neutral",
    "Dependency on liboqs: external C library must be managed in CI and packaging"
  ],
  supersedes := none,
  links := [
    ArtifactLink.leanDecl "QMHESStability.multiplicity_bounded",
    ArtifactLink.leanDecl "QMHESStability.lyapunov_convergence",
    ArtifactLink.leanDecl "QMHESStability.prime_eigenmode_convergence",
    ArtifactLink.leanDecl "QMHESStability.hkdf_expand_distinct",
    ArtifactLink.leanDecl "QMHESStability.frequency_quantization_bounded",
    ArtifactLink.testFile "docs/adr/ADR-033-QMHES Integration.md"
  ]
}

/-! ## Example Registry for Traceability Proofs -/

/--
A registry mapping ADR IDs to their records, used for `followSupersession`
and traceability demonstrations.
-/
def adrRegistry : ADRId → Option ADR
  | ⟨14⟩ => some adr014
  | ⟨33⟩ => some adr033
  | ⟨999⟩ => some adr0999
  | ⟨1001⟩ => some adr1001
  | ⟨1002⟩ => some adr1002
  | ⟨1003⟩ => some adr1003
  | ⟨1004⟩ => some adr1004
  | _ => none


end ADR
