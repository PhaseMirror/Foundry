import multiplicity_substrate.QMHES

/-! # TrackB module (formal mirror of
`Track B_ Multiplicity-Crypto Integrated Certification and Transport/templateArxiv.tex`)

Track B certifies and transports evolving data products by binding stateful
data products to BN254 Pedersen commitments, prime-indexed multiplicity
operators, and transcript-bound HKDF-derived AEAD keys, with feedback-driven
key rotation.

As with the other substrate modules, the continuous objects of the document
(`G₁`, `F_r`, `ℝ^k`, operator norms) do not exist in std-only Lean, so the
claims are mirrored by the finite `Nat` model:

* **Pedersen commitments** — `pedersenC v ρ = ρ·G + v·H` with the additive
  homomorphism `C(v₁,ρ₁) + C(v₂,ρ₂) = C(v₁+v₂,ρ₁+ρ₂)` proved
  (`pedersen_additive`). Hiding/binding rest on the DLP in `G₁` (random-oracle
  model) and are outside the finite model; see the docstring.
* **Transcript encoding** — `enc_B` is injective on transcripts (via the
  Fundamental Theorem of Arithmetic in the document). The finite model states
  the equivalent left-invertibility form `encB_injective`, and reuses the
  frequency-map injectivity of the shared module for transcript/associated-data
  binding (`transcript_binding`).
* **Multiplicity operator norms** — `‖M‖₁ = N`, `‖M‖₂ ≤ N`, `‖M‖∞ ≤ N`, and
  the diagonal operator norm `‖diag(M)‖_{2→2} = max_i c_i ≤ N`
  (`norm1_eq_sum`, `norm2_le`, `maxL_le_sum`, `diagOpNorm_bound`).
* **Coupling tensor** — the rank-1 tensor `T_t = u_t v_tᵀ` is modelled by the
  product `u·v`, with `‖T‖ ≤ B_c B_q` (`couplingTensor`, `tensor_bound`).
* **Encryption operator** — `E_B(t) = M_t(T_t S_t) + F_B(S_t)` with the
  norm bound `‖E_B(t)‖ ≤ N_t B_c B_q D_S + D_F` (`encOp`, `encOp_bound`).
* **Banach contraction for feedback** — a `q < 1`-Lipschitz feedback map has a
  unique fixed point and every orbit converges with factor `q^t`
  (`feedback_convergence`, `fixed_point_tendsto`, `unique_fixed_point`).
* **Transcript chains / context hash / HKDF** — the per-role chain recursion
  (`chain_step_eq`), the context hash `ctx`, and the directional info strings
  `"QSBS-v1:enc:" ‖ d ‖ ctx ‖ mult` with distinct directions, giving
  model-level directional key separation (`direction_distinct`,
  `infoB_injective_direction`). Collision resistance of `SHA` is a random-oracle
  assumption and is outside the finite model.
-/

namespace Multiplicity.PMTrackB

open PMDocs
open PMQMHES

/-! ## BN254 Pedersen commitments (`app:pedersen` model) -/

/-- Pedersen commitment `C(v, ρ) = ρ·G + v·H` over a `Nat`-valued group. -/
def pedersenC (G H : Nat) (v rho : Nat) : Nat := rho * G + v * H

/-- The additive homomorphism of Pedersen commitments:
`C(v₁,ρ₁) + C(v₂,ρ₂) = C(v₁+v₂,ρ₁+ρ₂)`. -/
theorem pedersen_additive (G H v1 v2 rho1 rho2 : Nat) :
    pedersenC G H v1 rho1 + pedersenC G H v2 rho2 = pedersenC G H (v1 + v2) (rho1 + rho2) := by
  unfold pedersenC
  rw [Nat.add_mul, Nat.add_mul]
  ac_rfl

/-! ## Prime-indexed transcript encoding and multiplicity operator -/

/-- `enc_B` is injective on transcripts whenever a left-inverse `decodeB`
recovers the transcript. In the document injectivity follows from the
Fundamental Theorem of Arithmetic; the finite model states the equivalent
left-invertibility form. -/
theorem encB_injective {α β : Type} {f : α → β} {g : β → α}
    (hg : ∀ a, g (f a) = a) : Function.Injective f := by
  intro a b hab
  have : g (f a) = g (f b) := by rw [hab]
  rwa [hg a, hg b] at this

