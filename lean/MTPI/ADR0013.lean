import MTPI.ADR

/-!
# ADR-0013 UOR Civic Infrastructure — Lean 4 formal scaffold

Machine-checked mirror of `docs/adr/accepted/0013-UOR Civic Infrastructure.md`
for the canonical PWEH/CRMF core:

* **Canonical BCS wire format** of the `UnsignedCrmfEnvelope`: fixed field order,
  unsigned big-endian integers, no floating-point fields, and a length-prefixed
  metadata tail (deterministic total length theorem).
* **Fail-closed interlocks**: the `SIG_GOV_KILL`/`L0_HALT` latch (non-maskable,
  never un-halts) and the associator-defect predicate.
* **Contractivity gate**: the UCC's `Λ_m < 1` acceptance bound.
* **PWEH binding**: the four-field integrity-binding tuple, its injectivity, its
  fixed preimage width, and the path-dependence (order matters) theorem.

All theorems here are zero-sorry; this module deliberately proves only what is
mechanically checkable in Lean core (the `Hash_PQC` slot itself is collision
resistance, which is an assumption, not a theorem).

The Rust companion lives in `packages/rust/crmf/src/canonical.rs`,
`failgate.rs`, and `pweh.rs` (Kani-verified); the two implementations agree on
every constant and structural property formalized here.
-/

namespace MTPI.ADR0013

open MTPI.ADR

initialize adrAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `adr { descr := "marks a formal ADR-0013 artifact" }

initialize proofAttr : Lean.TagAttribute ←
  Lean.registerTagAttribute `proof { descr := "marks a machine-checked ADR-0013 proof" }

/-! ## Meta: the ADR record itself -/

/-- Formal representation of ADR-0013 as a machine-checkable architecture
decision record. -/
@[adr]
def adr0013 : ADR := {
  id := { number := 13 },
  title := "UOR Civic Infrastructure",
  status := ADRStatus.Accepted,
  context := "The Foundry DAO progresses through three epochs. PrismPM governs process and packaging law; the UCC governs physical and dynamical law via the universal closure sextuple. PWEH operationalizes contractivity and fail-closed interlocks as an active execution lock, and CRMF envelopes canonicalized under BCS provide tamper-evident attestation.",
  decision := "Serialize the UnsignedCrmfEnvelope in the canonical BCS byte sequence (fixed field order, big-endian unsigned integers, no floating-point fields, length-prefixed metadata); chain PWEH integrity states S(t) = Hash(S(t-1) ‖ p^t ‖ ‖AT(t)‖ ‖ M(t)); admit transitions only when contractivity Λ_m < 1 holds; trigger a non-maskable SIG_GOV_KILL on any associator defect ‖Δ‖ > ε or expansive transition.",
  consequences := [
    "Deterministic, cross-language canonical byte streams for cryptographic commitments.",
    "Path-dependent tamper resistance across the whole PWEH chain.",
    "Fail-closed governance: any unmodeled defect halts L0 before side effects materialize.",
    "Poseidon2 sponge absorption (t=9, r=8) is the ZK sealing stage; the field implementation is staged."
  ],
  supersedes := none,
  links := []
}

/-! ## Canonical BCS wire format -/

/-- Fixed point scale anchoring the contractivity bound (`Λ_m = 1`). -/
@[adr]
def SCALE : Nat := 1000000000

/-- Fixed point bound `ε` for the associator defect (`‖Δ‖ > ε`). -/
@[adr]
def EPSILON : Nat := 1

/-- Width of the fixed envelope header: id[32] + ts[8] + poseidon[32] +
sha[32] + sig[64] + lambda[8] + drift[8] (ADR-0013 field sequence). -/
@[adr]
def fixedWidth : Nat := 184

/-- Width of the metadata length prefix (u32 big-endian). -/
@[adr]
def prefixWidth : Nat := 4

/-- Minimum encoded length (empty metadata). -/
@[adr]
def minEnvelopeLen : Nat := fixedWidth + prefixWidth

@[proof]
theorem fixedWidth_eq : fixedWidth = 184 := by
  rfl

@[proof]
theorem minEnvelopeLen_eq : minEnvelopeLen = 188 := by
  rfl

/-- Byte index helper: byte `exponent` (0 = least significant) of `n`. -/
@[adr]
def byteAt (exponent n : Nat) : Nat := (n / (256 ^ exponent)) % 256

/-- Big-endian 8-byte encoding of a 64-bit-style value. -/
@[adr]
def be8 (n : Nat) : List Nat :=
  [ byteAt 7 n, byteAt 6 n, byteAt 5 n, byteAt 4 n,
    byteAt 3 n, byteAt 2 n, byteAt 1 n, byteAt 0 n ]

/-- Big-endian 4-byte encoding of a 32-bit-style length. -/
@[adr]
def be4 (n : Nat) : List Nat :=
  [ byteAt 3 n, byteAt 2 n, byteAt 1 n, byteAt 0 n ]

@[proof]
theorem be8_length (n : Nat) : (be8 n).length = 8 := by
  simp [be8]

@[proof]
theorem be4_length (n : Nat) : (be4 n).length = 4 := by
  simp [be4]

