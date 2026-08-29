/-
F1 square — **the dimension-independent Gram–Schmidt family** (`GramSchmidtConcrete.lean`), brick 3.5b
of the Hausdorff *sufficiency* arc. The committed `gramSchmidt_exists d` (brick 3) is a *`d`-dependent
existential*: for each truncation dimension it asserts *some* orthogonal family exists. The `L²`-limit
needs one *fixed* family, whose vectors are stable as the degree grows, and whose orthogonality holds at
*every* dimension. This file supplies exactly that, concretely:

  `gsBuild m`  : the family of the first `m` Gram–Schmidt vectors (`k ≥ m` junk-zero), by structural
                 recursion `gsBuild (m+1) = update (gsBuild m) at m by nextVec (m+1) m (gsBuild m)`;
  `gsFam k`    : `gsBuild (k+1) k` — the `k`-th orthogonal polynomial, a *single fixed* vector;
  `gsFam_den`/`gsFam_support`/`gsFam_monic` : the three structural invariants, `d`-free;
  `gsFam_ortho`  : `i ≠ j ⟹ ⟨gsFam i, gsFam j⟩_d = 0` **for every `d > i, j`** (dimension-uniform).

The invariants are proved once for `gsBuild m` by induction on `m` (mirroring `gramSchmidt_exists`), then
specialised to `gsFam` via the stability lemma `gsBuild_lt` (`k < m ⟹ gsBuild m k = gsFam k`). The
dimension-uniform orthogonality is the new ingredient: the step gives orthogonality at the *single*
dimension `m+1` (`nextVec_ortho`), and truncation-stability (`qHil_trunc_eq`, brick 3.5a) carries it to
every larger `d`, since each `gsFam` vector is finitely supported.

HONEST SCOPE. The *existence-free*, dimension-independent orthogonal family and its four `d`-uniform
invariants — finite ℚ linear algebra. This is NOT the Riesz convergence / L²-limit that builds the L²
element from a valid moment sequence (needs a supplied Bessel convergence modulus — later brick), NOT
the moment-range surjectivity, NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.GramSchmidtOrtho
import Foundations.F1.Square.QHilbertPos
import Foundations.F1.Square.QHilbertSymm
import Foundations.F1.Square.QHilbertTrunc

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `⟨0,1⟩ < x` (as rationals) forces a positive numerator. -/
private theorem num_pos_of_Qlt_zero {x : Q} (h : Qlt (⟨0, 1⟩ : Q) x) : 0 < x.num := by
  have h' : (0 : Int) * (x.den : Int) < x.num * (1 : Int) := h
  omega

-- ===========================================================================
-- The concrete family, built by structural recursion on the build depth.
-- ===========================================================================

/-- The family of the first `m` Gram–Schmidt vectors: `gsBuild m k` is the `k`-th orthogonal polynomial
    for `k < m`, and the junk-zero vector for `k ≥ m`. Each step *extends* by the next Gram–Schmidt
    vector `nextVec (m+1) m (gsBuild m)` at index `m`, keeping the earlier ones untouched. Built at each
    step at its own minimal dimension `m+1`; truncation-stability makes the value dimension-independent. -/
def gsBuild : Nat → (Nat → (Nat → Q))
  | 0 => fun _ _ => (⟨0, 1⟩ : Q)
  | (m + 1) => fun k => if k = m then nextVec (m + 1) m (gsBuild m) else gsBuild m k

/-- The `k`-th orthogonal polynomial, a single fixed coefficient vector. -/
def gsFam (k : Nat) : Nat → Q := gsBuild (k + 1) k

/-- Unfolding at the new index: `gsBuild (m+1) m = nextVec (m+1) m (gsBuild m)`. -/
private theorem gsBuild_self (m : Nat) :
    gsBuild (m + 1) m = nextVec (m + 1) m (gsBuild m) := by
  show (if m = m then nextVec (m + 1) m (gsBuild m) else gsBuild m m)
      = nextVec (m + 1) m (gsBuild m)
  rw [if_pos rfl]

/-- Unfolding off the new index: `gsBuild (m+1) k = gsBuild m k` for `k ≠ m`. -/
private theorem gsBuild_ne (m k : Nat) (h : k ≠ m) :
    gsBuild (m + 1) k = gsBuild m k := by
  show (if k = m then nextVec (m + 1) m (gsBuild m) else gsBuild m k) = gsBuild m k
  rw [if_neg h]

/-- **STABILITY**: below the build depth the family is already the fixed family — `gsBuild m k = gsFam k`
    for `k < m`. So `gsBuild M` restricted to indices `< M` is exactly `gsFam`. -/
