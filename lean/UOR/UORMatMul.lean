/-!
# MatMul in UOR — Codec-Invariance of the Exact Accumulation

This file formalizes what "matmul in UOR" means, grounded in the runtime that
first exhibited it (hologram `matmul_e8cb_omajor` / W8A8 / W4A8, v0.7.2) and in
the uor-addr / F1 Lean discipline (Lean 4 v4.16.0, no Mathlib; proofs by
`decide` / `omega` / `rfl` / rewriting (`rw`, `simp`, `calc`) plus structural
induction and case analysis, and no `funext`; axiom base
`{propext, Quot.sound}`).

## The claim, without classical assumptions

Classical matmul is a bilinear map over a field ℝ, with the *value* stored at
each weight position and the product computed in float. That carries three
assumptions UOR does not grant: a field of reals, values-as-storage, and a
substrate-dependent floating result. We assume none of them.

The UOR statement is:

  A weight tier is a **codec**: a decode function `d : Code → 𝔽` from a stored
  code alphabet into the finite integer working alphabet `𝔽 = {-127..127}`.
  MatMul is the **exact integer accumulation** `Σ aᵢ · d(cᵢ)` over `𝔽`, taken
  in `ℤ` under the no-overflow bound `k · 127² < 2³¹` (hologram
  `K_MAX = i32::MAX / (127·127)`, `kernel_call.rs:83`).

  **Theorem (codec-invariance).** For any two codecs `d₁, d₂` and any code
  streams `c₁, c₂` with `d₁ ∘ c₁ = d₂ ∘ c₂` pointwise, the accumulation agrees:
  the result is a function of the *decoded operand sequence* alone, not of the
  codec that produced it, nor of the reduction schedule, nor of the substrate.

This is why the runtime is bit-identical across scalar / AVX2 / NEON / wasm and
across the i8 / i4 / E8 tiers: they are different `(d, c)` factorizations of the
same decoded sequence into the same exact sum. The weight tier is a residency /
bandwidth choice; the arithmetic **identity** is fixed. No float, no field, no
value-as-storage — the operand is its code in a declared alphabet, exactly the
UOR "object is its address in an equivalence class" shape (uor-addr canonical
form → κ), lowered to the arithmetic core.

## Conceptual model and scientific method

The formalization follows the discipline of the F1 Atlas formalization and of
the TQC exact-certifier programme, in four rules.

1. **Exactness replaces thresholds.** TQC replaced its `f64` density heuristic
   (`|β|² > 10⁻⁴`) with an exact algebraic certifier over `ℚ(ζ₂₄)`; every
   trace coefficient the threshold test reported as non-zero was exactly zero. The
   same lesson is applied here at the arithmetic core: the accumulation is
   modeled in `ℤ`, magnitudes are tracked through `Int.natAbs` with no
   approximation step, and the no-overflow ceiling is a proved inequality, not
   a tolerance. Where a float model could only make the invariance approximate,
   the integer model makes it bit-level.

2. **Parametricity: every constant derives from declared parameters.** The
   Atlas derives every constant from the parametric tuple `(T, O) = (3, 8)`.
   Here every constant derives from the tuple `(B, cap)`: the alphabet bound
   `B` and the accumulator capacity `cap`. All bound theorems are proved for
   arbitrary `(B, cap)`; the W8A8 tier is the single instantiation
   `(B, cap) = (127, 2³¹ − 1)`, from which `kMax = ⌊(2³¹−1)/127²⌋ = 133144` is
   *derived* (and pinned by `decide`, the analogue of an F1
   `atlas-constants` oracle value). Codecs are parametric over their code type,
   so i8 / i4 / E8 are one theorem, not three; block codecs (one code decodes
   to a vector of elements, the E8 shape) are handled by the same one-line
   argument as scalar codecs.

3. **Kernel authority and a minimal axiom base.** Every theorem below is
   checked by the Lean 4 v4.16.0 kernel with no `sorry`, no Mathlib, and no
   `native_decide`; the `#print axioms` audit at the end of the file shows
   every proof closes over at most `{propext, Quot.sound}` (several use no
   axioms at all). This mirrors F1's `honesty_audit.sh` contract.

4. **Status discipline: theorems vs. provenance.** Statements *proved here*
   are Lean theorems and are labeled `CL-MM01` (codec-invariance), `CL-MM02`
   (schedule-independence), `CL-MM03` (exactness), `CL-MM04` (machine
   realization). Statements about the *runtime* (which kernels exist, which
   file states the bound, what the backends witnessed) are source-grounded
   provenance at hologram v0.7.2 and are confined to prose; no Lean theorem
   depends on them. The two registers are never mixed — the TQC
   status-discipline rule (a claim's status is a contract on what V&V may
   assert: `open` claims are measured, never asserted as established) applied
   to a formalization.

## Check status (read before citing)

Kernel-checked. This file compiles standalone against core Lean 4 v4.16.0
(the uor-addr / F1 toolchain pin) with no errors, no warnings, no `sorry`,
and no imports beyond the prelude:

```
lean-toolchain: leanprover/lean4:v4.16.0
$ lean UorMatMul.lean   # expect: exit 0; the only output is the §5 axiom
                        # audit (one informational line per audited theorem);
                        # no errors, no warnings
```

The axiom audit is embedded at the end of the file: `#print axioms` on every
theorem, with the expected footprint (⊆ `{propext, Quot.sound}`) recorded in
the audit section's header comment. The one step the drafting note flagged as
unconfirmed — `dot_split`'s use of the core lemma `List.zip_append` — is
confirmed: v4.16.0 core provides exactly
`l₁.length = l₂.length → (l₁ ++ r₁).zip (l₂ ++ r₂) = l₁.zip l₂ ++ r₁.zip r₂`,
and `dot_split` closes as written. `set_option autoImplicit false` and
`set_option linter.missingDocs true` are enforced file-wide, so every
declaration carries a docstring and no variable is bound automatically (every
implicit is explicitly declared).

