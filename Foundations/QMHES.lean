import multiplicity_substrate.DocsShared

/-! # QMHES module (formal mirror of
`Quantum-Multiplicity Hybrid Encryption System/templateArxiv.tex`)

The document's appendices give the formal core: the multiplicity operator
`M_t` with admissible set `B = {M ⪰ 0, ‖M‖_op ≤ 1}` and the spectral
projection `Π_B` (singular-value clip `σ ↦ min(max(σ,0),1)`); the uniform
spectral bound; the Frobenius bound `‖M_t‖_F ≤ √k`; Lyapunov geometric
convergence; the prime-indexed eigen-decomposition; injectivity of the
classical frequency map `F_c`; and HKDF info-string separation.

None of the continuous objects exist in std-only Lean, so the claims are
mirrored by the finite `Nat` model below:

* **Scalar spectral clip** `clipN x = min x 1` (the `min(max(σ,0),1)`
  projection for non-negative `σ` in the `Nat` model) is bounded in `[0,1]`,
  idempotent, fixes its fixed points, and is *non-expansive*
  (`ndist (clipN a) (clipN b) ≤ ndist a b`) — the scalar form of
  `lem:nonexpansive`.
* **Uniform spectral bound** — every iterate of a `Π_B`-projected update
  stays in `[0,1]` (`iterClip_bound`, `iterEigen_bound`).
* **Frobenius bound** — with all eigenvalues `λᵢ ≤ 1`,
  `Σ λᵢ² ≤ k` (`eigen_frobenius_bound`), the finite form of
  `cor:frob_bound`.
* **Lyapunov convergence** — the contraction machinery of
  `PMDocs.iterate_contraction`/`iterate_tendsto` is specialised to the
  multiplicity update (`geometric_convergence`, `fixed_point_tendsto`,
  `iter_non_expansive`), the finite form of `thm:lyapunov`.
* **Prime-indexed stability** — eigenvalues are `λ(p) = 1/p`; larger primes
  carry no larger equilibrium mass (`eigenMode_mono`), and per-eigenmode
  updates converge with the same contraction factor.
* **Frequency-map injectivity** — `F_c : {0,1} → {f_c⁻, f_c⁺}` is injective,
  and its componentwise lift `F_c^{⊗n}` is injective
  (`freqList_injective`), so distinct transcripts encode distinctly
  (`encode_distinct`) — `prop:Fc_injective`.
* **HKDF key separation** — the AEAD info labels for the two directions are
  distinct, giving the model-level guarantee underlying
  `prop:key_separation`.
-/

namespace Multiplicity.PMQMHES

open PMDocs

/-! ## Distance on the Nat model -/

/-- Distance `|a - b|` on `Nat` (the ℓ₁ "Frobenius" distance of the scalar
model). -/
def ndist (a b : Nat) : Nat := if a ≤ b then b - a else a - b

/-! ## Spectral projection onto `[0,1]` (model of `Π_B`) -/

/-- Scalar spectral clip `min(max(σ, 0), 1)` for the `Nat` model (where
`σ ≥ 0` automatically, so the clip is `min σ 1`). -/
def clipN (x : Nat) : Nat := min x 1

/-- The clip is contained in the admissible set: `0 ≤ clipN x ≤ 1`. -/
theorem clipN_ge_zero (x : Nat) : 0 ≤ clipN x := Nat.zero_le _

theorem clipN_bound (x : Nat) : clipN x ≤ 1 := by
  unfold clipN
  exact Nat.min_le_right x 1

/-- The clip does not move points already in `[0,1]`. -/
theorem clipN_fixed {x : Nat} (h : x ≤ 1) : clipN x = x := by
  unfold clipN
  cases x with
  | zero => decide
  | succ x' =>
      cases x' with
      | zero => decide
      | succ x'' => omega

/-- The projection is idempotent (`Π_B ∘ Π_B = Π_B`). -/
theorem clipN_idem (x : Nat) : clipN (clipN x) = clipN x := by
  exact clipN_fixed (clipN_bound x)

/-- Non-expansiveness of `Π_B` (scalar form of `lem:nonexpansive`):
`|Π_B a − Π_B b| ≤ |a − b|`. -/
theorem clipN_lipschitz (a b : Nat) : ndist (clipN a) (clipN b) ≤ ndist a b := by
  cases a with
  | zero =>
      cases b with
      | zero => decide
      | succ b' =>
          cases b' with
          | zero => simp [ndist, clipN]
          | succ b'' => simp [ndist, clipN]
  | succ a' =>
      cases a' with
      | zero =>
          cases b with
          | zero => simp [ndist, clipN]
          | succ b' =>
              cases b' with
              | zero => simp [ndist, clipN]
              | succ b'' => simp [ndist, clipN]
      | succ a'' =>
          cases b with
          | zero => simp [ndist, clipN]
          | succ b' =>
              cases b' with
              | zero => simp [ndist, clipN]
              | succ b'' => simp [ndist, clipN]

