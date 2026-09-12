import Foundations.Multiplicity.Core

/-!
# Multiplicity Kernel — Doctrine Witnesses (ADR-0000 / ADR-0001)

This module certifies the verification doctrine itself: the `Theorem`
acceptance predicate, the `FormWitness` four-fold acceptance record, the
extraction rule `witness_certifies`, and the no-axiom structural guarantee.
Every doctrine statement is itself packaged as a `FormWitness`, so the
meta-layer satisfies the same three-form contract as the mathematics.
-/

namespace Multiplicity.Proofs

open Multiplicity.Kernel

/-! ## Acceptance doctrine (`Spec.Core`) -/

/-- An accepted theorem is a proposition with a proof. -/
def theoremAcceptedWitness : FormWitness where
  leanSpec := ∀ (P : Prop), P → Theorem P
  statement := ∀ (P : Prop), P → Theorem P
  proof := theoremOf
  rustFn := "multiplicity-core/src/lib.rs:theorem"
  kaniProof := "kani/proofs/theorem_of.rs"
  regression := "kani/regression/theorem_of.json"

/-- A witness certifies its statement: extraction rule. -/
def witnessCertifiesWitness : FormWitness where
  leanSpec := ∀ (w : FormWitness), w.statement
  statement := ∀ (w : FormWitness), w.statement
  proof := witness_certifies
  rustFn := "multiplicity-core/src/lib.rs:witness"
  kaniProof := "kani/proofs/witness_certifies.rs"
  regression := "kani/regression/witness_certifies.json"

/-- Acceptance only through a witness: `w.statement = P` gives `Theorem P`. -/
def acceptedOnlyIfWitnessedWitness : FormWitness where
  leanSpec := ∀ {P : Prop} (w : FormWitness), w.statement = P → Theorem P
  statement := ∀ {P : Prop} (w : FormWitness), w.statement = P → Theorem P
  proof := accepted_only_if_witnessed
  rustFn := "multiplicity-core/src/lib.rs:witness"
  kaniProof := "kani/proofs/accepted_only_if_witnessed.rs"
  regression := "kani/regression/accepted_only_if_witnessed.json"

/-- Determinism: every total function is deterministic (instance over the
factorial to keep the witness universe-concrete). -/
def determinismWitness : FormWitness where
  leanSpec := ∀ (f : Nat → Nat), Deterministic f
  statement := ∀ (f : Nat → Nat), Deterministic f
  proof := deterministic_of_any
  rustFn := "multiplicity-core/src/lib.rs:determinism"
  kaniProof := "kani/proofs/determinism.rs"
  regression := "kani/regression/determinism.json"

/-! ## Certificate manifest -/

/-- Doctrine witnesses, the audit point for the governance gate. -/
def kernelWitnesses : List FormWitness :=
  [ theoremAcceptedWitness, witnessCertifiesWitness, acceptedOnlyIfWitnessedWitness,
    determinismWitness ]

/-- Every entry of the manifest certifies a real proposition. -/
theorem manifest_certifies (w : FormWitness) (_hw : w ∈ kernelWitnesses) : w.statement :=
  witness_certifies w

end Multiplicity.Proofs