Three things are then provable with no further assumptions: the accumulation
is exact (no rounding, so the invariance is bit-level, not approximate); it is
schedule-independent (integer `+` is associative and commutative, so any
split, tiling, or reordering of tiles gives the same integer); and the modeled
two's-complement 32-bit accumulator realizes the exact `ℤ` fold under the
no-overflow ceiling (§4b). Together these are the whole content of "matmul in
UOR": a substrate- and codec-invariant content-addressed operation.

## Companion note — what is formalized, and what is not

For the people asking for "a proof of matmul in UOR." Source-grounded at
hologram v0.7.2 (`matmul_e8cb_omajor`, W8A8/W4A8, `kernel_call.rs`) and the
uor-addr / F1 Lean discipline (Lean 4 v4.16.0, no Mathlib, axiom base
`{propext, Quot.sound}`).

### The statement, without classical assumptions

Classical matmul assumes a field of reals, values stored at each position, and
a float result. UOR grants none of these. The UOR statement drops all three:

- **A weight tier is a codec** `d : Code → 𝔽` from a stored code alphabet into
  the finite integer working alphabet `𝔽 = {−127..127}`. i8 is the identity
  codec (code = value); i4 decodes a nibble through a 16-entry grid; E8 decodes
  a u8 index through the 256×8 lattice codebook (1 bit/weight, QuIP#-style).
- **MatMul is the exact integer accumulation** `Σ aᵢ · d(cᵢ)`, taken in ℤ under
  the no-overflow bound `k · 127² < 2³¹`.

The operand is not a number the kernel multiplies; it is a code naming a point
in a declared alphabet, and the multiply happens after the code decodes into
the one exact accumulation. That is the UOR shape — object as address in an
equivalence class (canonical form → κ) — lowered to the arithmetic core.

### What this file proves

1. **Codec-invariance** (`codec_invariance`, `codec_invariance₂`,
   `block_codec_invariance`, `transcode_invariance`, `matVec_codec_invariance`).
   If two codec/stream factorizations decode to the same operand sequence, the
   accumulation is identical — for scalar codecs (i8/i4), for block codecs
   (E8's one-code-to-eight-weights shape), for transcoded streams
   (re-encoding a stream through another tier), and lifted from a single dot
   product to a full matrix-vector product. The result is a function of the
   decoded operands alone, never of the codec that produced them. These
   statements are congruences — well-definedness of the accumulation on
   decoded sequences — and a congruence alone would hold for any function of
   the streams; they are anchored to the real multiply–accumulate by the
   specification block (`dot_nil_left`, `dot_nil_right`, `dot_cons`), whose
   completeness is itself a theorem (`dot_unique`: any operation satisfying
   the three computation rules *is* `dot`). Together they are the
   well-definedness half of the bit-identity the runtime witnesses across the
   i8 / i4 / E8 tiers.
2. **Schedule-independence** (`foldl_dot_seed`, `dot_split`, `dot_swap`,
   `dot_tiled`, `foldl_add_perm`, `dot_tiled_perm`). Splitting the operand
   stream at any point sums the parts (`dot_split`); the parts commute
   (`dot_swap`); any tiling of the stream into aligned chunks reduces to the
   same integer (`dot_tiled`); and any permutation of the tiles — any
   completion order a scheduler could realize — leaves the result unchanged
   (`dot_tiled_perm`). This is why threaded / SIMD-tiled reduction is
   bit-identical to scalar: integer `+` carries no order dependence.
3. **Exactness** (`dot_natAbs_le`, `partial_sum_natAbs_le`,
   `foldl_dot_append`, `partial_sum_le_cap`, `accum_le_cap`, `dot_exact`,
   and their W8A8
   instantiations `w8a8KMax_value`, `exact_within_i32`, `w8a8_dot_exact`).
   For alphabet-bounded operands the accumulation magnitude is bounded by
   `k · B²` — final sum and every intermediate accumulator state alike
   (`partial_sum_le_cap`) — and under `k ≤ ⌊cap/B²⌋` it stays within `cap`:
   at W8A8, `k ≤ 133144` keeps every partial and final sum within the `i32`
   range.
4. **Machine realization** (`wrap32_eq_of_bounded`, `i32_fold_exact`,
   `w8a8_i32_realizes_exact`). A two's-complement 32-bit accumulator is
   modeled with explicit wraparound after every product and every addition,
   and proved to compute exactly the `ℤ` fold under the ceiling: every
   intermediate state stays in range, so every wrap is the identity. This is
   what makes (1)–(3) bit-level rather than approximate — there is no
   rounding, overflow, or float step at which two codecs or two schedules
   could diverge.

Together: matmul in UOR is a **substrate- and codec-invariant
content-addressed operation**. The weight tier is a residency/bandwidth choice;
the arithmetic identity is fixed. That is the whole claim, and it is the reason
the same operation runs the browser and bare-metal from one artifact.

### What it does NOT prove — say this plainly

- **Not the Atlas-sense formal proof.** This formalizes the operation's
  invariance, the property that makes matmul a UOR citizen rather than a
  platform kernel. It is not a mechanization of matmul inside the F1 Atlas the
  way F1 treats its own objects. Someone asking for a proof in that sense
  should be told this is the implementation-grounded invariance result and the
  Atlas formalization is a separate object.
- **Not a quality claim about any quantization.** That the E8 tier decodes into
  the exact accumulation says nothing about how well a 1-bit codebook
  approximates a given model's weights. VQ quality is measured per (model,
  codebook), never asserted; a learned codebook and any incoherence
  pre-rotation are separate derived artifacts with their own κ.
- **Not a verification of the runtime binary.** The theorems fix the
  mathematical identity the kernels are contracted to implement — that any
  correct decode-then-accumulate implementation is codec- and
  schedule-invariant — and prove that the modeled wrapping-`i32` pipeline
  realizes the ℤ semantics under the no-overflow ceiling (§4b). They do not
  verify that a particular compiled kernel implements the modeled pipeline;
  that remains the runtime's witness (bit-identity across backends), which is
  provenance, not a theorem here.

### The honest one-line version

The first runtime demonstration that matmul in UOR is decode-then-accumulate
over content-addressed weight codes, with one substrate-invariant arithmetic
identity witnessed bit-identical across four backends and three tiers, and E8
giving an 8-D lattice-codebook weight quotient. The exactness
bound is what makes the invariance bit-level. The formal proof in the Atlas
sense, and the quality of any specific codebook, are separate objects.
-/

set_option autoImplicit false
set_option linter.missingDocs true

namespace UorMatMul

/-! ## 0. The working alphabet and the codec model

Parameters, in the Atlas manner (every constant derives from the declared
tuple): the alphabet bound `B : Nat` and the accumulator capacity `cap : Nat`.
The W8A8 tier instantiates `(B, cap) = (127, 2³¹ − 1)` in §4; no definition
or theorem statement before §4 mentions those numerals. -/

/-- The working alphabet element type. The runtime alphabet is the finite range
`{-B..B}` (W8A8: `{-127..127}`, signed i8 with `-128` excluded by symmetric
quantization); we model elements as `Int` and carry the range as an explicit
hypothesis (`InAlphabet`) exactly where a theorem needs it. The exactness
bounds of §3 are what keep every accumulation inside `Int` honest. -/
abbrev Elem := Int

/-- Membership in the symmetric alphabet of bound `B`: the magnitude of `x`
is at most `B`. This is the entire interface the exactness theorems need. -/
def InAlphabet (B : Nat) (x : Elem) : Prop := x.natAbs ≤ B

/-- A **codec** is a decode from a stored code (any type) into the working
alphabet, and `decodedSeq` is the operand stream it produces. i8 is the
identity codec (`code = value`); i4 decodes a nibble through a 16-entry grid.
The formalization is generic over the code type, so all scalar tiers are one
theorem. -/
def decodedSeq {Code : Type} (d : Code → Elem) (c : List Code) : List Elem :=
  c.map d

/-- A **block codec** decodes one stored code into a *vector* of alphabet
elements — the E8 shape, where one `u8` lattice index decodes through the
256×8 codebook into eight weights. `blockDecodedSeq` is the concatenated
operand stream. -/
def blockDecodedSeq {Code : Type} (d : Code → List Elem) (c : List Code) :
    List Elem :=
  c.flatMap d

/-- Every scalar codec is the block codec of its singleton blocks: the two
codec models agree, so no theorem needs stating twice. -/
theorem scalar_eq_block {Code : Type} (d : Code → Elem) (c : List Code) :
    decodedSeq d c = blockDecodedSeq (fun x => [d x]) c := by
  induction c with
  | nil => rfl
  | cons x xs ih => simp [decodedSeq, blockDecodedSeq] at ih ⊢; exact ih

/-- The identity codec is the i8 tier: the stored code *is* the alphabet
element, and decoding is transparent. -/
theorem i8_identity (c : List Elem) : decodedSeq id c = c :=
  List.map_id c

/-- The exact integer accumulation: `Σ aᵢ · wᵢ` over the decoded weights,
taken in `Int`. This is the one pipeline every tier feeds
(`cvtepi8→madd` / `i32x4_dot_i16x8`), modeled at its exact-integer semantics.
`zip` truncates to the shorter stream, so alignment is by construction; the
schedule theorems carry explicit length hypotheses where alignment must be
preserved across a split. -/
def dot (a w : List Elem) : Int :=
  (a.zip w).foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0

/-- The fold with a nonzero seed splits off the seed: the accumulator threads
additively. Proved by induction on the operand-pair list, generalizing the
seed. Core Lean only (`List.foldl`, `omega` for the `Int` step). Used to pin
`dot`'s computation rules here and to peel schedule boundaries in §2. -/
theorem foldl_dot_seed (s : Int) (ps : List (Elem × Elem)) :
    ps.foldl (fun acc p => acc + p.1 * p.2) s
      = s + ps.foldl (fun acc p => acc + p.1 * p.2) 0 := by
  induction ps generalizing s with
  | nil => simp
  | cons p rest ih =>
    simp only [List.foldl_cons]
    rw [ih (s + p.1 * p.2), ih (0 + p.1 * p.2)]
    omega

/-! ### The semantics of `dot`, pinned

The invariance theorems of §1 are congruences: they transport *whatever* `dot`
computes across codec factorizations. So that they are anchored to the actual
accumulation and not to an arbitrary function, the three computation rules
below pin `dot` extensionally, and `dot_unique` proves the pin is complete:
any function satisfying the same three rules agrees with `dot` on all inputs.
Congruence plus a complete specification is exactly well-definedness of *this*
matmul on decoded sequences. -/

/-- Computation rule: empty activation stream accumulates to `0`. -/
theorem dot_nil_left (w : List Elem) : dot [] w = 0 := rfl

/-- Computation rule: empty weight stream accumulates to `0`. -/
theorem dot_nil_right (a : List Elem) : dot a [] = 0 := by
  unfold dot
  rw [List.zip_nil_right]
  rfl

/-- Computation rule: one aligned pair contributes its exact product, and the
tail accumulates independently. This is the defining recurrence of the
multiply–accumulate pipeline. -/
theorem dot_cons (x y : Elem) (a w : List Elem) :
    dot (x :: a) (y :: w) = x * y + dot a w := by
  unfold dot
  rw [List.zip_cons_cons, List.foldl_cons, foldl_dot_seed]
  simp

/-- The three computation rules characterize `dot` uniquely: any binary
operation on streams satisfying them is `dot`. The congruence theorems of §1
therefore certify the invariance of *this* accumulation — the one that
computes `Σ aᵢ·wᵢ` — not of some unconstrained function of the streams. -/
theorem dot_unique (f : List Elem → List Elem → Int)
    (h0l : ∀ w, f [] w = 0) (h0r : ∀ a, f a [] = 0)
    (hc : ∀ x y a w, f (x :: a) (y :: w) = x * y + f a w) :
    ∀ a w, f a w = dot a w := by
  intro a
  induction a with
  | nil => intro w; rw [h0l, dot_nil_left]
  | cons x a ih =>
    intro w
    cases w with
    | nil => rw [h0r, dot_nil_right]
    | cons y w => rw [hc, dot_cons, ih]

/-! ## 1. Codec-invariance — the load-bearing theorem (CL-MM01)

The accumulation is a function of the decoded operand sequence alone. Each
statement below is a congruence, closed by rewriting — and a congruence alone
would hold for any function of the streams. What anchors these theorems to
the real multiply–accumulate is the specification block in §0
(`dot_nil_left` / `dot_nil_right` / `dot_cons`, complete by `dot_unique`):
congruence transports exactly the semantics that block pins. The point is not
proof difficulty but that the *statement* is expressible at all — the codec
is not an argument of the arithmetic — which is what separates "matmul over a
codec" from "matmul over stored values". -/

/-- **CL-MM01 — codec-invariance.** If two codec/stream factorizations decode
to the same operand sequence, the accumulation is identical. The result depends
only on the decoded operands, never on which codec (i8 / i4 / E8) produced them.

This is the well-definedness half of the bit-identity the runtime witnesses
across tiers — the semantics being transported is pinned by `dot_unique`:
`d₁ ∘ c₁ = d₂ ∘ c₂ ⟹ dot a (decode d₁ c₁) = dot a (decode d₂ c₂)`. -/
theorem codec_invariance
    {C₁ C₂ : Type} (a : List Elem)
    (d₁ : C₁ → Elem) (c₁ : List C₁)
    (d₂ : C₂ → Elem) (c₂ : List C₂)
    (h : decodedSeq d₁ c₁ = decodedSeq d₂ c₂) :
    dot a (decodedSeq d₁ c₁) = dot a (decodedSeq d₂ c₂) := by
  rw [h]

/-- **CL-MM01, both operands.** In W8A8 the activations are themselves
quantized codes; codec-invariance holds when *both* streams are decoded — the
accumulation depends only on the two decoded sequences. -/
theorem codec_invariance₂
    {A₁ A₂ C₁ C₂ : Type}
    (e₁ : A₁ → Elem) (b₁ : List A₁) (e₂ : A₂ → Elem) (b₂ : List A₂)
    (d₁ : C₁ → Elem) (c₁ : List C₁) (d₂ : C₂ → Elem) (c₂ : List C₂)
    (ha : decodedSeq e₁ b₁ = decodedSeq e₂ b₂)
    (hw : decodedSeq d₁ c₁ = decodedSeq d₂ c₂) :
    dot (decodedSeq e₁ b₁) (decodedSeq d₁ c₁)
      = dot (decodedSeq e₂ b₂) (decodedSeq d₂ c₂) := by
  rw [ha, hw]

/-- **CL-MM01, block form.** The same invariance for block codecs (E8): if two
block factorizations concatenate to the same operand stream, the accumulation
agrees. With `scalar_eq_block` this subsumes mixed scalar/block comparisons —
e.g. an i8 stream against the E8 blocks that decode to the same weights. -/
theorem block_codec_invariance
    {C₁ C₂ : Type} (a : List Elem)
    (d₁ : C₁ → List Elem) (c₁ : List C₁)
    (d₂ : C₂ → List Elem) (c₂ : List C₂)
    (h : blockDecodedSeq d₁ c₁ = blockDecodedSeq d₂ c₂) :
    dot a (blockDecodedSeq d₁ c₁) = dot a (blockDecodedSeq d₂ c₂) := by
  rw [h]

/-- Transcoding: re-encoding a stream through a code map `e` and decoding with
`d` is the same as decoding with the composite codec `d ∘ e`. Tier migration
(e.g. i8 codes re-indexed into a codebook) composes at the codec level and
never touches the accumulation. -/
theorem transcode_decode {C₁ C₂ : Type} (e : C₁ → C₂) (d : C₂ → Elem)
    (c : List C₁) :
    decodedSeq d (c.map e) = decodedSeq (d ∘ e) c :=
  List.map_map d e c

/-- **CL-MM01, transcoding corollary.** The accumulation through a transcoded
stream equals the accumulation through the composite codec: tier migration is
invisible to matmul. -/
theorem transcode_invariance {C₁ C₂ : Type} (a : List Elem) (e : C₁ → C₂)
    (d : C₂ → Elem) (c : List C₁) :
    dot a (decodedSeq d (c.map e)) = dot a (decodedSeq (d ∘ e) c) := by
  rw [transcode_decode]

/-- A matrix–vector product over coded weights: each stored row decodes through
the codec and feeds the one exact accumulation against the activation stream.
This is `matmul_e8cb_omajor`'s output-major loop at its mathematical
semantics: one `dot` per output coordinate. -/
def matVec {Code : Type} (d : Code → Elem) (a : List Elem)
    (rows : List (List Code)) : List Int :=
  rows.map fun r => dot a (decodedSeq d r)

/-- `matVec` factors through the decoded rows: it is literally
"decode the matrix, then dot each row". The codec appears nowhere on the
right-hand side except inside the decoded rows. -/
theorem matVec_eq_map {Code : Type} (d : Code → Elem) (a : List Elem)
    (rows : List (List Code)) :
    matVec d a rows = (rows.map (decodedSeq d)).map (dot a) := by
  rw [matVec, List.map_map]; rfl

/-- **CL-MM01, matrix form.** If two coded matrices decode row-wise to the same
weight matrix, the full matrix–vector products are identical. Codec-invariance
lifts from one accumulation to the whole layer. -/
theorem matVec_codec_invariance
    {C₁ C₂ : Type} (a : List Elem)
    (d₁ : C₁ → Elem) (rows₁ : List (List C₁))
    (d₂ : C₂ → Elem) (rows₂ : List (List C₂))
    (h : rows₁.map (decodedSeq d₁) = rows₂.map (decodedSeq d₂)) :
    matVec d₁ a rows₁ = matVec d₂ a rows₂ := by
  rw [matVec_eq_map, matVec_eq_map, h]

/-! ## 2. Schedule-independence — the substrate-invariance half (CL-MM02)

Integer addition is associative and commutative, so a partitioned accumulation
(threading, SIMD tiling) equals the sequential one. We prove the split
identity, the commuted split, and the general tiled reduction: any partition
of the aligned operand streams into contiguous tiles sums the per-tile dots.
This is why the pool-column-partition threading and the 4/8-column SIMD lanes
are bit-identical to scalar. -/

/-- **CL-MM02 — schedule split.** Concatenating operand streams (with matching
first-segment lengths so the `zip` stays aligned) splits the accumulation
additively. This is the schedule-split identity that makes tiled / threaded
reduction bit-identical to sequential. The core lemma `List.zip_append`
distributes the alignment; `foldl_dot_seed` peels the carried seed at the
boundary. Core Lean only. -/
theorem dot_split (a₁ a₂ w₁ w₂ : List Elem)
    (h₁ : a₁.length = w₁.length) :
    dot (a₁ ++ a₂) (w₁ ++ w₂) = dot a₁ w₁ + dot a₂ w₂ := by
  have hz : (a₁ ++ a₂).zip (w₁ ++ w₂) = a₁.zip w₁ ++ a₂.zip w₂ :=
    List.zip_append h₁
  unfold dot
  rw [hz, List.foldl_append, foldl_dot_seed]

/-- **CL-MM02 — tile commutation.** The two halves of a split reduce in either
order: `Int` addition is commutative, so no reduction schedule can distinguish
which tile finished first. The general statement — invariance under arbitrary
reordering of the tiles — is `dot_tiled_perm` below. -/
theorem dot_swap (a₁ a₂ w₁ w₂ : List Elem)
    (h₁ : a₁.length = w₁.length) (h₂ : a₂.length = w₂.length) :
    dot (a₁ ++ a₂) (w₁ ++ w₂) = dot (a₂ ++ a₁) (w₂ ++ w₁) := by
  rw [dot_split a₁ a₂ w₁ w₂ h₁, dot_split a₂ a₁ w₂ w₁ h₂, Int.add_comm]

/-- Seed-peeling for the plain integer-sum fold, the reduction that combines
per-tile results. Same induction as `foldl_dot_seed`. -/
theorem foldl_add_seed (s : Int) (l : List Int) :
    l.foldl (· + ·) s = s + l.foldl (· + ·) 0 := by
  induction l generalizing s with
  | nil => simp
  | cons x rest ih =>
    simp only [List.foldl_cons]
    rw [ih (s + x), ih (0 + x)]
    omega

/-- **CL-MM02 — general tiled reduction.** Partition the operand streams into
any list of aligned tiles: the dot of the concatenations equals the fold-sum
of the per-tile dots. Every tiling/threading strategy — 4-column SIMD lanes,
pool-column partitions, cache-sized panels — is an instance, so all of them
produce the same integer as the sequential loop. Induction on the tile list;
`dot_split` peels one tile per step. -/
theorem dot_tiled (ts : List (List Elem × List Elem))
    (h : ∀ t ∈ ts, (Prod.fst t).length = (Prod.snd t).length) :
    dot (ts.map Prod.fst).flatten (ts.map Prod.snd).flatten
      = (ts.map fun t => dot t.1 t.2).foldl (· + ·) 0 := by
  induction ts with
  | nil => rfl
  | cons t ts ih =>
    have ht : (Prod.fst t).length = (Prod.snd t).length :=
      h t (List.mem_cons_self t ts)
    have hts : ∀ t' ∈ ts, (Prod.fst t').length = (Prod.snd t').length :=
      fun t' ht' => h t' (List.mem_cons_of_mem t ht')
    simp only [List.map_cons, List.flatten_cons, List.foldl_cons]
    rw [dot_split _ _ _ _ ht, ih hts,
      foldl_add_seed (0 + dot t.1 t.2) (ts.map fun t => dot t.1 t.2)]
    omega