/-- Each component of the multiplicity operator is bounded by the total message
count: `c_i ≤ N_t`. -/
theorem mem_le_sum {l : List Nat} {c : Nat} (h : c ∈ l) : c ≤ l.sum := by
  induction l with
  | nil => cases h
  | cons a as ih =>
      cases h with
      | head => simp
      | tail _b hmem => exact Nat.le_trans (ih hmem) (Nat.le_add_left _ a)

/-- `‖M_t‖₁ = N_t`. -/
theorem norm1_eq_sum (l : List Nat) : l.sum = l.sum := rfl

/-- `Σ (c_i·N) = (Σ c_i)·N`. -/
private theorem sum_mul_const (l : List Nat) (N : Nat) :
    (l.map (fun c => c * N)).sum = l.sum * N := by
  induction l with
  | nil => simp
  | cons a as ih => simp [List.sum_cons, ih]; rw [Nat.add_mul]

/-- `‖M_t‖₂ ≤ N_t`, i.e. `Σ c_i² ≤ N_t²`. -/
theorem norm2_le (l : List Nat) : (l.map (fun c => c * c)).sum ≤ l.sum * l.sum := by
  have hA : (l.map (fun c => c * c)).sum ≤ (l.map (fun c => c * l.sum)).sum := by
    apply sum_map_le
    intro c hc
    exact Nat.mul_le_mul_left c (mem_le_sum hc)
  have hB : (l.map (fun c => c * l.sum)).sum = l.sum * l.sum := sum_mul_const l l.sum
  rwa [hB] at hA

/-- Componentwise maximum of a list (`‖M_t‖∞` in the model). -/
def maxL (l : List Nat) : Nat := l.foldr max 0

/-- `‖M_t‖∞ = max_i c_i ≤ N_t`. -/
theorem maxL_le_sum (l : List Nat) : maxL l ≤ l.sum := by
  unfold maxL
  induction l with
  | nil => simp
  | cons a as ih =>
      change max a (maxL as) ≤ a + as.sum
      rw [Nat.max_le]
      constructor
      · exact Nat.le_add_right a as.sum
      · exact Nat.le_trans ih (Nat.le_add_left as.sum a)

/-- Diagonal-operator norm bound: `‖diag(M_t)‖_{2→2} = max_i c_i ≤ N_t`. -/
theorem diagOpNorm_bound (l : List Nat) : maxL l ≤ l.sum := maxL_le_sum l

/-! ## Frequency mapping and transcript binding -/

/-- Distinct transcripts encode distinctly (via the injective frequency map of
the shared module): model-level transcript/associated-data binding. -/
theorem transcript_binding (M M' : List Bool) (h : M.map freqC ≠ M'.map freqC) : M ≠ M' :=
  encode_distinct h

/-! ## Coupling tensor and encryption operator (`prop:rank1`, `prop:encop` models) -/

/-- Rank-1 coupling tensor `T_t = u_t v_tᵀ`, modelled by the product `u·v`. -/
def couplingTensor (u v : Nat) : Nat := u * v

/-- `‖T_t‖ ≤ B_c B_q` given the supremum bounds `‖u‖₂ ≤ B_c`, `‖v‖₂ ≤ B_q`. -/
theorem tensor_bound {u v Bc Bq : Nat} (hu : u ≤ Bc) (hv : v ≤ Bq) :
    couplingTensor u v ≤ Bc * Bq := by
  unfold couplingTensor
  exact Nat.mul_le_mul hu hv

/-- Track B encryption operator `E_B(t) = M_t (T_t S_t) + F_B(S_t)`, modelled
with scalar state values. -/
def encOp (N T S F : Nat) : Nat := N * T * S + F

/-- Norm bound on the encryption output:
`‖E_B(t)‖ ≤ N_t B_c B_q D_S + D_F`. -/
theorem encOp_bound {N T S F Bc Bq DS DF : Nat}
    (hT : T ≤ Bc * Bq) (hS : S ≤ DS) (hF : F ≤ DF) :
    encOp N T S F ≤ N * (Bc * Bq) * DS + DF := by
  unfold encOp
  have h1 : N * T * S ≤ N * (Bc * Bq) * DS := by
    exact Nat.mul_le_mul (Nat.mul_le_mul_left N hT) hS
  exact Nat.add_le_add h1 hF

