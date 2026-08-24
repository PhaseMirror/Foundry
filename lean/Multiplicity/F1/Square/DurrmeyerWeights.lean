/-
F1 square — **the Durrmeyer integrals of the monomials** (`DurrmeyerWeights.lean`), the Mellin-inversion
arc, sub-brick J₃. Evaluating `⟨xʲ, b_{n,k}⟩ = ∫₀¹ tʲ·b_{n,k}(t) dt` in closed form for `j = 0,1,2` — the
per-`k` weights the Durrmeyer moment sums (and hence the second-moment/convergence estimate) consume. From
J₁ the integral is `C(n,k)·momDiff (powTest j) k (n−k)`, and J₂ evaluates the finite difference, giving (for
`k ≤ n`)

    `⟨xʲ, b_{n,k}⟩ = C(n,k)·(n−k)!·(k+j)! / (n+j+1)!`   (`durrInt_raw`),

which the factorial identity `C(n,k)·k!·(n−k)! = n!` collapses to

    `⟨1,  b_{n,k}⟩ = n!/(n+1)!`                (`durrInt_zero`),
    `⟨x,  b_{n,k}⟩ = (k+1)·n!/(n+2)!`         (`durrInt_one`),
    `⟨x², b_{n,k}⟩ = (k+1)(k+2)·n!/(n+3)!`    (`durrInt_two`).

WHY (the Sonine route, step 3, the Mellin FRONT). Summed against `(n+1)·b_{n,k}(x)` and the Bernstein moment
identities (`bernR_mean`, `bernR_sq`, partition of unity), these give the Durrmeyer moments `M_n⁽ʲ⁾(x)`, from
which the second central moment `T_n(x) = M_n⁽²⁾ − 2x·M_n⁽¹⁾ + x²` — the vanishing quantity that drives
`durrOp φ n x → φ(x)` — is assembled.