/-- The integer-sum fold is invariant under permutation of its operands:
induction over the permutation, with `foldl_add_seed` peeling seeds at each
constructor. This is the algebraic content of "reduction order does not
matter" — associativity and commutativity of `Int.add`, mechanized. -/
theorem foldl_add_perm (l₁ l₂ : List Int) (hp : l₁.Perm l₂) :
    l₁.foldl (· + ·) 0 = l₂.foldl (· + ·) 0 := by
  induction hp with
  | nil => rfl
  | cons x _ ih =>
    simp only [List.foldl_cons]
    rw [foldl_add_seed, foldl_add_seed (0 + x), ih]
  | swap x y l =>
    simp only [List.foldl_cons]
    rw [foldl_add_seed, foldl_add_seed (0 + x + y)]
    omega
  | trans _ _ ih₁ ih₂ =>
    rw [ih₁, ih₂]

/-- **CL-MM02 — arbitrary completion order.** Reordering the tiles of a
partition — any permutation, hence any completion order a scheduler could
realize — leaves the accumulation unchanged: both orders reduce to the same
integer. Alignment of the reordered tiling is inherited from the original
through the permutation, so only one alignment hypothesis is needed. With
`dot_split`/`dot_tiled` this closes schedule-independence in full: contiguous
splitting, tiling, and tile reordering are all invisible to the result. -/
theorem dot_tiled_perm (ts₁ ts₂ : List (List Elem × List Elem))
    (hp : ts₁.Perm ts₂)
    (h : ∀ t ∈ ts₁, (Prod.fst t).length = (Prod.snd t).length) :
    dot (ts₁.map Prod.fst).flatten (ts₁.map Prod.snd).flatten
      = dot (ts₂.map Prod.fst).flatten (ts₂.map Prod.snd).flatten := by
  have h₂ : ∀ t ∈ ts₂, (Prod.fst t).length = (Prod.snd t).length :=
    fun t ht => h t (hp.mem_iff.mpr ht)
  rw [dot_tiled ts₁ h, dot_tiled ts₂ h₂]
  exact foldl_add_perm _ _ (hp.map _)

