/-
F1 square — **the `∫ log` layer, part 2c(iii): the point values** (`LogPointVal.lean`).
The dyadic samples of the totalized integrand collapse to `logN` differences:

    `gLog c (j/(N+1)) ≈ logN (c(N+1)+j) − logN (N+1)`      (`1 ≤ c ≤ 3`, `j ≤ N+1`)

— general in the sample, one theorem for every fold of every Riemann sum of
`∫₀¹ log(c+t) dt`. Assembly: the constant-real sum `c + j/(N+1) ≈ (c(N+1)+j)/(N+1)`
sits inside the band `[1, c+1]`, so the clamp is inert (`qBandQ_eq_of_band`); the
`RlogPos` congruence at the presented modulus `B = c+1` (small-radius certificate
`radius_half_proj (c+1) 1`, needing exactly `c ≤ 3`) moves the integrand to
`RlogPos (ofQ ((c(N+1)+j)/(N+1)))`; and the part 2c(ii) bridge (`RlogPos_ofQ_eq_logN`,
on the band `N+1 ≤ c(N+1)+j ≤ 4(N+1)` — again exactly `c ≤ 3`, `j ≤ N+1`) lands the
`logN` difference the `LogStep` telescopes speak.

HONEST SCOPE. Point evaluations of a constructed integrand; no integral is evaluated
and no positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogIntegrand
import Core.F1.Analysis.LogRatBridge

namespace UOR.Bridge.F1Square.Analysis

/-- `1 ≤ s·B` from `1 ≤ s`, `1 ≤ B` (private copy; the `LogIntegrand` original is
    private). -/
private theorem pv_one_le_mul {s B : Q} (hs : Qle (⟨1, 1⟩ : Q) s) (hB : Qle (⟨1, 1⟩ : Q) B) :
    Qle (⟨1, 1⟩ : Q) (mul s B) := by
  show (1 : Int) * ((s.den * B.den : Nat) : Int) ≤ s.num * B.num * 1
  simp only [Qle] at hs hB
  push_cast at hs hB ⊢
  have hsd : (0 : Int) ≤ (s.den : Int) := Int.ofNat_nonneg _
  have hsn : (0 : Int) ≤ s.num := by omega
  have h1 : (s.den : Int) * (B.den : Int) ≤ s.num * (B.den : Int) :=
    Int.mul_le_mul_of_nonneg_right (by omega) (Int.ofNat_nonneg _)
  have h2 : s.num * (B.den : Int) ≤ s.num * B.num :=
    Int.mul_le_mul_of_nonneg_left (by omega) hsn
  omega

/-- The rational collapse `c + j/(N+1) = (c(N+1)+j)/(N+1)`. -/
private theorem pv_add_collapse (c j N : Nat) :
    Qeq (add (⟨(c : Int), 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q))
      (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) := by
  simp only [Qeq, add]
  push_cast
  ring_uor

/-- The sample clears the band ceiling: `(c(N+1)+j)/(N+1) ≤ c+1` from `j ≤ N+1`. -/
private theorem pv_sample_le (c j N : Nat) (hj : j ≤ N + 1) :
    Qle (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) := by
  have hNat : c * (N + 1) + j ≤ (c + 1) * (N + 1) := by
    have hsm : (c + 1) * (N + 1) = c * (N + 1) + (N + 1) := Nat.succ_mul c (N + 1)
    omega
  simp only [Qle]
  have hInt : ((c * (N + 1) + j : Nat) : Int) ≤ (((c + 1) * (N + 1) : Nat) : Int) :=
    Int.ofNat_le.mpr hNat
  push_cast at hInt ⊢
  omega

/-- **★ The point values**: for `1 ≤ c ≤ 3` and any dyadic sample `j/(N+1)` (`j ≤ N+1`),

        `gLog c (ofQ (j/(N+1))) ≈ logN (c(N+1)+j) − logN (N+1)`.

    General in the sample — every fold of every Riemann sum of `∫₀¹ log(c+t) dt` routes
    through this single theorem. The two `c ≤ 3` constraints (the presented-modulus
    certificate at `B = c+1` and the bridge band `a ≤ 4d`) are the same constraint,
    which is why the `gLog` instances stop at `c = 3`. -/
theorem gLog_point (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (j N : Nat) (hj : j ≤ N + 1)
    (ha1 : 1 ≤ c * (N + 1) + j) :
    Req (gLog c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (Rsub (logN (c * (N + 1) + j) ha1) (logN (N + 1) (Nat.succ_pos N))) := by
  have hda : N + 1 ≤ c * (N + 1) + j :=
    Nat.le_trans (Nat.le_mul_of_pos_left (N + 1) hc1) (Nat.le_add_right _ j)
  have ha4 : c * (N + 1) + j ≤ 4 * (N + 1) := by
    have h3 : c * (N + 1) ≤ 3 * (N + 1) := Nat.mul_le_mul_right (N + 1) hc3
    omega
  have hq1 : Qle (⟨1, 1⟩ : Q) (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) :=
    sample_ge_one (c * (N + 1) + j) (N + 1) hda
  have hqB : Qle (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) :=
    pv_sample_le c j N hj
  have hBge : Qle (⟨1, 1⟩ : Q) (⟨((c + 1 : Nat) : Int), 1⟩ : Q) :=
    sample_ge_one (c + 1) 1 (Nat.le_add_left 1 c)
  -- the constant-real sum collapses to the single sample
  have hsum : Req (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos)
        (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (Nat.succ_pos N)) :=
    Req_trans (Radd_ofQ_ofQ Nat.one_pos (Nat.succ_pos N))
      (ofQ_congr (add_den_pos Nat.one_pos (Nat.succ_pos N)) (Nat.succ_pos N)
        (pv_add_collapse c j N))
  -- the sample sits on the band, so the clamp is inert
  have hArg : Req (gLogArg c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (Nat.succ_pos N)) :=
    Req_trans
      (qBandQ_eq_of_band
        (Rle_trans (Rle_ofQ_ofQ Nat.one_pos (Nat.succ_pos N) hq1)
          (Rle_of_Req (Req_symm hsum)))
        (Rle_trans (Rle_of_Req hsum) (Rle_ofQ_ofQ (Nat.succ_pos N) Nat.one_pos hqB)))
      hsum
  -- the positivity witness on the collapsed sample
  have hy : Qlt (Qbound 1)
      ((ofQ (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (Nat.succ_pos N)).seq 1) :=
    ge1_pos_witness _ hq1
  -- move `RlogPos` across the collapse at the presented modulus `B = c+1`
  have hcongr : Req (gLog c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (RlogPos (ofQ (⟨((c * (N + 1) + j : Nat) : Int), N + 1⟩ : Q) (Nat.succ_pos N)) 1 hy) :=
    RlogPos_congr _ _ _ (gLogArg_witness c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N))) 1 hy
      (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos hBge
      (gLogArg_pos c _) (gLogArg_hi c _) (gLogArg_lo c _)
      (fun _ => by show (0 : Int) < ((c * (N + 1) + j : Nat) : Int); exact_mod_cast ha1)
      (fun _ => hqB) (fun _ => pv_one_le_mul hq1 hBge)
      (radius_half_proj (c + 1) 1 Nat.one_pos (Nat.le_add_left 1 c) (by omega))
      hArg
  -- land on the `logN` difference through the part 2c(ii) bridge
  exact Req_trans hcongr
    (RlogPos_ofQ_eq_logN (c * (N + 1) + j) (N + 1) (Nat.succ_pos N) hda ha4 1 hy)

end UOR.Bridge.F1Square.Analysis
