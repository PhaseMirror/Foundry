/-
F1 square — v0.17.0 stage C, brick 3: the distinguished divisors of `𝕊` and their
POINT-COUNT intersection behaviour (the intrinsic input to the intersection lattice).

Companion §1.2 / §2.2 / §2.3. On the constructed square `𝕊` (brick 2) the distinguished
codimension-1 objects of §1.2 are realized as genuine subsets of the point set `C × C`:

  • the two fiber RULINGS — vertical fibers `V_a = {a} × C` (pullbacks of points under
    `proj1`) and horizontal fibers `H_b = C × {b}` (under `proj2`);
  • the DIAGONAL `Δ = {(m, m)}`;
  • the graph CORRESPONDENCES `Γ_n = {(m, n·m)}` of the scaling flow `mScale n`
    (brick 1) — the Connes–Consani Frobenius correspondences; `Γ_1 = Δ`.

The theorems below are the TRANSVERSE POINT COUNTS and DISJOINTNESS facts that the
intersection form is DERIVED from (brick 5, `Square/Lattice.lean`) — the program's
declarative discipline (§2.2): intersection numbers are never entered by hand; here they
are read off the constructed object:

  singleton (count 1):  V_a ∩ H_b = {(a,b)}    Δ ∩ V_a = {(a,a)}    Γ_n ∩ V_a = {(a,na)}
  empty (count 0):      V_a ∩ V_a' = ∅ (a≠a')   H_b ∩ H_b' = ∅       Γ_n ∩ Γ_m = ∅ (n≠m)
  and the §2.3 STRUCTURAL FINDING, now a theorem on canonical `𝕊`:
                        Δ ∩ Γ_n = ∅ for n ≥ 2 — the scaling Frobenius has NO transverse
                        fixed points; `Γ_n` is the TRANSLATE of `Δ` by the flow
                        (`graph_translate_diag`), so the pencil `{Γ_n}` is parallel and the
                        arithmetic content relocates to the shift lengths `log n`
                        (brick 4, `Square/Pencil.lean`).

The moving discipline for self-intersections (used by brick 5): within each ruling the
fibers are TRANSLATES of one another (`vFiber_translate`), and the translates of `Δ` are
exactly the `Γ_n` (`graph_translate_diag`); distinct translates are disjoint — that is the
derivation `E² = 0`, `Δ² = 0` (never an assumption).

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Tensor

namespace UOR.Bridge.F1Square.Square

/-- A point of the square (the carrier of `𝕊`). -/
abbrev SqPt : Type := Sq.carrier

/-- The vertical fiber `V_a = {a} × C` (pullback of the point `a` under `proj1`). -/
def vFiber (a : Nat) (z : SqPt) : Prop := z.1.val = a

/-- The horizontal fiber `H_b = C × {b}` (pullback of the point `b` under `proj2`). -/
def hFiber (b : Nat) (z : SqPt) : Prop := z.2.val = b

/-- The diagonal `Δ = {(m, m)}`. -/
def diag (z : SqPt) : Prop := z.1.val = z.2.val

/-- The graph correspondence `Γ_n = {(m, n·m)}` of the scaling flow `mScale n` —
    the Connes–Consani Frobenius correspondence at `n`. -/
def graph (n : Nat) (z : SqPt) : Prop := z.2.val = n * z.1.val

/-- `Γ_1 = Δ`: the unit of the pencil is the diagonal. -/
theorem graph_one_diag (z : SqPt) : graph 1 z ↔ diag z := by
  unfold graph diag
  rw [Nat.one_mul]
  exact eq_comm

/-- `Γ_0 = ∅`: the index `0` is degenerate (no point of `𝕊` has a coordinate `0`), so the
    pencil is genuinely indexed by the positive integers. -/
theorem graph_zero_empty (z : SqPt) : ¬ graph 0 z := by
  intro h
  have h2 : z.2.val = 0 * z.1.val := h
  rw [Nat.zero_mul] at h2
  have := z.2.property
  omega

/-- TRANSVERSE COUNT 1 — the two rulings: `V_a ∩ H_b = {(a, b)}`, a single point.
    (Derives the boundary number `E₁·E₂ = 1` of §1.3.) -/