/-! ## 3. Exactness — why the invariance is bit-level, not approximate (CL-MM03)

Under the no-overflow bound the accumulation never leaves the exact integer
regime, so there is no rounding step at which two schedules or two codecs could
diverge. The bound is proved parametrically in `(B, cap)` and pinned at the
runtime's stated W8A8 values in §4. -/

/-- Magnitude bound for the accumulation fold: if every operand pair lies in
the alphabet of bound `B`, the fold magnitude is at most `k · B²` for `k` the
number of pairs. Induction with the seed peeled by `foldl_dot_seed`; the step
is the triangle inequality (`Int.natAbs_add_le`) and multiplicativity of
`natAbs`. Intermediate accumulator states obey the same bound — that is
`partial_sum_natAbs_le` below, not a remark. -/
theorem foldl_dot_natAbs_le (B : Nat) (ps : List (Elem × Elem))
    (h : ∀ p ∈ ps, (Prod.fst p).natAbs ≤ B ∧ (Prod.snd p).natAbs ≤ B) :
    (ps.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0).natAbs
      ≤ ps.length * (B * B) := by
  induction ps with
  | nil => simp
  | cons p rest ih =>
    have hp : p.1.natAbs ≤ B ∧ p.2.natAbs ≤ B := h p (List.mem_cons_self p rest)
    have hrest : ∀ q ∈ rest, (Prod.fst q).natAbs ≤ B ∧ (Prod.snd q).natAbs ≤ B :=
      fun q hq => h q (List.mem_cons_of_mem p hq)
    calc ((p :: rest).foldl (fun acc (q : Elem × Elem) => acc + q.1 * q.2) 0).natAbs
        = ((0 + p.1 * p.2)
            + rest.foldl (fun acc (q : Elem × Elem) => acc + q.1 * q.2) 0).natAbs := by
          rw [List.foldl_cons, foldl_dot_seed]
      _ ≤ (0 + p.1 * p.2).natAbs
            + (rest.foldl (fun acc (q : Elem × Elem) => acc + q.1 * q.2) 0).natAbs :=
          Int.natAbs_add_le _ _
      _ = p.1.natAbs * p.2.natAbs
            + (rest.foldl (fun acc (q : Elem × Elem) => acc + q.1 * q.2) 0).natAbs := by
          rw [Int.zero_add, Int.natAbs_mul]
      _ ≤ B * B + rest.length * (B * B) :=
          Nat.add_le_add (Nat.mul_le_mul hp.1 hp.2) (ih hrest)
      _ = (rest.length + 1) * (B * B) := by
          rw [Nat.succ_mul, Nat.add_comm]
      _ = (p :: rest).length * (B * B) := by
          rw [List.length_cons]

