import Multiplicity.WordLove.Core
import Multiplicity.WordLove.Proofs
import Multiplicity.WordLove.FFI

/-!
# Word Love Certified Coupling — Joint Invariants (ADR-0033 P4 Certification)

Machine-checked proof obligations over the live hybrid-primality gate and the
certified prime coupling `FFI.gammaCertified` (ADR-0031 §6, fixed-point scale
N = 1024). This module realizes the **P4 Certification** stratum of the Prism
semantic model (ADR-0033): behaviors authored once, obligations proved against
the realized definition, no independent restatement of the arithmetic.

Every `@[wordlove_proof]` declaration below is kernel-checked. As with the rest
of the Word Love layer: **no `sorry`, no `admit`, no `axiom`**.

## Obligations Delivered

| Obligation ID | Theorem | Meaning |
|---|---|---|
| `WL-CERTCOUPLE-007` | `certified_gamma_zero_on_inadmissible` | Gate collapse: any inadmissible orbital forces γ = 0 |
| `WL-CERTCOUPLE-007` | `certified_gamma_agrees_when_admissible` | Gate inertness: on admissible orbitals γ equals the ungated reference model |
| `WL-CERTMULT-008`   | `certified_multiplicity_bounded`        | Participation multiplicity M ∈ [1, 3] unconditionally |
| `WL-CERTJOINT-009`  | `joint_admissible_multiplicity`         | Joint admissibility + coherence attestation ⇒ M = 3 ∧ γ = raw |

## Spec Decisions (deliberate, documented, extensible)

1. **Ungated reference model (`couplingRaw`).** The Lean layer never had an
   ungated coupling — the gate was baked into `FFI.gammaCertified` from the
   start. "Agreement" therefore means: the certified function restricts to the
   *identical arithmetic* once both orbitals pass the gate. `couplingRaw` is
   that arithmetic, mirrored line-for-line from the FFI body minus the gate.
2. **Participation multiplicity (`certifiedMultiplicity`).** "Multiplicity over
   the fixed-point scale" is defined as the count of certified prime orbitals
   participating in the coupling plus the base unit: M(p,n) =
   1 + [p admissible] + [n admissible]. Each admissible orbital contributes
   exactly one unit because hybrid primality certifies a *prime* (ω = Ω = 1);
   composites and uncertified large naturals contribute nothing. This is an
   orbital-level Ω, deliberately minimal; a future refinement can connect
   Tier-2 acceptance to `factorize` soundness (Pratt verifier correctness),
   which is out of scope here and would be a separate obligation.
3. **Coherence witness (`JointCoherenceAttestation`).** The UOR Coherence layer
   (ADR-0031 §6 / Prism P3 Composition) is not yet formalized, so the joint
   theorem carries an explicit attestation structure whose field is vacuous
   today *by design*: downstream proofs thread the witness already, and the
   slot is replaced by the real invariant without disturbing signatures — the
   same pattern as `ProxySignatureHypothesis` in SpectralAttractor.Hyperplane.
-/

namespace Multiplicity.WordLove

/-! ### Reference Model and Participation Multiplicity -/

/-- Ungated reference coupling (spec decision 1): identical arithmetic to
`FFI.gammaCertified` with the hybrid-primality gate removed. Normalized prime
coupling decaying with orbital separation via `FFI.careDecay`, fixed-point
scale N = 1024. -/
def couplingRaw (p n trust : Nat) : Nat :=
  let minVal := if p < n then p else n
  let maxVal := if p < n then n else p
  if maxVal == 0 then 0
  else
    let sep := if p >= n then p - n else n - p
    (minVal * FFI.careDecay sep * trust) / (maxVal * 1024)

/-- Orbital participation multiplicity over the fixed-point scale (spec
decision 2): base unit 1, incremented once per orbital admitted by the
hybrid gate. Range {1, 2, 3}; see `certified_multiplicity_bounded`. -/
def certifiedMultiplicity (p n : Nat) (certP certN : Option PrattCertificate) : Nat :=
  1 + (if isHybridPrime p certP then 1 else 0)
    + (if isHybridPrime n certN then 1 else 0)

/-- Coherence attestation slot for the joint invariant (spec decision 3).
Vacuous field today by design; replaced by the UOR CoherenceProof obligation
when that layer lands. -/
@[wordlove_adr]
structure JointCoherenceAttestation : Prop where
  /-- Integration slot: UOR CoherenceProof obligation (ADR-0031 §6). -/
  uorSealed : True

/-! ### WL-CERTCOUPLE-007: Gate Collapse and Gate Inertness -/

/-- **Gate collapse.** If either orbital fails the hybrid gate, the certified
coupling collapses to exactly 0 — the coupling never fires on unverified
primality, regardless of trust weight or separation. -/
@[wordlove_proof]
theorem certified_gamma_zero_on_inadmissible (p n trust : Nat)
    (certP certN : Option PrattCertificate)
    (h : isHybridPrime p certP = false ∨ isHybridPrime n certN = false) :
    FFI.gammaCertified p n trust certP certN = 0 := by
  unfold FFI.gammaCertified
  rcases h with hp | hn
  · exact if_pos (by rw [hp, Bool.not_false, Bool.true_or])
  · exact if_pos (by rw [hn, Bool.not_false, Bool.or_true])