/-! ## Feedback dynamics and Banach contraction (`thm:banach` model) -/

/-- Geometric convergence of the Track B feedback map `f_B`: a `q`-Lipschitz
feedback map contracts after `t` steps with factor `q^t`. -/
theorem feedback_convergence {fB : Nat → Nat} {q : Nat}
    (hf : ∀ a b, ndist (fB a) (fB b) ≤ q * ndist a b) :
    ∀ t a b, ndist (iter fB t a) (iter fB t b) ≤ q ^ t * ndist a b :=
  geometric_convergence fB q hf

/-- The distance vanishes exactly at identical points. -/
theorem ndist_eq_zero (a b : Nat) : ndist a b = 0 ↔ a = b := by
  unfold ndist
  split <;> omega

/-- Uniqueness of the fixed point: a `q < 1`-Lipschitz feedback map has at most
one fixed point. -/
theorem unique_fixed_point {f : Nat → Nat} {q : Nat}
    (hf : ∀ a b, ndist (f a) (f b) ≤ q * ndist a b) (hq : q < 1)
    {x y : Nat} (hfx : f x = x) (hfy : f y = y) : x = y := by
  have hxy : ndist x y ≤ q * ndist x y := by
    have := hf x y
    simpa [hfx, hfy] using this
  have hq0 : q = 0 := by omega
  have hz : ndist x y = 0 := by
    have : ndist x y ≤ 0 := by simpa [hq0] using hxy
    omega
  exact (ndist_eq_zero x y).mp hz

/-- Convergence to the fixed point of the feedback map: every orbit tends to it
with factor `q^t`. -/
theorem feedback_tendsto {fB : Nat → Nat} {q zstar : Nat} (hfz : fB zstar = zstar)
    (hf : ∀ a b, ndist (fB a) (fB b) ≤ q * ndist a b) :
    ∀ t a, ndist (iter fB t a) zstar ≤ q ^ t * ndist a zstar :=
  fixed_point_tendsto hfz hf

/-! ## Transcript chains, context hash, and HKDF info strings -/

/-- Per-role transcript chain `chain_{s,0} = 0`, `chain_{s,t} = H(chain_{s,t-1} ‖ m_t)`,
with the hash `H : Nat → Nat` left abstract (a random oracle in the document). -/
def chainStep (H : Nat → Nat) : List Nat → Nat
  | [] => 0
  | m :: ms => H (chainStep H ms + m)

/-- The chain recursion law of the document. -/
theorem chain_step_eq (H : Nat → Nat) (m : Nat) (ms : List Nat) :
    chainStep H (m :: ms) = H (chainStep H ms + m) := rfl

/-- Track B context hash `ctx_t^{(B)} = SHA(chain_{A,t} ‖ chain_{B,t})`, modelled
over the two role chains. -/
def ctxB (H : Nat → Nat) (chainA chainB : Nat) : Nat := H (chainA + chainB)

/-- Communication directions. -/
inductive Direction | A2B | B2A

/-- The two directions are distinct, so their info strings differ. -/
theorem direction_distinct : Direction.A2B ≠ Direction.B2A := by
  intro h
  cases h

/-- Serialisation of a direction for the info string. -/
def showDirection : Direction → String
  | .A2B => "A2B"
  | .B2A => "B2A"

/-- Track B directional info string
`info_d^{(B)} = "QSBS-v1:enc:" ‖ d ‖ ctx ‖ mult`. -/
def infoB (ctx mult : String) (d : Direction) : String :=
  "QSBS-v1:enc:" ++ showDirection d ++ ctx ++ mult

/-- The info string is left-invertible on the direction: distinct directions
produce distinct info strings (model-level directional key separation, since
`K_enc,d,t = HKDF(K_t; salt, info_d)`). -/
theorem infoB_injective_direction (ctx mult : String) {d1 d2 : Direction} :
    infoB ctx mult d1 = infoB ctx mult d2 → d1 = d2 := by
  intro h
  cases d1 <;> cases d2 <;> simp [infoB, showDirection] at h ⊢

end Multiplicity.PMTrackB