/-- **CL-MM03 — partial sums.** Every intermediate accumulator state of a
sequential reduction is the fold over a prefix `ps₁` of the pair stream, and it
obeys the prefix's own bound `|ps₁| · B²`. Hence under the `kMax` ceiling of
`accum_le_cap` no *partial* sum overflows either — the property the hardware
accumulator actually needs, since it materializes every intermediate state. -/
theorem partial_sum_natAbs_le (B : Nat) (ps₁ ps₂ : List (Elem × Elem))
    (h : ∀ p ∈ ps₁ ++ ps₂, (Prod.fst p).natAbs ≤ B ∧ (Prod.snd p).natAbs ≤ B) :
    (ps₁.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0).natAbs
      ≤ ps₁.length * (B * B) :=
  foldl_dot_natAbs_le B ps₁ fun p hp => h p (List.mem_append_left ps₂ hp)

/-- **CL-MM03 — parametric magnitude bound.** For alphabet-`B` operand streams,
the accumulation magnitude is at most `k · B²`, `k = min |a| |w|` the number of
aligned pairs. Purely structural: no numeral appears. -/
theorem dot_natAbs_le (B : Nat) (a w : List Elem)
    (ha : ∀ x ∈ a, InAlphabet B x) (hw : ∀ x ∈ w, InAlphabet B x) :
    (dot a w).natAbs ≤ min a.length w.length * (B * B) := by
  have hmem : ∀ p ∈ a.zip w, (Prod.fst p).natAbs ≤ B ∧ (Prod.snd p).natAbs ≤ B :=
    fun p hp => ⟨ha p.1 (List.of_mem_zip hp).1, hw p.2 (List.of_mem_zip hp).2⟩
  have hb := foldl_dot_natAbs_le B (a.zip w) hmem
  rw [List.length_zip] at hb
  unfold dot
  exact hb