/-- Fixed-point UCC metrics carried by the envelope. -/
@[adr]
structure BcsMetrics where
  lambda_m : Nat
  drift : Nat

/-- The canonical `UnsignedCrmfEnvelope`. Fields hold bytes as `Nat` lists; the
`canonicalWidths` predicate fixes their declared widths. No field has a
floating-point type: rounding non-determinism is excluded structurally. -/
@[adr]
structure UnsignedCrmfEnvelope where
  envelope_id : List Nat
  timestamp : Nat
  poseidon_commitment : List Nat
  sha256_anchor : List Nat
  ed25519_signature : List Nat
  metrics : BcsMetrics
  metadata : List Nat

/-- Declared field widths of a canonical envelope. -/
@[adr]
def canonicalWidths (e : UnsignedCrmfEnvelope) : Prop :=
  e.envelope_id.length = 32 ∧ e.poseidon_commitment.length = 32 ∧
  e.sha256_anchor.length = 32 ∧ e.ed25519_signature.length = 64

/-- Fixed header in exact ADR-0013 field order. -/
@[adr]
def fixedPrefix (e : UnsignedCrmfEnvelope) : List Nat :=
  e.envelope_id ++ be8 e.timestamp ++ e.poseidon_commitment ++
    e.sha256_anchor ++ e.ed25519_signature ++ be8 e.metrics.lambda_m ++
    be8 e.metrics.drift

/-- Length prefix for the metadata tail (u32 big-endian element count). -/
@[adr]
def lenPrefix (e : UnsignedCrmfEnvelope) : List Nat :=
  be4 e.metadata.length

/-- The canonical byte stream of the envelope. -/
@[adr]
def canonicalBytes (e : UnsignedCrmfEnvelope) : List Nat :=
  fixedPrefix e ++ lenPrefix e ++ e.metadata

/-- Field order is exactly the ADR-0013 declared sequence. -/
@[proof]
theorem canonicalBytes_field_order (e : UnsignedCrmfEnvelope) :
    canonicalBytes e =
      e.envelope_id ++ be8 e.timestamp ++ e.poseidon_commitment ++
      e.sha256_anchor ++ e.ed25519_signature ++ be8 e.metrics.lambda_m ++
      be8 e.metrics.drift ++ be4 e.metadata.length ++ e.metadata := by
  simp [canonicalBytes, fixedPrefix, lenPrefix, List.append_assoc]

/-- The fixed header is exactly the ADR width (deterministic byte length). -/
@[proof]
theorem fixedPrefix_widths (e : UnsignedCrmfEnvelope) (h : canonicalWidths e) :
    (fixedPrefix e).length = fixedWidth := by
  rcases h with ⟨h_id, h_pose, h_sha, h_sig⟩
  simp [fixedPrefix, be8, List.length_append, fixedWidth, h_id, h_pose, h_sha, h_sig]

/-- Total canonical length is a deterministic function of the metadata length:
`len = 184 + 4 + |metadata|`. This is the Lean mirror of the Rust
`canonical_len` formula (Kani-verified). -/
@[proof]
theorem canonicalBytes_length (e : UnsignedCrmfEnvelope) (h : canonicalWidths e) :
    (canonicalBytes e).length = minEnvelopeLen + e.metadata.length := by
  rcases h with ⟨h_id, h_pose, h_sha, h_sig⟩
  simp [canonicalBytes, fixedPrefix, lenPrefix, be8, be4, List.length_append,
        minEnvelopeLen, fixedWidth, prefixWidth, h_id, h_pose, h_sha, h_sig]

/-! ## Contractivity gate and fail-closed interlocks -/

/-- UCC kiln gate: accept exactly when `Λ_m < 1` (fixed-point scaled). -/
@[adr]
def Contractive (lambda_m : Nat) : Prop := lambda_m < SCALE

@[proof]
theorem contractive_strictly_below_scale {lambda_m : Nat}
    (h : Contractive lambda_m) : lambda_m < SCALE := h

/-- The gate rejects at or above `Λ_m = 1` (complete contrapositive). -/
@[proof]
theorem gate_rejects_at_or_above_scale {lambda_m : Nat}
    (h : ¬ Contractive lambda_m) : SCALE ≤ lambda_m := by
  exact Nat.le_of_not_gt (by simpa [Contractive] using h)

/-- Associator defect: `‖Δ‖ > ε`. -/
@[adr]
def AssociatorDefect (norm_scaled : Nat) : Prop := norm_scaled > EPSILON

@[proof]
theorem defect_above_epsilon {norm_scaled : Nat}
    (h : AssociatorDefect norm_scaled) : EPSILON < norm_scaled := h

/-- Pure commit predicate of the fail latch: `killed ∨ defect ∨ expansive`
(ADR-0013: any unmodeled associator defect or expansive transition triggers
SIG_GOV_KILL). -/
@[adr]
def commit (killed defect expansive : Bool) : Bool := killed || defect || expansive

@[proof]
theorem kill_is_monotone {killed defect expansive : Bool} (hk : killed = true) :
    commit killed defect expansive = true := by
  simp [commit, hk]

