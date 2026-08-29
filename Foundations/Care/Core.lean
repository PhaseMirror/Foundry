/-!
# Foundations.Care.Core — Multiplicity Care Physics & Socio-Atomic Patient–Nurse Bond

Formalization of the patient–nurse relationship `M_pn = 1 + 2·γ_pn·c_pn`
over **exact fixed-point arithmetic** (scale `N = 1024`).
Discharged entirely by core `Nat` order lemmas, `omega`, and `decide`.
-/

namespace Foundations.Care

/-! ## Fixed-point scale -/

/-- Fixed-point scale: rational `q ∈ [0,1]` is represented by `⌊N·q⌋`. -/
abbrev Scale : Nat := 1024

/-- The scale is positive. -/
theorem scale_pos : 0 < Scale := by decide

/-! ## Quantized exponential attenuation -/

/-- `⌊N · e^{-d}⌋` for `d ≤ 6`; zero beyond the coupling horizon (`d ≥ 7`). -/
def decay : Nat → Nat
  | 0 => 1024 | 1 => 376 | 2 => 138 | 3 => 50
  | 4 => 18 | 5 => 6 | 6 => 2 | _ => 0

/-- Attenuation at zero distance is unity. -/
theorem decay_zero : decay 0 = Scale := rfl

/-- The attenuation factor is normalized: `decay d ≤ N` for every distance. -/
theorem decay_le_scale : ∀ d, decay d ≤ Scale := by
  intro d
  match d with
  | 0 | 1 | 2 | 3 | 4 | 5 | 6 => decide
  | n + 7 => simp [decay] <;> omega

/-! ## Normalized prime-weighted coupling -/

/-- Index separation `|p − n|`; truncated subtraction keeps it `omega`-friendly. -/
def sep (p n : Nat) : Nat := p - n + (n - p)

/-- Normalized prime coupling
`γ̂(p,n) = ⌊N·(min/max)·e^(-|p−n|)⌋ ∈ [0,N]`, maximal when `p = n`.
Encoded via `min p n = p - (p-n)` and `max p n = n + (p-n)`. -/
def gamma (p n : Nat) : Nat :=
  ((p - (p - n)) * Scale / (n + (p - n)) * decay (sep p n)) / Scale

/-- Coupling is normalized: `γ̂(p,n) ≤ N`. -/
theorem gamma_le_scale (p n : Nat) : gamma p n ≤ Scale := by
  have hminmax : p - (p - n) ≤ n + (p - n) := by omega
  have hratio : (p - (p - n)) * Scale / (n + (p - n)) ≤ Scale :=
    Nat.div_le_of_le_mul (Nat.mul_le_mul_right Scale hminmax)
  exact Nat.div_le_of_le_mul <|
    Nat.mul_le_mul hratio (decay_le_scale _)

/-! ## Trust, affinity, multiplicity -/