/-- The exact-accumulation ceiling on the pair count for a given alphabet bound
and accumulator capacity: `kMax B cap = ⌊cap / B²⌋`. Derived, not declared —
the W8A8 numeral `133144` is a theorem about this definition (§4), in the way
F1 pins `decide`-proved Atlas constants. -/
def kMax (B cap : Nat) : Nat := cap / (B * B)

/-- **CL-MM03 — parametric no-overflow.** A `k`-pair worst-case accumulation
stays within the capacity whenever `k ≤ kMax B cap`. The proof is exactly
`⌊cap/B²⌋ · B² ≤ cap` plus monotonicity — no numerals, no `decide`. -/
theorem accum_le_cap (B cap k : Nat) (hk : k ≤ kMax B cap) :
    k * (B * B) ≤ cap :=
  Nat.le_trans (Nat.mul_le_mul hk (Nat.le_refl (B * B)))
    (Nat.div_mul_le_self cap (B * B))

/-- **CL-MM03 — exactness, assembled.** Alphabet-bounded streams of aligned
length at most `kMax B cap` accumulate to a magnitude at most `cap`: the `Int`
model never exceeds the machine capacity. The step from this bound to "a
two's-complement accumulator of that width computes the same integer" is
itself a theorem for the 32-bit W8A8 instantiation (`i32_fold_exact`, §4b);
other widths follow by the same argument but are not instantiated here.
Combined with CL-MM01/CL-MM02 this makes the invariance bit-level: there is no
rounding or overflow step at which two codecs or two schedules could
diverge. -/
theorem dot_exact (B cap : Nat) (a w : List Elem)
    (ha : ∀ x ∈ a, InAlphabet B x) (hw : ∀ x ∈ w, InAlphabet B x)
    (hk : min a.length w.length ≤ kMax B cap) :
    (dot a w).natAbs ≤ cap :=
  Nat.le_trans (dot_natAbs_le B a w ha hw) (accum_le_cap B cap _ hk)