/-- A defect always kills: the interlock is fail-closed. -/
@[proof]
theorem defect_implies_kill {killed defect expansive : Bool} (hd : defect = true) :
    commit killed defect expansive = true := by
  simp [commit, hd]

/-- An expansive transition always kills: the interlock is fail-closed. -/
@[proof]
theorem expansive_implies_kill {killed defect expansive : Bool} (he : expansive = true) :
    commit killed defect expansive = true := by
  simp [commit, he]

/-- A kill is always warranted by prior kill, defect, or expansion (no false
kills on a fresh latch). -/
@[proof]
theorem kill_requires_evidence {killed defect expansive : Bool}
    (h : commit killed defect expansive = true) :
    killed = true ∨ defect = true ∨ expansive = true := by
  revert h
  cases killed <;> cases defect <;> cases expansive <;> simp_all [commit]

/-- The latch never un-halts: once killed, further commits stay killed. -/
@[proof]
theorem latch_never_unhalts {defect expansive : Bool} :
    commit true defect expansive = true := by
  simp [commit]

/-! ## PWEH integrity binding -/

/-- The four-field integrity binding of one PWEH step:
`S(t) = Hash_PQC(prev ‖ p^t ‖ ‖A_{p^t} T(t)‖ ‖ M(t))` (ADR-0013). The binding
carries the fields in exact order; injectivity makes the hash input a lossless
encoding of the trace step, so forgery is a path-collision problem. -/
@[adr]
structure PwehBind where
  prev : Nat
  prime : Nat
  norm : Nat
  meta : Nat

/-- The binding is injective: equality of bound steps is componentwise
equality. This formalizes the losslessness of the PWEH hash input; the Key for
`Hash_PQC` collision resistance itself is that distinct inputs yield distinct
attestations. -/
@[proof]
theorem pweh_bind_injective {a b c d a' b' c' d' : Nat}
    (h : PwehBind.mk a b c d = PwehBind.mk a' b' c' d') :
    a = a' ∧ b = b' ∧ c = c' ∧ d = d' := by
  have h1 := congrArg PwehBind.prev h
  have h2 := congrArg PwehBind.prime h
  have h3 := congrArg PwehBind.norm h
  have h4 := congrArg PwehBind.meta h
  simpa using And.intro h1 (And.intro h2 (And.intro h3 h4))

/-- The exact sequence of applied operators matters: swapping the prime index
and the previous state of a four-field binding changes the binding. -/
@[proof]
theorem pweh_bind_swap {a b c d : Nat} (hab : a ≠ b) :
    PwehBind.mk a b c d ≠ PwehBind.mk b a c d := by
  intro heq
  have ⟨h1, _⟩ := pweh_bind_injective (a := a) (b := b) (c := c) (d := d)
    (a' := b) (b' := a) (c' := c) (d' := d) heq
  exact hab h1

/-- Concrete path-dependence witness: `(2, 9, 27, 5)` is not `(9, 2, 27, 5)`;
the two operator orders bind to distinct integrity inputs. -/
@[proof]
theorem order_ab_ne_ba :
    PwehBind.mk 2 9 27 5 ≠ PwehBind.mk 9 2 27 5 := by
  exact pweh_bind_swap (a := 2) (b := 9) (c := 27) (d := 5) (by decide)

/-- Fixed-width byte preimage of a binding (8 bytes per field, ADR-0013
fixed-width fields). -/
@[adr]
def pweh_preimage_bytes (b : PwehBind) : List Nat :=
  be8 b.prev ++ be8 b.prime ++ be8 b.norm ++ be8 b.meta

/-- The preimage has fixed width `4 * 8 = 32` bytes, so the hash chip always
sees a canonical-length digest input. -/
@[proof]
theorem pweh_preimage_length (b : PwehBind) :
    (pweh_preimage_bytes b).length = 32 := by
  simp [pweh_preimage_bytes, be8, List.length_append]

/-! ## Canonical example (runtime witness) -/

/-- A concrete ADR-0013 envelope used by the test harness as the executable
witness for the canonical packing. -/
@[adr]
def exampleEnvelope : UnsignedCrmfEnvelope := {
  envelope_id := List.replicate 32 0x11,
  timestamp := 0x0102_0304_0506_0708,
  poseidon_commitment := List.replicate 32 0x22,
  sha256_anchor := List.replicate 32 0x33,
  ed25519_signature := List.replicate 64 0x44,
  metrics := { lambda_m := 0x5555_5555_5555_5555, drift := 0x6666_6666_6666_6666 },
  metadata := [ 0x77, 0x88, 0x99 ],
}

@[proof]
theorem example_envelope_is_canonical : canonicalWidths exampleEnvelope := by
  simp [canonicalWidths, exampleEnvelope, List.length_replicate]

/-- The example envelope encodes to exactly `188 + 3 = 191` bytes. -/
@[proof]
theorem example_envelope_bytes_length :
    (canonicalBytes exampleEnvelope).length = 191 := by
  rw [canonicalBytes_length exampleEnvelope example_envelope_is_canonical]
  simp [exampleEnvelope]
  norm_num

end MTPI.ADR0013