HONEST SCOPE. The closed-form monomial Durrmeyer integrals for `j = 0,1,2`, over `Real`. NOT the summed
moments, NOT the second-moment estimate, NOT convergence, NOT inversion, NOT positivity. Step 4 is RH; crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DurrmeyerMoments

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `≈` transports through `natScaleR` (local copy). -/
private theorem natScaleR_congr' {a b : Real} (hab : Req a b) :
    ∀ m, Req (natScaleR m a) (natScaleR m b)
  | 0 => Req_refl _
  | m + 1 => Radd_congr hab (natScaleR_congr' hab m)

/-- `m·(ofQ q) ≈ ofQ (m·q)` (local copy). -/
private theorem natScaleR_ofQ' (q : Q) (hq : 0 < q.den) :
    ∀ m, Req (natScaleR m (ofQ q hq))
        (ofQ (mul (⟨(m : Int), 1⟩ : Q) q) (Qmul_den_pos Nat.one_pos hq))
  | 0 => Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (mul (⟨(0 : Int), 1⟩ : Q) q)
      simp only [Qeq, mul]; push_cast; ring_uor)
  | m + 1 => by
    refine Req_trans (Radd_congr (Req_refl _) (natScaleR_ofQ' q hq m)) ?_
    refine Req_trans (Radd_ofQ_ofQ hq (Qmul_den_pos Nat.one_pos hq)) ?_
    refine Req_of_seq_Qeq (fun _ => ?_)
    show Qeq (add q (mul (⟨(m : Int), 1⟩ : Q) q)) (mul (⟨((m + 1 : Nat) : Int), 1⟩ : Q) q)
    simp only [Qeq, add, mul]; push_cast; ring_uor

-- Pure-ℤ collapse identities (the factorial denominator `F`/`D` rides as an opaque atom).
private theorem durrRaw_id (X D : Int) : X * D = X * (1 * D) := by ring_uor
private theorem durrInt0f_id (c fk fnk fn F : Int) (h : c * fk * fnk = fn) :
    (c * (fnk * fk)) * F = fn * F := by rw [← h]; ring_uor
private theorem durrInt1f_id (c fk fnk kk fn F : Int) (h : c * fk * fnk = fn) :
    (c * (fnk * ((kk + 1) * fk))) * F = ((kk + 1) * fn) * F := by rw [← h]; ring_uor
private theorem durrInt2f_id (c fk fnk kk fn F : Int) (h : c * fk * fnk = fn) :
    (c * (fnk * ((kk + 2) * ((kk + 1) * fk)))) * F = ((kk + 1) * (kk + 2) * fn) * F := by
  rw [← h]; ring_uor

/-- **The raw monomial Durrmeyer integral**: `⟨xʲ, b_{n,k}⟩ = C(n,k)·(n−k)!·(k+j)! / (n+j+1)!` for
    `k ≤ n`. J₁ gives `C(n,k)·momDiff (powTest j) k (n−k)`; J₂ evaluates the finite difference and the index
    `k+j+(n−k)+1 = n+j+1` closes. -/
theorem durrInt_raw (n k j : Nat) (hkn : k ≤ n) :
    Req (innerI (powTest j) (bernBasisTest n k))
        (ofQ (⟨(choose n k : Int) * ((fct (n - k) * fct (k + j) : Nat) : Int),
              fct (n + j + 1)⟩ : Q) (fct_pos _)) := by
  refine Req_trans (innerI_bernBasis_eq_momDiff (powTest j) n k) ?_
  refine Req_trans (natScaleR_congr' (momDiff_powTest j (n - k) k) (choose n k)) ?_
  refine Req_trans (natScaleR_ofQ' _ (fct_pos _) (choose n k)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (fct_pos _)) (fct_pos _) ?_
  have hidx : k + j + (n - k) + 1 = n + j + 1 := by omega
  simp only [Qeq, mul]
  rw [hidx]
  push_cast
  exact durrRaw_id _ _

/-- **`⟨1, b_{n,k}⟩ = n!/(n+1)!`** (`= 1/(n+1)`) — the normalization weight (`j = 0`). -/
theorem durrInt_zero (n k : Nat) (hkn : k ≤ n) :
    Req (innerI (powTest 0) (bernBasisTest n k))
        (ofQ (⟨((fct n : Nat) : Int), fct (n + 1)⟩ : Q) (fct_pos _)) := by
  refine Req_trans (durrInt_raw n k 0 hkn) (ofQ_congr (fct_pos _) (fct_pos _) ?_)
  have hcmZ : (choose n k : Int) * (fct k : Nat) * (fct (n - k) : Nat) = (fct n : Nat) := by
    exact_mod_cast choose_mul_fct_mul_fct hkn
  simp only [Qeq]
  push_cast at hcmZ ⊢
  exact durrInt0f_id _ _ _ _ _ hcmZ

/-- **`⟨x, b_{n,k}⟩ = (k+1)·n!/(n+2)!`** (`= (k+1)/((n+1)(n+2))`) — the first-moment weight (`j = 1`). -/
theorem durrInt_one (n k : Nat) (hkn : k ≤ n) :
    Req (innerI (powTest 1) (bernBasisTest n k))
        (ofQ (⟨(((k + 1) * fct n : Nat) : Int), fct (n + 2)⟩ : Q) (fct_pos _)) := by
  refine Req_trans (durrInt_raw n k 1 hkn) (ofQ_congr (fct_pos _) (fct_pos _) ?_)
  have hcmZ : (choose n k : Int) * (fct k : Nat) * (fct (n - k) : Nat) = (fct n : Nat) := by
    exact_mod_cast choose_mul_fct_mul_fct hkn
  have hfk1 : fct (k + 1) = (k + 1) * fct k := fct_succ k
  simp only [Qeq]
  rw [hfk1]
  push_cast at hcmZ ⊢
  exact durrInt1f_id _ _ _ _ _ _ hcmZ

/-- **`⟨x², b_{n,k}⟩ = (k+1)(k+2)·n!/(n+3)!`** (`= (k+1)(k+2)/((n+1)(n+2)(n+3))`) — the second-moment
    weight (`j = 2`). -/
theorem durrInt_two (n k : Nat) (hkn : k ≤ n) :
    Req (innerI (powTest 2) (bernBasisTest n k))
        (ofQ (⟨(((k + 1) * (k + 2) * fct n : Nat) : Int), fct (n + 3)⟩ : Q) (fct_pos _)) := by
  refine Req_trans (durrInt_raw n k 2 hkn) (ofQ_congr (fct_pos _) (fct_pos _) ?_)
  have hcmZ : (choose n k : Int) * (fct k : Nat) * (fct (n - k) : Nat) = (fct n : Nat) := by
    exact_mod_cast choose_mul_fct_mul_fct hkn
  have hfk2 : fct (k + 2) = (k + 2) * ((k + 1) * fct k) := by
    have h1 : fct (k + 2) = (k + 2) * fct (k + 1) := fct_succ (k + 1)
    rw [h1, fct_succ k]
  simp only [Qeq]
  rw [hfk2]
  push_cast at hcmZ ⊢
  exact durrInt2f_id _ _ _ _ _ _ hcmZ

end Multiplicity.UOR.Bridge.F1Square.Square