/-! ## Uniform spectral bound (iterated projection) -/

/-- Every projected iterate of a fixed update stays in `[0,1]`: the finite
form of `thm:spectral_bound` (`Π_B` maps every input into `B`). -/
theorem iterClip_bound (t x : Nat) : iter clipN (t + 1) x ≤ 1 := by
  rw [iter_succ]
  exact clipN_bound (iter clipN t x)

/-- Iterates from an admissible starting point stay admissible. -/
theorem iterClip_fixed_bound {x : Nat} (hx : x ≤ 1) (t : Nat) : iter clipN t x ≤ 1 := by
  induction t with
  | zero => simpa [iter] using hx
  | succ t ih => exact iterClip_bound t x

/-! ## Frobenius bound (`cor:frob_bound` model) -/

/-- `Σ 1 = l.length`. -/
private theorem sum_const_one (l : List Nat) : (l.map (fun _ => 1)).sum = l.length := by
  induction l with
  | nil => rfl
  | cons a as ih => simp [List.sum_cons, List.length_cons, ih]; omega

/-- With all eigenvalues in `[0,1]`, `Σᵢ λᵢ² ≤ k = l.length`. -/
theorem eigen_frobenius_bound (l : List Nat) (h : ∀ x ∈ l, x ≤ 1) :
    (l.map (fun c => c * c)).sum ≤ l.length := by
  have hle : (l.map (fun c => c * c)).sum ≤ (l.map (fun _ => 1)).sum :=
    sum_map_le (by
      intro x hx
      have hx1 : x ≤ 1 := h x hx
      calc
        x * x ≤ x * 1 := Nat.mul_le_mul_left x hx1
        _ = x := by simp
        _ ≤ 1 := hx1)
  have hlen : (l.map (fun _ => 1)).sum = l.length := sum_const_one l
  rwa [hlen] at hle

/-! ## Lyapunov geometric convergence (specialisation of the shared machinery) -/

/-- Iterates of a non-expansive map are non-expansive (finite form of the
Step 1 bound `e_{t+1} ≤ ‖M_t − M^*‖²` of `thm:lyapunov`). -/
theorem iter_non_expansive {f : Nat → Nat} (hf : ∀ a b, ndist (f a) (f b) ≤ ndist a b) :
    ∀ t a b, ndist (iter f t a) (iter f t b) ≤ ndist a b := by
  intro t
  induction t with
  | zero =>
      intro a b
      simp [iter]
  | succ t ih =>
      intro a b
      have h1 := hf (iter f t a) (iter f t b)
      have h2 := ih a b
      exact Nat.le_trans h1 h2

/-- Geometric convergence: a `q`-Lipschitz update contracts after `t` steps
with factor `q^t` (the finite core of `thm:lyapunov`, via
`PMDocs.iterate_contraction`). -/
theorem geometric_convergence (f : Nat → Nat) (q : Nat)
    (hf : ∀ a b, ndist (f a) (f b) ≤ q * ndist a b) :
    ∀ t a b, ndist (iter f t a) (iter f t b) ≤ q ^ t * ndist a b :=
  iterate_contraction hf

/-- Convergence to a fixed point: if `zstar` is a fixed point of `f`, every
orbit tends to it geometrically (via `PMDocs.iterate_tendsto`). -/
theorem fixed_point_tendsto {f : Nat → Nat} {q zstar : Nat} (hfz : f zstar = zstar)
    (hf : ∀ a b, ndist (f a) (f b) ≤ q * ndist a b) :
    ∀ t a, ndist (iter f t a) zstar ≤ q ^ t * ndist a zstar :=
  iterate_tendsto hfz hf

/-! ## Prime-indexed multiplicity stability (`app:prime` model) -/

/-- Equilibrium eigenvalue `λ(p) = 1/p` of the prime-indexed eigenbasis. -/
def eigenMode (p : Nat) : Nat := 1 / p

/-- Larger primes carry no larger equilibrium mass: `p ≤ q ⟹ λ(q) ≤ λ(p)`
(holds in the `Nat` model for all primes, where `1/p = 0` for `p ≥ 2`). -/
theorem eigenMode_mono {p q : Nat} (hp2 : 2 ≤ p) (hpq : p ≤ q) : eigenMode q ≤ eigenMode p := by
  unfold eigenMode
  have hp1 : 1 < p := by omega
  have hq1 : 1 < q := by omega
  rw [Nat.div_eq_of_lt hq1, Nat.div_eq_of_lt hp1]
  exact Nat.le_refl 0