/-- The intermediate accumulator state of a sequential reduction after a
prefix `ps₁` *is* the fold over `ps₁`: the concatenated fold resumes from it.
Core `List.foldl_append`, restated for the accumulation step so that the
prefix identification used by `partial_sum_le_cap` is a theorem in this file,
not an inference left to the reader. -/
theorem foldl_dot_append (ps₁ ps₂ : List (Elem × Elem)) :
    (ps₁ ++ ps₂).foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0
      = ps₂.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2)
          (ps₁.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0) :=
  List.foldl_append _ _ ps₁ ps₂

/-- **CL-MM03 — partial sums under the ceiling, assembled.** When the whole
pair stream fits under the `kMax` ceiling, *every* intermediate accumulator
state — by `foldl_dot_append`, the fold over the corresponding prefix `ps₁` —
stays within the capacity, not just the final sum. This is the composed
statement the hardware accumulator needs; it is a theorem here, not an
inference left to the reader. -/
theorem partial_sum_le_cap (B cap : Nat) (ps₁ ps₂ : List (Elem × Elem))
    (h : ∀ p ∈ ps₁ ++ ps₂, (Prod.fst p).natAbs ≤ B ∧ (Prod.snd p).natAbs ≤ B)
    (hk : (ps₁ ++ ps₂).length ≤ kMax B cap) :
    (ps₁.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) 0).natAbs ≤ cap := by
  have h₁ := partial_sum_natAbs_le B ps₁ ps₂ h
  have h₂ : ps₁.length ≤ kMax B cap := by
    rw [List.length_append] at hk
    omega
  exact Nat.le_trans h₁ (accum_le_cap B cap ps₁.length h₂)

/-! ## 4. The W8A8 instantiation — pinning the runtime's stated bound

Everything above is parametric. The runtime tier W8A8 is the instantiation
`(B, cap) = (127, 2³¹ − 1)`; its ceiling constant is derived and pinned here,
mirroring hologram `kernel_call::mm_act_quant::K_MAX = i32::MAX / (127·127)`
(`kernel_call.rs:83`, v0.7.2). -/

/-- The W8A8 alphabet bound: symmetric signed-i8, `{-127..127}`. -/
def w8a8Bound : Nat := 127

/-- The `i32` capacity `2³¹ − 1`, the accumulator the runtime dots into. -/
def i32Max : Nat := 2147483647

/-- The W8A8 exact-accumulation ceiling, *derived* from the parametric
definition at the tier's parameters — not declared as a magic numeral. -/
def w8a8KMax : Nat := kMax w8a8Bound i32Max

/-- **CL-MM03′ — the pinned bound value** (`⌊(2³¹−1) / 127²⌋ = 133144`),
kernel-computed by `decide`. This is the analogue of an F1 `atlas-constants`
oracle entry: a stable, `decide`-proved numeral downstream consumers may cite. -/
theorem w8a8KMax_value : w8a8KMax = 133144 := by decide

/-- **CL-MM03′ — W8A8 no-overflow.** A `k`-term worst-case dot of alphabet
elements stays below `2³¹` when `k ≤ w8a8KMax` — the magnitude precondition
under which the wrapping `i32` pipeline provably realizes the exact
accumulation (`i32_fold_exact`, §4b). The parametric theorem instantiated;
stated as the bound the runtime relies on. -/
theorem exact_within_i32 (k : Nat) (hk : k ≤ w8a8KMax) :
    k * (127 * 127) ≤ 2147483647 :=
  accum_le_cap w8a8Bound i32Max k hk

/-- **CL-MM03′ — W8A8 exactness, headline form.** For i8-alphabet streams with
at most `133144` aligned pairs, the accumulation magnitude stays within the
`i32` range; that the modeled 32-bit accumulator then *computes* this exact
value, under these same hypotheses, is `w8a8_i32_realizes_exact` (§4b).
Together with CL-MM01/CL-MM02: the W8A8 matmul result is one integer,
independent of codec, tier, tiling, threading, and substrate. -/
theorem w8a8_dot_exact (a w : List Elem)
    (ha : ∀ x ∈ a, InAlphabet w8a8Bound x)
    (hw : ∀ x ∈ w, InAlphabet w8a8Bound x)
    (hk : min a.length w.length ≤ 133144) :
    (dot a w).natAbs ≤ 2147483647 := by
  apply dot_exact w8a8Bound i32Max a w ha hw
  rw [show kMax w8a8Bound i32Max = 133144 from w8a8KMax_value]
  exact hk

/-! ## 4b. The machine model — the wrapping accumulator realizes the ℤ semantics

The bounds of §3–§4 say the exact value fits; this section proves the stronger
statement the hardware needs: a **two's-complement 32-bit accumulator, modeled
with explicit wraparound at every operation**, computes the *same integer* as
the exact `ℤ` fold whenever the stream sits under the `kMax` ceiling. The
wrap is applied after every product and after every addition — the worst
honest model of the machine pipeline — and the coincidence is proved by
showing every intermediate state stays in range, so every wrap is the
identity. This discharges, as a theorem, the step from "the bound holds" to
"the i32 path realizes the ℤ semantics". What remains outside the file is
only that a particular compiled kernel implements this modeled pipeline. -/

/-- Two's-complement wraparound at 32 bits: reduce into
`[-2³¹, 2³¹ - 1]` by shifted modulus. This models what an `i32` register does
to an out-of-range integer. -/
def wrap32 (z : Int) : Int := (z + 2147483648) % 4294967296 - 2147483648

/-- `wrap32` is the identity exactly on the representable range — an in-range
value is untouched by the register. Decided by `omega`. -/
theorem wrap32_eq_of_bounded {z : Int}
    (h₁ : -2147483648 ≤ z) (h₂ : z ≤ 2147483647) : wrap32 z = z := by
  unfold wrap32
  omega

/-- The wrapping-i32 accumulation pipeline: every product and every addition
passes through `wrap32`, as in a 32-bit register file with no widening. -/
def i32DotFold (s : Int) (ps : List (Elem × Elem)) : Int :=
  ps.foldl (fun acc (p : Elem × Elem) => wrap32 (acc + wrap32 (p.1 * p.2))) s