/-- Overlap coefficient `⟨ψ_p|ψ_n⟩`, modeled as a trust score in `[0, N]`. -/
def Trust := {c : Nat // c ≤ Scale}

/-- Affinity `κ̂ = ⌊γ̂·c / N⌋ ∈ [0, N]`. -/
def affinity (g : Nat) (c : Trust) : Nat := g * c.val / Scale

/-- Socio-atomic multiplicity of the patient–nurse bond:
`M̂ = N + 2·κ̂`, the fixed-point image of `M = 1 + 2·γ·c ∈ [1, 3]`. -/
def multiplicityPN (g : Nat) (c : Trust) : Nat := Scale + 2 * affinity g c

/-- Range theorem: For any normalized coupling and any trust level, the
bond multiplicity lies in `[N, 3N]`, i.e. `M ∈ [1, 3]`. -/
theorem multiplicity_bounded (g : Nat) (hg : g ≤ Scale) (c : Trust) :
    Scale ≤ multiplicityPN g c ∧ multiplicityPN g c ≤ 3 * Scale := by
  have hk : affinity g c ≤ Scale := by
    unfold affinity
    exact Nat.div_le_of_le_mul (Nat.mul_le_mul hg c.property)
  constructor
  · show Scale ≤ Scale + 2 * affinity g c
    omega
  · show Scale + 2 * affinity g c ≤ 3 * Scale
    omega

/-- Affinity stays within the fixed-point scale. -/
theorem affinity_le_scale (g : Nat) (hg : g ≤ Scale) (c : Trust) :
    affinity g c ≤ Scale :=
  Nat.div_le_of_le_mul (Nat.mul_le_mul hg c.property)

/-- Monotonicity: Deeper trust never weakens the bond. -/
theorem multiplicity_mono (g : Nat) (c₁ c₂ : Trust) (hle : c₁.val ≤ c₂.val) :
    affinity g c₁ ≤ affinity g c₂ :=
  Nat.div_le_div_right (Nat.mul_le_mul_left g hle)

/-- Zero-trust anchor: Absent reciprocity, the bond sits exactly at baseline `M = 1`. -/
theorem multiplicity_zero_trust (g : Nat) :
    multiplicityPN g ⟨0, Nat.zero_le _⟩ = Scale := by
  have hv : (⟨0, Nat.zero_le _⟩ : Trust).val = 0 := rfl
  unfold multiplicityPN affinity
  rw [hv, Nat.mul_zero, Nat.zero_div]

/-- Perfect-bond anchor: Full trust across perfectly coupled indices yields `M = 3`. -/
theorem multiplicity_perfect :
    multiplicityPN Scale ⟨Scale, Nat.le_refl Scale⟩ = 3 * Scale := by
  show 1024 + 2 * (1024 * 1024 / 1024) = 3 * 1024
  decide

/-! ## Interpretation bands -/

/-- The three care-delivery regimes of the interpretation table. -/
inductive Reciprocity where
  | transactional
  | engaged
  | resonant
  deriving DecidableEq, Repr

/-- Band classifier over affinity `κ̂`. -/
def classifyBand (k : Nat) : Reciprocity :=
  if 2 * k < Scale then .transactional
  else if 2 * k < 2 * Scale then .engaged
  else .resonant

/-- Classification of a bond from its coupling and trust level. -/
def classifyBond (g : Nat) (c : Trust) : Reciprocity := classifyBand (affinity g c)

/-- Exhaustiveness of regime classification. -/
theorem classifyBand_cases (k : Nat) :
    (classifyBand k = .transactional ∧ 2 * k < Scale)
    ∨ (classifyBand k = .engaged ∧ Scale ≤ 2 * k ∧ 2 * k < 2 * Scale)
    ∨ (classifyBand k = .resonant ∧ 2 * Scale ≤ 2 * k) := by
  unfold classifyBand
  by_cases h1 : 2 * k < Scale
  · rw [if_pos h1]
    exact Or.inl ⟨rfl, h1⟩
  · rw [if_neg h1]
    by_cases h2 : 2 * k < 2 * Scale
    · rw [if_pos h2]
      refine Or.inr (Or.inl ⟨rfl, ?_, h2⟩)
      omega
    · rw [if_neg h2]
      refine Or.inr (Or.inr ⟨rfl, ?_⟩)
      omega

/-- Disjointness of regime classification. -/
theorem classify_disjoint (k : Nat) :
    ¬ (classifyBand k = .transactional ∧ classifyBand k = .engaged)
    ∧ ¬ (classifyBand k = .engaged ∧ classifyBand k = .resonant)
    ∧ ¬ (classifyBand k = .transactional ∧ classifyBand k = .resonant) :=
  ⟨fun h => Reciprocity.noConfusion ((Eq.symm h.1).trans h.2),
   ⟨fun h => Reciprocity.noConfusion ((Eq.symm h.1).trans h.2),
    fun h => Reciprocity.noConfusion ((Eq.symm h.1).trans h.2)⟩⟩

/-! ## Un-normalized specification defect check -/

def rawGamma (p n : Nat) : Nat := p * n * decay (sep p n)

def rawMultiplicity (p n : Nat) (c : Trust) : Nat :=
  Scale + 2 * (rawGamma p n * c.val / Scale)

theorem raw_two_two_full :
    rawMultiplicity 2 2 ⟨Scale, Nat.le_refl Scale⟩ = 9 * Scale := by
  unfold rawMultiplicity rawGamma sep
  rfl

theorem raw_spec_violation :
    ∃ p n c, c.val ≤ Scale ∧ 3 * Scale < rawMultiplicity p n c :=
  ⟨2, 2, ⟨Scale, Nat.le_refl Scale⟩,
   Nat.le_refl Scale,
   by rw [raw_two_two_full]; decide⟩

end Foundations.Care