theorem gsBuild_lt : ∀ m k, k < m → gsBuild m k = gsFam k := by
  intro m
  induction m with
  | zero => intro k hk; exact absurd hk (Nat.not_lt_zero k)
  | succ m ih =>
    intro k hk
    by_cases hkm : k = m
    · -- `gsFam m = gsBuild (m+1) m` by definition
      rw [hkm]; rfl
    · rw [gsBuild_ne m k hkm]; exact ih k (by omega)

-- ===========================================================================
-- ★ The four invariants of the concrete family, by induction on the build depth.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- **★ THE FAMILY'S INVARIANTS** at every build depth `m`: positive denominators everywhere; each
    `gsBuild m k` (`k < m`) supported on `[0,k]` and monic; and **dimension-uniform** mutual
    orthogonality `⟨gsBuild m i, gsBuild m j⟩_d = 0` for `i ≠ j` (`i,j < m`) at every `d > i, j`.
    Induction on `m`, extending by the next Gram–Schmidt vector; the step's single-dimension
    orthogonality (`nextVec_ortho` at `m+1`) is carried to all `d` by truncation-stability. -/
theorem gsBuild_props (m : Nat) :
    (∀ k idx, 0 < (gsBuild m k idx).den) ∧
    (∀ k, k < m → ∀ idx, k < idx → Qeq (gsBuild m k idx) (⟨0, 1⟩ : Q)) ∧
    (∀ k, k < m → ¬ Qeq (gsBuild m k k) (⟨0, 1⟩ : Q)) ∧
    (∀ i j, i < m → j < m → i ≠ j → ∀ d, i < d → j < d →
      Qeq (qHil (gsBuild m i) (gsBuild m j) d) (⟨0, 1⟩ : Q)) := by
  induction m with
  | zero =>
    refine ⟨fun k idx => Nat.one_pos, fun k hk => absurd hk (Nat.not_lt_zero k),
      fun k hk => absurd hk (Nat.not_lt_zero k), fun i j hi _ _ _ _ _ => absurd hi (Nat.not_lt_zero i)⟩
  | succ m ih =>
    obtain ⟨ihden, ihsupp, ihmonic, ihorth⟩ := ih
    -- the orthogonality hypothesis the step feeds `nextVec_ortho`, at dimension `m+1`
    have hqorthMp1 : ∀ a b, a < m → b < m → a ≠ b →
        Qeq (qHil (gsBuild m a) (gsBuild m b) (m + 1)) (⟨0, 1⟩ : Q) :=
      fun a b ha hb hab => ihorth a b ha hb hab (m + 1) (Nat.lt_succ_of_lt ha) (Nat.lt_succ_of_lt hb)
    refine ⟨?_, ?_, ?_, ?_⟩
    · -- denominators
      intro k idx
      by_cases hk : k = m
      · have hval : gsBuild (m + 1) k = nextVec (m + 1) m (gsBuild m) := by rw [hk]; exact gsBuild_self m
        rw [hval]; exact nextVec_den (m + 1) m (gsBuild m) ihden idx
      · rw [gsBuild_ne m k hk]; exact ihden k idx
    · -- support on `[0,k]`
      intro k hk idx hidx
      by_cases hkm : k = m
      · have hval : gsBuild (m + 1) k = nextVec (m + 1) m (gsBuild m) := by rw [hkm]; exact gsBuild_self m
        rw [hval]; exact nextVec_support (m + 1) m (gsBuild m) ihsupp idx (by omega)
      · rw [gsBuild_ne m k hkm]; exact ihsupp k (by omega) idx hidx
    · -- monic at `k`
      intro k hk
      by_cases hkm : k = m
      · have hval : gsBuild (m + 1) k = nextVec (m + 1) m (gsBuild m) := by rw [hkm]; exact gsBuild_self m
        rw [hval, hkm]; exact nextVec_monic (m + 1) m (gsBuild m) ihden ihsupp
      · rw [gsBuild_ne m k hkm]; exact ihmonic k (by omega)
    · -- dimension-uniform mutual orthogonality
      intro i j hi hj hij d hid hjd
      by_cases him : i = m
      · -- `i = m`, `j < m`: orthogonality at `m+1` then flip + extend dimension
        subst him
        have hjm : j < i := by omega
        rw [gsBuild_self i, gsBuild_ne i j (Ne.symm hij)]
        have hposj : 0 < (qHil (gsBuild i j) (gsBuild i j) (i + 1)).num :=
          num_pos_of_Qlt_zero (qHil_self_pos (gsBuild i j) (ihden j) (i + 1) ⟨j, by omega, ihmonic j hjm⟩)
        have horth : Qeq (qHil (gsBuild i j) (nextVec (i + 1) i (gsBuild i)) (i + 1)) (⟨0, 1⟩ : Q) :=
          nextVec_ortho (i + 1) i j (gsBuild i) ihden hqorthMp1 hjm hposj
        refine Qeq_trans (qHil_den_pos (gsBuild i j) (nextVec (i + 1) i (gsBuild i)) (ihden j)
            (nextVec_den (i + 1) i (gsBuild i) ihden) d)
          (qHil_comm (nextVec (i + 1) i (gsBuild i)) (gsBuild i j)
            (nextVec_den (i + 1) i (gsBuild i) ihden) (ihden j) d) ?_
        refine Qeq_trans (qHil_den_pos (gsBuild i j) (nextVec (i + 1) i (gsBuild i)) (ihden j)
            (nextVec_den (i + 1) i (gsBuild i) ihden) (i + 1))
          (qHil_trunc_eq (gsBuild i j) (nextVec (i + 1) i (gsBuild i)) (ihden j)
            (nextVec_den (i + 1) i (gsBuild i) ihden) (i + 1)
            (fun idx hidx => ihsupp j hjm idx (by omega))
            (fun idx hidx => nextVec_support (i + 1) i (gsBuild i) ihsupp idx (by omega))
            d (i + 1) (by omega) (Nat.le_refl (i + 1)))
          horth
      · by_cases hjm : j = m
        · -- `j = m`, `i < m`: `nextVec_ortho` directly (new vector second), then extend dimension
          subst hjm
          have hilt : i < j := by omega
          rw [gsBuild_ne j i him, gsBuild_self j]
          have hposi : 0 < (qHil (gsBuild j i) (gsBuild j i) (j + 1)).num :=
            num_pos_of_Qlt_zero (qHil_self_pos (gsBuild j i) (ihden i) (j + 1) ⟨i, by omega, ihmonic i hilt⟩)
          have horth : Qeq (qHil (gsBuild j i) (nextVec (j + 1) j (gsBuild j)) (j + 1)) (⟨0, 1⟩ : Q) :=
            nextVec_ortho (j + 1) j i (gsBuild j) ihden hqorthMp1 hilt hposi
          exact Qeq_trans (qHil_den_pos (gsBuild j i) (nextVec (j + 1) j (gsBuild j)) (ihden i)
              (nextVec_den (j + 1) j (gsBuild j) ihden) (j + 1))
            (qHil_trunc_eq (gsBuild j i) (nextVec (j + 1) j (gsBuild j)) (ihden i)
              (nextVec_den (j + 1) j (gsBuild j) ihden) (j + 1)
              (fun idx hidx => ihsupp i hilt idx (by omega))
              (fun idx hidx => nextVec_support (j + 1) j (gsBuild j) ihsupp idx (by omega))
              d (j + 1) (by omega) (Nat.le_refl (j + 1)))
            horth
        · -- both `< m`: the induction hypothesis
          rw [gsBuild_ne m i him, gsBuild_ne m j hjm]
          exact ihorth i j (by omega) (by omega) hij d hid hjd