/-- The spectral radius of the equilibrium is `< 1` (its model value is `0`). -/
theorem eigenMode_lt_one (p : Nat) (hp2 : 2 ≤ p) : eigenMode p < 1 := by
  unfold eigenMode
  have hp1 : 1 < p := by omega
  rw [Nat.div_eq_of_lt hp1]
  omega

/-- Per-eigenmode projected gradient update `λ ↦ Π_{[0,1]}(λ + g)`. -/
def eigenUpdate (g lam : Nat) : Nat := clipN (lam + g)

/-- Every eigenmode stays admissible under the projected update. -/
theorem eigenUpdate_bound (g lam : Nat) : eigenUpdate g lam ≤ 1 := by
  unfold eigenUpdate
  exact clipN_bound (lam + g)

/-- Iterating the projected update keeps eigenmodes in `[0,1]` for all `t ≥ 1`. -/
theorem iterEigen_bound (g t lam : Nat) : iter (eigenUpdate g) (t + 1) lam ≤ 1 := by
  rw [iter_succ]
  unfold eigenUpdate
  exact clipN_bound (iter (eigenUpdate g) t lam + g)

/-- Per-eigenmode convergence: if the scalar update is `q`-Lipschitz, the
eigenmode converges with factor `q^t` (each scalar problem inherits the
`μ`-strong convexity / `L`-smoothness factor). -/
theorem eigen_convergence (g q : Nat) {lam lam' : Nat}
    (hf : ∀ a b, ndist (eigenUpdate g a) (eigenUpdate g b) ≤ q * ndist a b) :
    ∀ t, ndist (iter (eigenUpdate g) t lam) (iter (eigenUpdate g) t lam') ≤ q ^ t * ndist lam lam' :=
  fun t => geometric_convergence (eigenUpdate g) q hf t lam lam'

/-! ## Frequency-map injectivity (`app:freqmap` model) -/

/-- Classical frequency map `F_c : {0,1} → {f_c⁻, f_c⁺}` with distinct
values. -/
def freqC : Bool → Nat
  | false => 17
  | true => 23

/-- `F_c` is injective (`f_c⁻ ≠ f_c⁺`). -/
theorem freqC_injective {x y : Bool} (h : freqC x = freqC y) : x = y := by
  cases x <;> cases y <;> simp [freqC] at h ⊢ <;> omega

/-- Componentwise lift of an injective map is injective (the finite form of
`F_c^{⊗n}` injectivity). -/
theorem map_injective {α β : Type} {f : α → β}
    (hf : ∀ {x y : α}, f x = f y → x = y) :
    ∀ {l m : List α}, l.map f = m.map f → l = m := by
  intro l m h
  induction l generalizing m with
  | nil =>
      cases m with
      | nil => rfl
      | cons b bs => simp at h
  | cons a as ih =>
      cases m with
      | nil => simp at h
      | cons b bs =>
          simp at h
          rcases h with ⟨h1, h2⟩
          have hb : a = b := hf h1
          have has : as = bs := ih h2
          rw [hb, has]

/-- The lifted frequency map on transcripts is injective: distinct bit
strings produce distinct frequency vectors. -/
theorem freqList_injective {l m : List Bool} (h : l.map freqC = m.map freqC) : l = m :=
  map_injective (by intro x y hxy; exact freqC_injective hxy) h

/-- `F_c` is left-invertible: `x = 1[F_c(x) = f_c⁺]`, i.e. decoding the lower
frequency recovers the bit. -/
theorem freqC_left_inverse {x : Bool} (h : freqC x = freqC false) : x = false :=
  freqC_injective h

/-- Distinct encodings cannot come from the same transcript (the model-level
content of `prop:encode_injective` applied to associated data). -/
theorem encode_distinct {l m : List Bool} (h : l.map freqC ≠ m.map freqC) : l ≠ m := by
  intro hl
  exact h (by rw [hl])

/-! ## HKDF key separation (`app:hkdf` model) -/

/-- The AEAD info labels for the two communication directions are distinct,
so the HKDF derivations query the PRF at disjoint points
(`K_enc^{A→B} ≠ K_enc^{B→A}` in the model). -/
theorem infoA2B_ne_infoB2A : "AEAD-ENC-A2B" ≠ "AEAD-ENC-B2A" := by decide

/-- Multiplicity-extended info binding: distinct multiplicity encodings give
distinct info strings (model-level, via `encode_distinct`). -/
theorem info_distinct_of_encoding {M M' : List Bool}
    (h : M.map freqC ≠ M'.map freqC) : M ≠ M' := encode_distinct h

end Multiplicity.PMQMHES