theorem vFiber_inter_hFiber (a b : Nat) (ha : 1 ≤ a) (hb : 1 ≤ b) (z : SqPt) :
    (vFiber a z ∧ hFiber b z) ↔ z = ((⟨a, ha⟩ : MPos), (⟨b, hb⟩ : MPos)) := by
  cases z with
  | mk z1 z2 =>
    constructor
    · intro ⟨h1, h2⟩
      have e1 : z1.val = a := h1
      have e2 : z2.val = b := h2
      rw [show z1 = (⟨a, ha⟩ : MPos) from Subtype.ext e1,
        show z2 = (⟨b, hb⟩ : MPos) from Subtype.ext e2]
    · intro h
      cases h
      exact ⟨rfl, rfl⟩

/-- MOVING COUNT 0 — distinct fibers of the SAME ruling are disjoint: `V_a ∩ V_a' = ∅`.
    (With `vFiber_translate`, derives the self-intersection `E₁² = 0`.) -/
theorem vFiber_disjoint (a a' : Nat) (h : a ≠ a') (z : SqPt) :
    ¬(vFiber a z ∧ vFiber a' z) := by
  intro ⟨h1, h2⟩
  exact h (h1 ▸ h2 ▸ rfl)

/-- MOVING COUNT 0 — the horizontal ruling: `H_b ∩ H_b' = ∅` for `b ≠ b'`. -/
theorem hFiber_disjoint (b b' : Nat) (h : b ≠ b') (z : SqPt) :
    ¬(hFiber b z ∧ hFiber b' z) := by
  intro ⟨h1, h2⟩
  exact h (h1 ▸ h2 ▸ rfl)

/-- TRANSVERSE COUNT 1 — the diagonal meets each vertical fiber in one point:
    `Δ ∩ V_a = {(a, a)}`. (Derives `Δ·E₁ = 1`.) -/
theorem diag_inter_vFiber (a : Nat) (ha : 1 ≤ a) (z : SqPt) :
    (diag z ∧ vFiber a z) ↔ z = ((⟨a, ha⟩ : MPos), (⟨a, ha⟩ : MPos)) := by
  cases z with
  | mk z1 z2 =>
    constructor
    · intro ⟨h1, h2⟩
      have e1 : z1.val = z2.val := h1
      have e2 : z1.val = a := h2
      rw [show z1 = (⟨a, ha⟩ : MPos) from Subtype.ext e2,
        show z2 = (⟨a, ha⟩ : MPos) from Subtype.ext (show z2.val = a by omega)]
    · intro h
      cases h
      exact ⟨rfl, rfl⟩

/-- TRANSVERSE COUNT 1 — the diagonal meets each horizontal fiber in one point:
    `Δ ∩ H_b = {(b, b)}`. (Derives `Δ·E₂ = 1`.) -/
theorem diag_inter_hFiber (b : Nat) (hb : 1 ≤ b) (z : SqPt) :
    (diag z ∧ hFiber b z) ↔ z = ((⟨b, hb⟩ : MPos), (⟨b, hb⟩ : MPos)) := by
  cases z with
  | mk z1 z2 =>
    constructor
    · intro ⟨h1, h2⟩
      have e1 : z1.val = z2.val := h1
      have e2 : z2.val = b := h2
      rw [show z1 = (⟨b, hb⟩ : MPos) from Subtype.ext (show z1.val = b by omega),
        show z2 = (⟨b, hb⟩ : MPos) from Subtype.ext e2]
    · intro h
      cases h
      exact ⟨rfl, rfl⟩

/-- TRANSVERSE COUNT 1 — the Frobenius graph meets each vertical fiber in one point:
    `Γ_n ∩ V_a = {(a, n·a)}` (the correspondence has degree 1 over the first factor;
    derives `Γ_n·E₁ = 1`). -/
theorem graph_inter_vFiber (n a : Nat) (hn : 1 ≤ n) (ha : 1 ≤ a) (z : SqPt) :
    (graph n z ∧ vFiber a z) ↔
      z = ((⟨a, ha⟩ : MPos), (⟨n * a, one_le_mul hn ha⟩ : MPos)) := by
  cases z with
  | mk z1 z2 =>
    constructor
    · intro ⟨h1, h2⟩
      have e1 : z2.val = n * z1.val := h1
      have e2 : z1.val = a := h2
      rw [e2] at e1
      rw [show z1 = (⟨a, ha⟩ : MPos) from Subtype.ext e2,
        show z2 = (⟨n * a, one_le_mul hn ha⟩ : MPos) from Subtype.ext e1]
    · intro h
      cases h
      exact ⟨rfl, rfl⟩

/-- TRANSVERSE COUNT 1 — over a DIVISIBLE base point the graph meets the horizontal fiber
    in one point: `Γ_n ∩ H_{n·a} = {(a, n·a)}` (the cofinal family of horizontal
    representatives; derives `Γ_n·E₂ = 1`, the degree-1 count of a translation
    correspondence — NOT the degree-`n` count of the power Frobenius). -/
theorem graph_inter_hFiber (n a : Nat) (hn : 1 ≤ n) (ha : 1 ≤ a) (z : SqPt) :
    (graph n z ∧ hFiber (n * a) z) ↔
      z = ((⟨a, ha⟩ : MPos), (⟨n * a, one_le_mul hn ha⟩ : MPos)) := by
  cases z with
  | mk z1 z2 =>
    constructor
    · intro ⟨h1, h2⟩
      have e1 : z2.val = n * z1.val := h1
      have e2 : z2.val = n * a := h2
      have e3 : z1.val = a :=
        Nat.eq_of_mul_eq_mul_left (show 0 < n by omega) (e1.symm.trans e2)
      rw [show z1 = (⟨a, ha⟩ : MPos) from Subtype.ext e3,
        show z2 = (⟨n * a, one_le_mul hn ha⟩ : MPos) from Subtype.ext e2]
    · intro h
      cases h
      exact ⟨rfl, rfl⟩

/-- COMPLEMENT of `graph_inter_hFiber` — off the divisible representatives the graph
    misses the horizontal fiber entirely: `Γ_n ∩ H_b = ∅` when `n ∤ b`. This makes the
    monoid-level coarseness EXPLICIT rather than hidden: at the point level the count over
    `H_b` is `1` exactly on the cofinal divisible family (`graph_inter_hFiber`) and `0`
    otherwise; the stable (tropical) count is the constant `1`
    (`|det((1,1),(0,1))| = 1`, the R13 rule), realized by the divisible family. -/
theorem graph_inter_hFiber_empty (n b : Nat) (h : ¬ n ∣ b) (z : SqPt) :
    ¬(graph n z ∧ hFiber b z) := by
  intro ⟨h1, h2⟩
  have e1 : z.2.val = n * z.1.val := h1
  have e2 : z.2.val = b := h2
  exact h ⟨z.1.val, e2.symm.trans e1⟩

/-- THE §2.3 FINDING, point level, on canonical `𝕊`: the scaling Frobenius has NO
    transverse fixed points — `Δ ∩ Γ_n = ∅` for `n ≥ 2` (`m = n·m` is impossible for
    positive `m`). The algebraic template's fixed-point count `Δ·Γ_q = q + 1 − a` has no
    counterpart here; the arithmetic content relocates to the shift length `log n`
    (brick 4). With `graph_translate_diag` this also derives `Δ² = 0` by moving `Δ`
    along its own pencil. -/
theorem diag_inter_graph_empty (n : Nat) (hn : 2 ≤ n) (z : SqPt) :
    ¬(diag z ∧ graph n z) := by
  intro ⟨h1, h2⟩
  have hd : z.1.val = z.2.val := h1
  have hg : z.2.val = n * z.1.val := h2
  have hz1 : 1 ≤ z.1.val := z.1.property
  have hmul : 2 * z.1.val ≤ n * z.1.val := Nat.mul_le_mul_right z.1.val hn
  omega

/-- MOVING COUNT 0 — distinct graphs are disjoint: `Γ_n ∩ Γ_m = ∅` for `n ≠ m`
    (cancel the positive base point). The pencil `{Γ_n}` is PAIRWISE PARALLEL; with
    `graph_translate_diag` this derives `Γ_n² = 0`. -/
theorem graph_disjoint (n m : Nat) (h : n ≠ m) (z : SqPt) :
    ¬(graph n z ∧ graph m z) := by
  intro ⟨h1, h2⟩
  have hg1 : z.2.val = n * z.1.val := h1
  have hg2 : z.2.val = m * z.1.val := h2
  have hz1 : 1 ≤ z.1.val := z.1.property
  exact h (Nat.eq_of_mul_eq_mul_right (by omega) (hg1.symm.trans hg2))

/-- `Γ_n` IS THE TRANSLATE OF `Δ` BY THE FLOW: `Γ_n = (id × mScale n)(Δ)`. The pencil is
    the orbit of the diagonal under the scaling action — the structural reason its members
    are parallel (pairwise disjoint, never transverse). -/
theorem graph_translate_diag (n : Nat) (hn : 1 ≤ n) (z : SqPt) :
    graph n z ↔ ∃ w : SqPt, diag w ∧ z = (w.1, mScale n hn w.2) := by
  constructor
  · intro h
    have hg : z.2.val = n * z.1.val := h
    refine ⟨(z.1, z.1), rfl, ?_⟩
    cases z with
    | mk z1 z2 => exact congrArg (Prod.mk z1) (Subtype.ext hg)
  · intro ⟨w, hw, hz⟩
    have hd : w.1.val = w.2.val := hw
    subst hz
    show n * w.2.val = n * w.1.val
    rw [hd]

/-- The vertical ruling is a single TRANSLATION CLASS: `V_{k·a} = (mScale k × id)(V_a)` —
    any two vertical fibers are translates (up to the directed divisibility of the monoid).
    This is the moving step behind `E₁² = 0`: a fiber is moved to a DISJOINT translate
    (`vFiber_disjoint`) before self-intersecting. -/
theorem vFiber_translate (k a : Nat) (hk : 1 ≤ k) (z : SqPt) :
    vFiber (k * a) z ↔ ∃ w : SqPt, vFiber a w ∧ z = (mScale k hk w.1, w.2) := by
  constructor
  · intro h
    have hv : z.1.val = k * a := h
    have ha : 1 ≤ a := by
      rcases Nat.eq_zero_or_pos a with h0 | h1
      · exfalso
        have := z.1.property
        rw [h0, Nat.mul_zero] at hv
        omega
      · exact h1
    refine ⟨((⟨a, ha⟩ : MPos), z.2), rfl, ?_⟩
    cases z with
    | mk z1 z2 => exact congrArg (fun t => (t, z2)) (Subtype.ext hv)
  · intro ⟨w, hw, hz⟩
    have hv : w.1.val = a := hw
    subst hz
    show k * w.1.val = k * a
    rw [hv]

/-- Every vertical fiber is a translate of the UNIT fiber `V₁` — the vertical ruling is
    one translation pencil through `V₁` (the `a = 1` instance of `vFiber_translate`),
    which is the precise form of the "single translation class" used in the `E₁² = 0`
    moving derivation. -/
theorem vFiber_translate_unit (k : Nat) (hk : 1 ≤ k) (z : SqPt) :
    vFiber k z ↔ ∃ w : SqPt, vFiber 1 w ∧ z = (mScale k hk w.1, w.2) := by
  have h := vFiber_translate k 1 hk z
  rwa [Nat.mul_one] at h

/-- The horizontal mirror of `vFiber_translate`: `H_{k·b} = (id × mScale k)(H_b)` —
    the horizontal ruling is a translation pencil too (the `E₂² = 0` moving step). -/
theorem hFiber_translate (k b : Nat) (hk : 1 ≤ k) (z : SqPt) :
    hFiber (k * b) z ↔ ∃ w : SqPt, hFiber b w ∧ z = (w.1, mScale k hk w.2) := by
  constructor
  · intro h
    have hv : z.2.val = k * b := h
    have hb : 1 ≤ b := by
      rcases Nat.eq_zero_or_pos b with h0 | h1
      · exfalso
        have := z.2.property
        rw [h0, Nat.mul_zero] at hv
        omega
      · exact h1
    refine ⟨(z.1, (⟨b, hb⟩ : MPos)), rfl, ?_⟩
    cases z with
    | mk z1 z2 => exact congrArg (Prod.mk z1) (Subtype.ext hv)
  · intro ⟨w, hw, hz⟩
    have hv : w.2.val = b := hw
    subst hz
    show k * w.2.val = k * b
    rw [hv]

end UOR.Bridge.F1Square.Square