-- ===========================================================================
-- ★ The fixed family's invariants (the public, dimension-free interface).
-- ===========================================================================

/-- **★ Denominators**: every coefficient of every `gsFam` vector is a valid rational. -/
theorem gsFam_den (k idx : Nat) : 0 < (gsFam k idx).den :=
  (gsBuild_props (k + 1)).1 k idx

/-- **★ Support**: `gsFam k` vanishes strictly above index `k` (leading degree `k`). -/
theorem gsFam_support (k idx : Nat) (h : k < idx) : Qeq (gsFam k idx) (⟨0, 1⟩ : Q) :=
  (gsBuild_props (k + 1)).2.1 k (Nat.lt_succ_self k) idx h

/-- **★ Monic**: `gsFam k` has leading coefficient `≉ 0` at index `k`. -/
theorem gsFam_monic (k : Nat) : ¬ Qeq (gsFam k k) (⟨0, 1⟩ : Q) :=
  (gsBuild_props (k + 1)).2.2.1 k (Nat.lt_succ_self k)

/-- **★ DIMENSION-UNIFORM ORTHOGONALITY**: distinct fixed family vectors are orthogonal in the rational
    Hilbert form at *every* dimension larger than both indices. -/
theorem gsFam_ortho (i j : Nat) (hij : i ≠ j) (d : Nat) (hi : i < d) (hj : j < d) :
    Qeq (qHil (gsFam i) (gsFam j) d) (⟨0, 1⟩ : Q) := by
  have hiM : i < i + j + 1 := by omega
  have hjM : j < i + j + 1 := by omega
  rw [← gsBuild_lt (i + j + 1) i hiM, ← gsBuild_lt (i + j + 1) j hjM]
  exact (gsBuild_props (i + j + 1)).2.2.2 i j hiM hjM hij d hi hj

end Multiplicity.UOR.Bridge.F1Square.Square