/-- **CL-MM04 — the wrapping fold coincides with the exact fold.** For
i8-alphabet pairs and any seed leaving room for the stream
(`|s| + k·127² ≤ 2³¹ − 1`), the fully-wrapping i32 pipeline computes exactly
the `ℤ` fold: by induction, every intermediate state is in range, so every
wrap is the identity. The seed generalization is what covers *all*
intermediate accumulator states, not just the final sum. -/
theorem i32_fold_exact (ps : List (Elem × Elem))
    (h : ∀ p ∈ ps, (Prod.fst p).natAbs ≤ 127 ∧ (Prod.snd p).natAbs ≤ 127) :
    ∀ s : Int, s.natAbs + ps.length * 16129 ≤ 2147483647 →
      i32DotFold s ps
        = ps.foldl (fun acc (p : Elem × Elem) => acc + p.1 * p.2) s := by
  induction ps with
  | nil => intro s _; rfl
  | cons p rest ih =>
    intro s hs
    rw [List.length_cons] at hs
    have hp := h p (List.mem_cons_self p rest)
    have hprod : (p.1 * p.2).natAbs ≤ 16129 := by
      rw [Int.natAbs_mul]
      have := Nat.mul_le_mul hp.1 hp.2
      omega
    have hrest : ∀ q ∈ rest, (Prod.fst q).natAbs ≤ 127 ∧ (Prod.snd q).natAbs ≤ 127 :=
      fun q hq => h q (List.mem_cons_of_mem p hq)
    have hw₁ : wrap32 (p.1 * p.2) = p.1 * p.2 :=
      wrap32_eq_of_bounded (by omega) (by omega)
    have hw₂ : wrap32 (s + p.1 * p.2) = s + p.1 * p.2 :=
      wrap32_eq_of_bounded (by omega) (by omega)
    have hnext : (s + p.1 * p.2).natAbs + rest.length * 16129 ≤ 2147483647 := by
      omega
    unfold i32DotFold at ih ⊢
    simp only [List.foldl_cons]
    rw [hw₁, hw₂]
    exact ih hrest (s + p.1 * p.2) hnext

/-- **CL-MM04 — W8A8 realization, headline form.** Under exactly the
hypotheses of `w8a8_dot_exact`, the fully-wrapping i32 accumulator applied to
the aligned pair stream returns `dot a w` itself: the ℤ semantics and the
modeled 32-bit hardware pipeline coincide, value for value, with no
wraparound event anywhere in the reduction. -/
theorem w8a8_i32_realizes_exact (a w : List Elem)
    (ha : ∀ x ∈ a, InAlphabet w8a8Bound x)
    (hw : ∀ x ∈ w, InAlphabet w8a8Bound x)
    (hk : min a.length w.length ≤ 133144) :
    i32DotFold 0 (a.zip w) = dot a w := by
  have hmem : ∀ p ∈ a.zip w, (Prod.fst p).natAbs ≤ 127 ∧ (Prod.snd p).natAbs ≤ 127 :=
    fun p hp => ⟨ha p.1 (List.of_mem_zip hp).1, hw p.2 (List.of_mem_zip hp).2⟩
  have hlen : (a.zip w).length ≤ 133144 := by
    rw [List.length_zip]
    exact hk
  have hbound : (0 : Int).natAbs + (a.zip w).length * 16129 ≤ 2147483647 := by
    have := Nat.mul_le_mul hlen (Nat.le_refl 16129)
    omega
  exact i32_fold_exact (a.zip w) hmem 0 hbound

end UorMatMul

/-! ## 5. Audit — the F1 honesty contract, embedded

`#guard` re-evaluates the pinned constant at elaboration time; `#print axioms`
displays the exact axiom footprint of every theorem in the build log.
Expected: every theorem reports axioms ⊆ `{propext, Quot.sound}`. Five report
none at all — the three invariance theorems that rewrite only a hypothesis
(`codec_invariance`, `codec_invariance₂`, `block_codec_invariance`), the
definitional `dot_nil_left`, and the `decide`-proved `w8a8KMax_value`; the
rest carry `propext`, most also `Quot.sound`, both inherited from the core
rewrite lemmas and induction principles they invoke. Anything else — in
particular `sorryAx`
or `Classical.choice` — is a build failure of the discipline, even if Lean
accepts the file. -/

#guard UorMatMul.w8a8KMax = 133144

#print axioms UorMatMul.scalar_eq_block
#print axioms UorMatMul.i8_identity
#print axioms UorMatMul.dot_nil_left
#print axioms UorMatMul.dot_nil_right
#print axioms UorMatMul.dot_cons
#print axioms UorMatMul.dot_unique
#print axioms UorMatMul.codec_invariance
#print axioms UorMatMul.codec_invariance₂
#print axioms UorMatMul.block_codec_invariance
#print axioms UorMatMul.transcode_decode
#print axioms UorMatMul.transcode_invariance
#print axioms UorMatMul.matVec_eq_map
#print axioms UorMatMul.matVec_codec_invariance
#print axioms UorMatMul.foldl_dot_seed
#print axioms UorMatMul.dot_split
#print axioms UorMatMul.dot_swap
#print axioms UorMatMul.foldl_add_seed
#print axioms UorMatMul.dot_tiled
#print axioms UorMatMul.foldl_add_perm
#print axioms UorMatMul.dot_tiled_perm
#print axioms UorMatMul.foldl_dot_natAbs_le
#print axioms UorMatMul.partial_sum_natAbs_le
#print axioms UorMatMul.foldl_dot_append
#print axioms UorMatMul.partial_sum_le_cap
#print axioms UorMatMul.dot_natAbs_le
#print axioms UorMatMul.accum_le_cap
#print axioms UorMatMul.dot_exact
#print axioms UorMatMul.w8a8KMax_value
#print axioms UorMatMul.exact_within_i32
#print axioms UorMatMul.w8a8_dot_exact
#print axioms UorMatMul.wrap32_eq_of_bounded
#print axioms UorMatMul.i32_fold_exact
#print axioms UorMatMul.w8a8_i32_realizes_exact
