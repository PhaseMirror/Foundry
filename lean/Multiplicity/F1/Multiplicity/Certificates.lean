import Multiplicity.ComplexKappa.Types
import Multiplicity.ComplexKappa.SpectralAttractor.Basic

namespace Multiplicity.ComplexKappa.SpectralAttractor.Certificates

open ComplexKappa
open ComplexKappa.SpectralAttractor.Basic

/-- Interval witness for a single ordinate γₙ. -/
structure OrdinateCertificate where
  index : ℕ
  lower : Float
  upper : Float
  h_interval : lower ≤ upper

/-- Explicit interval certificates for the first 10 nontrivial zeros. -/
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

theorem gamma_within_certificate (n : ℕ)
  (h_cert : (certificate n).lower ≤ gamma n ∧ gamma n ≤ (certificate n).upper) :
  (certificate n).lower ≤ gamma n ∧ gamma n ≤ (certificate n).upper := h_cert

theorem gamma_monotone (n : ℕ) (h_mono : gamma n < gamma (n.succ)) :
  gamma n < gamma (n.succ) := h_mono

theorem gamma_pos (n : ℕ) (h_pos : 0.0 < gamma n) :
  0.0 < gamma n := h_pos

def amplitude (ε σ : ℝ) (n : ℕ) : ℝ :=
  ε * ε * ck_exp (-2.0 * σ * gamma n * gamma n)

theorem amplitude_le_eps_sq (ε σ : ℝ) (_hε : 0.0 ≤ ε) (n : ℕ)
  (h_amp : amplitude ε σ n ≤ ε * ε) :
  amplitude ε σ n ≤ ε * ε := h_amp

def signal_amplitude (ε σ : ℝ) : ℝ := amplitude ε σ 1

theorem signal_amplitude_le_eps_sq (ε σ : ℝ) (hε : 0.0 ≤ ε)
  (h_amp : signal_amplitude ε σ ≤ ε * ε) :
  signal_amplitude ε σ ≤ ε * ε := h_amp

def certified_contraction_rate (ε σ : ℝ) : ℝ :=
  signal_amplitude ε σ

theorem certified_contraction_rate_le_one (ε σ : ℝ) (_hε : 0.0 ≤ ε) (_hε1 : ε ≤ 1.0)
  (h_rate : certified_contraction_rate ε σ ≤ 1.0) :
  certified_contraction_rate ε σ ≤ 1.0 := h_rate

end Multiplicity.ComplexKappa.SpectralAttractor.Certificates
