/-
F1 square — infrastructure: **a `log π` LOWER bound** (`log π ≥ 1`).

The repo had only UPPER bounds on logs (built for the λ-coefficient proofs: `Rlogπc_le`,
`Rlog2c`, …). The archimedean-kernel sign work needs the complement — a positive lower bound on
`log π`. This supplies `Rlogpi_ge_one : log π ≥ 1`, resting on the sharp `Rpi_lower_three : π ≥ 3`.

The chain, all elementary once `π ≥ 3` is in hand:
- `RpiTmap_ge_half` — `(π−1)/(π+1) ≥ 1/2` at every approximant, since each `Rpi` approximant is
  `≥ 3` (`Rpi_seq_ge_three`) and `tmap` is monotone with `tmap(3) = 1/2` (`tmap_ge_half`).
- `Rartanh_RpiTmap_ge_half` — `artanh((π−1)/(π+1)) ≥ 1/2`, since `artanh` dominates its first series
  term (`artSum_ge_arg`) and that term is `(π−1)/(π+1) ≥ 1/2`.
- `Rlogpi_ge_one` — `log π = 2·artanh((π−1)/(π+1)) ≥ 2·(1/2) = 1`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.PsiQuarter

namespace UOR.Bridge.F1Square.Analysis

/-- **`(π−1)/(π+1) ≥ 1/2` at every approximant** — each `Rpi` approximant is `≥ 3`
    (`Rpi_seq_ge_three`) and `tmap` is monotone with `tmap(3) = 1/2` (`tmap_ge_half`). -/
theorem RpiTmap_ge_half (n : Nat) : Qle (⟨1, 2⟩ : Q) (RpiTmap.seq n) :=
  tmap_ge_half (Rpi_seq_den_pos (Rlog_R n)) (Rpi_seq_ge_three (Rlog_R n))

/-- **`artanh((π−1)/(π+1)) ≥ 1/2`** — `artanh` dominates its first series term (`artSum_ge_arg`),
    and that term is `(π−1)/(π+1) ≥ 1/2` (`RpiTmap_ge_half`). -/
theorem Rartanh_RpiTmap_ge_half :
    Rle (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rartanh RpiTmap ⟨15, 29⟩ (by decide) (by decide) (by decide) RpiTmap_abs_le) := by
  intro m
  show Qle (⟨1, 2⟩ : Q)
    (add (artSum (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) (Rartanh_R ⟨15, 29⟩ m)) ⟨2, m + 1⟩)
  have h1 : Qle (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m))
      (artSum (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) (Rartanh_R ⟨15, 29⟩ m)) :=
    artSum_ge_arg (RpiTmap_nonneg _) (RpiTmap.den_pos _) _
  have h2 : Qle (⟨1, 2⟩ : Q) (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) := RpiTmap_ge_half _
  exact Qle_trans (RpiTmap.den_pos _) h2
    (Qle_trans (artSum_den_pos (RpiTmap.den_pos _) _) h1
      (Qle_self_add (by show (0 : Int) ≤ 2; decide)))

/-- **`log π ≥ 1`** — `log π = 2·artanh((π−1)/(π+1)) ≥ 2·(1/2) = 1`. The lower companion of
    `Rlogπc_le` (`log π ≤ 1.1453`), and the first positive lower bound on a log in the substrate. -/
theorem Rlogpi_ge_one : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) Rlogπc := by
  have hstep : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rartanh RpiTmap ⟨15, 29⟩ (by decide) (by decide) (by decide) RpiTmap_abs_le)) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rartanh_RpiTmap_ge_half
  refine Rle_trans ?_ hstep
  refine Rle_of_Req (Req_symm (Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) ?_))
  exact ofQ_congr (by decide) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