/-- **Gate inertness.** When both orbitals are admissible, the certified
coupling agrees exactly with the ungated reference model: certification adds
safety without distorting the agreed arithmetic. -/
@[wordlove_proof]
theorem certified_gamma_agrees_when_admissible (p n trust : Nat)
    (certP certN : Option PrattCertificate)
    (hp : isHybridPrime p certP = true) (hn : isHybridPrime n certN = true) :
    FFI.gammaCertified p n trust certP certN = couplingRaw p n trust := by
  have hnc : ¬((!isHybridPrime p certP || !isHybridPrime n certN) = true) := by
    rw [hp, Bool.not_true, hn, Bool.not_true, Bool.false_or]
    decide
  unfold FFI.gammaCertified couplingRaw
  split
  · next hg => exact absurd hg hnc
  · next => rfl

/-! ### WL-CERTMULT-008: Participation Bound -/

/-- Participation contribution of a single gated orbital never exceeds 1
(construction keeps the bound proof free of classical principles). -/
private theorem participation_le_one (b : Bool) :
    (if b then (1 : Nat) else 0) ≤ 1 := by
  cases b
  · exact Nat.zero_le _
  · exact Nat.le_refl _

/-- **Participation bound.** The orbital participation multiplicity lies in
[1, 3] for every pair of orbitals and every certificate supply — unconditional,
no gate hypotheses required. -/
@[wordlove_proof]
theorem certified_multiplicity_bounded (p n : Nat) (certP certN : Option PrattCertificate) :
    1 ≤ certifiedMultiplicity p n certP certN ∧
      certifiedMultiplicity p n certP certN ≤ 3 := by
  unfold certifiedMultiplicity
  have hA := participation_le_one (isHybridPrime p certP)
  have hB := participation_le_one (isHybridPrime n certN)
  refine ⟨Nat.le_trans (Nat.le_add_right 1 _) (Nat.le_add_right _ _), ?_⟩
  calc 1 + (if isHybridPrime p certP then (1 : Nat) else 0)
        + (if isHybridPrime n certN then (1 : Nat) else 0)
      ≤ 1 + 1 + (if isHybridPrime n certN then (1 : Nat) else 0) :=
        Nat.add_le_add_right (Nat.add_le_add_left hA 1) _
    _ ≤ 1 + 1 + 1 := Nat.add_le_add_left hB _
    _ = 3 := by decide

/-! ### WL-CERTJOINT-009: Joint Admissibility -/

/-- **Joint admissibility.** Under mutual gate admission plus a coherence
attestation, participation is maximal (M = 3) and the certified coupling is
extensionally the reference coupling. This is the certified-coupling analogue
of "legal trajectory" in the substrate layer. -/
@[wordlove_proof]
theorem joint_admissible_multiplicity (p n trust : Nat)
    (certP certN : Option PrattCertificate) (_ : JointCoherenceAttestation)
    (hp : isHybridPrime p certP = true) (hn : isHybridPrime n certN = true) :
    certifiedMultiplicity p n certP certN = 3 ∧
      FFI.gammaCertified p n trust certP certN = couplingRaw p n trust := by
  refine ⟨?_, certified_gamma_agrees_when_admissible p n trust certP certN hp hn⟩
  unfold certifiedMultiplicity
  have h1 : (if isHybridPrime p certP then (1 : Nat) else 0) = 1 := if_pos hp
  have h2 : (if isHybridPrime n certN then (1 : Nat) else 0) = 1 := if_pos hn
  rw [h1, h2]
  try rfl

/-! ### Concrete Sanity Anchors (match Sedona Spine harness values) -/

/-- Full-trust self-coupling of Love (13): γ = 1024 at unity normalized weight,
matching the `sedona_spine_certified_coupling` harness line. -/
example : FFI.gammaCertified 13 13 1024 none none = 1024 := by decide

/-- Inadmissible orbital (12 = 2²·3, composite) collapses the coupling to 0,
matching the harness rejection line. -/
example : FFI.gammaCertified 12 13 1024 none none = 0 := by decide

/-- Tier-2 Fermat prime 65537 self-couples at full trust weight through its
Pratt certificate path. -/
example : FFI.gammaCertified 65537 65537 1024 (some cert65537) (some cert65537) = 1024 := by
  decide

/-- Separation beyond the decay window (|131071 − 65537| = 65534 ≥ 7) zeroes
the coupling even when both orbitals carry verified certificates. -/
example : FFI.gammaCertified 131071 65537 1024 (some cert131071) (some cert65537) = 0 := by
  decide

/-- Tier-1 precedence: 65535 ≤ 65536 is decided by the static table alone, so
participation stays at the base-plus-one level despite being one below the
certificate threshold. -/
example : certifiedMultiplicity 65535 13 none none = 2 := by decide

end Multiplicity.WordLove
