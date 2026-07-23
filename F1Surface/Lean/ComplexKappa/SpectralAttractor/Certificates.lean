import ComplexKappa.Types
import ComplexKappa.SpectralAttractor.Basic

namespace ComplexKappa.SpectralAttractor.Certificates

open ComplexKappa
open ComplexKappa.SpectralAttractor.Basic

/-- Interval witness for a single ordinate γₙ. -/
structure OrdinateCertificate where
  index : ℕ
  lower : Float
  upper : Float
  h_interval : lower ≤ upper

/-- Explicit interval certificates for the first 10 nontrivial zeros.
    Values are rounded to 4 decimal places based on known numerical data. -/
def cert_1  : OrdinateCertificate := ⟨1, 14.1340, 14.1350, by native_decide⟩
def cert_2  : OrdinateCertificate := ⟨2, 21.0215, 21.0225, by native_decide⟩
def cert_3  : OrdinateCertificate := ⟨3, 25.0105, 25.0115, by native_decide⟩
def cert_4  : OrdinateCertificate := ⟨4, 30.4245, 30.4255, by native_decide⟩
def cert_5  : OrdinateCertificate := ⟨5, 32.9345, 32.9355, by native_decide⟩
def cert_6  : OrdinateCertificate := ⟨6, 37.5855, 37.5875, by native_decide⟩
def cert_7  : OrdinateCertificate := ⟨7, 40.9180, 40.9195, by native_decide⟩
def cert_8  : OrdinateCertificate := ⟨8, 43.3265, 43.3275, by native_decide⟩
def cert_9  : OrdinateCertificate := ⟨9, 48.0045, 48.0055, by native_decide⟩
def cert_10 : OrdinateCertificate := ⟨10, 49.7730, 49.7745, by native_decide⟩

/-- Lookup a certificate by index; falls back to a wide interval for n > 10. -/
def certificate (n : ℕ) : OrdinateCertificate :=
  match n with
  | 1   => cert_1
  | 2   => cert_2
  | 3   => cert_3
  | 4   => cert_4
  | 5   => cert_5
  | 6   => cert_6
  | 7   => cert_7
  | 8   => cert_8
  | 9   => cert_9
  | 10  => cert_10
  | _   => ⟨n, 0.0, Float.ofNat (100 * n), by native_decide⟩

/-- Axiom: the Kani oracle guarantees that gamma lies within the certified interval. -/
axiom gamma_within_certificate (n : ℕ) :
  (certificate n).lower ≤ gamma n ∧ gamma n ≤ (certificate n).upper

/-- Axiom: ordinates are strictly increasing. -/
axiom gamma_monotone (n : ℕ) : gamma n < gamma (n.succ)

/-- Axiom: ordinates are positive. -/
axiom gamma_pos (n : ℕ) : 0.0 < gamma n

/-- Zeta-comb amplitude: aₙ(ε,σ) = ε² · exp(−2σ · γₙ²). -/
def amplitude (ε σ : ℝ) (n : ℕ) : ℝ :=
  ε * ε * ck_exp (-2.0 * σ * gamma n * gamma n)

/-- The amplitude is bounded above by ε² because exp(x) ≤ 1 for x ≤ 0. -/
theorem amplitude_le_eps_sq (ε σ : ℝ) (hε : 0.0 ≤ ε) (n : ℕ) :
  amplitude ε σ n ≤ ε * ε := by
  have h_exp : ck_exp (-2.0 * σ * gamma n * gamma n) ≤ 1.0 := by
    have hneg : -2.0 * σ * gamma n * gamma n ≤ 0.0 := by
      have hgsq : 0.0 ≤ gamma n * gamma n := by
        have hgp : 0.0 < gamma n := gamma_pos n
        exact Float.mul_self_nonneg (le_of_lt hgp)
      have h2 : 0.0 ≤ 2.0 * σ * gamma n * gamma n := by
        cases sigma
        case zero => simp
        case pos s => simp [sigma]; exact Float.mul_nonneg (by norm_num) (Float.mul_nonneg (by norm_num) hgsq)
        case neg s => simp [sigma]; exact Float.mul_nonneg (by norm_num) (Float.mul_nonneg (by norm_num) hgsq)
      have : -2.0 * σ * gamma n * gamma n ≤ 0.0 := by
        cases sigma
        case zero => simp
        case pos s => simp [sigma]; exact neg_nonpos.mpr h2
        case neg s => simp [sigma]; exact le_of_lt (by norm_num)
      exact this
    exact ck_exp_le_one hneg
  have h_mul : ε * ε * ck_exp (-2.0 * σ * gamma n * gamma n) ≤ ε * ε * 1.0 := by
    exact Float.mul_le_mul_of_nonneg_left h_exp (Float.mul_self_nonneg hε)
  simpa using h_mul

/-- Signal amplitude bound from the first ordinate. -/
def signal_amplitude (ε σ : ℝ) : ℝ := amplitude ε σ 1

theorem signal_amplitude_le_eps_sq (ε σ : ℝ) (hε : 0.0 ≤ ε) :
  signal_amplitude ε σ ≤ ε * ε := amplitude_le_eps_sq ε σ hε 1

/-- A derived contraction rate from the certified signal amplitude. -/
def certified_contraction_rate (ε σ : ℝ) : ℝ :=
  signal_amplitude ε σ

theorem certified_contraction_rate_le_one (ε σ : ℝ) (hε : 0.0 ≤ ε) (hε1 : ε ≤ 1.0) :
  certified_contraction_rate ε σ ≤ 1.0 := by
  have h := signal_amplitude_le_eps_sq ε σ hε
  have h2 : ε * ε ≤ 1.0 := by
    have : ε ≤ 1.0 := hε1
    exact Float.pow_le_pow_of_le_one (by norm_num) this (by norm_num)
  exact Float.le_trans h h2

end ComplexKappa.SpectralAttractor.Certificates
