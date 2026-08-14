import Multiplicity.Std
open Classical

namespace Multiplicity.IntegrativeSolver

namespace Multiplicity.Core

abbrev Channels (K : Nat) := Fin K

structure SCV (K : Nat) where
  counts : Channels K → Nat

theorem scv_eq_iff {K : Nat} (v w : SCV K) : v = w ↔ ∀ k, v.counts k = w.counts k := by
  constructor
  · intro h k
    rw [h]
  · induction v with
    | mk c1 =>
        induction w with
        | mk c2 =>
            intro h
            have : c1 = c2 := by
              funext k
              exact h k
            rw [this]

/-- The support of an SCV: the channels carrying a strictly positive load. -/
def support {K : Nat} (v : SCV K) : Channels K → Prop :=
  fun k => 0 < v.counts k

/-- Restriction of an SCV to a set of channels; channels outside the set read 0. -/
noncomputable def restrict {K : Nat} (v : SCV K) (s : Channels K → Prop) : Channels K → Nat :=
  fun k => if s k then v.counts k else 0

/-! ## Finite arithmetic layer -/

/-- Finite sum over `Fin K`. -/
def sumFin : {K : Nat} → (Fin K → Nat) → Nat
  | 0, _ => 0
  | K + 1, f => sumFin (fun i : Fin K => f i.castSucc) + f (Fin.last K)

theorem sumFin_succ (K : Nat) (f : Fin (K + 1) → Nat) :
    sumFin f = sumFin (fun i : Fin K => f i.castSucc) + f (Fin.last K) := by
  rfl

theorem sumFin_mono {K : Nat} (f g : Fin K → Nat) (h : ∀ k, f k ≤ g k) :
    sumFin f ≤ sumFin g := by
  induction K with
  | zero => simp [sumFin]
  | succ K ih =>
      have h1 := ih (fun i : Fin K => f i.castSucc) (fun i : Fin K => g i.castSucc) (fun i => h i.castSucc)
      have h2 := h (Fin.last K)
      simp [sumFin]
      omega

theorem sumFin_add (K : Nat) (f g : Fin K → Nat) :
    sumFin (fun k => f k + g k) = sumFin f + sumFin g := by
  induction K with
  | zero => simp [sumFin]
  | succ K ih =>
      have h1 := ih (fun i : Fin K => f i.castSucc) (fun i : Fin K => g i.castSucc)
      simp [sumFin]
      omega

theorem sumFin_mul_right (K : Nat) (f : Fin K → Nat) (c : Nat) :
    sumFin (fun k => f k * c) = sumFin f * c := by
  induction K with
  | zero => simp [sumFin]
  | succ K ih =>
      simp [sumFin]
      rw [ih (fun i : Fin K => f i.castSucc)]
      rw [Nat.add_mul]

theorem sumFin_const (K : Nat) (c : Nat) : sumFin (fun _ : Fin K => c) = K * c := by
  induction K with
  | zero => simp [sumFin]
  | succ K ih =>
      simp [sumFin, ih]
      rw [Nat.succ_mul]

theorem sumFin_le {K : Nat} (f : Fin K → Nat) (M : Nat) (h : ∀ k, f k ≤ M) :
    sumFin f ≤ K * M := by
  have hm := sumFin_mono f (fun _ : Fin K => M) h
  have hc := sumFin_const K M
  rw [hc] at hm
  exact hm

/-- Finite max over `Fin K`. -/
def maxFin : {K : Nat} → (Fin K → Nat) → Nat
  | 0, _ => 0
  | K + 1, f => Nat.max (maxFin (fun i : Fin K => f i.castSucc)) (f (Fin.last K))

theorem maxFin_ge {K : Nat} (f : Fin K → Nat) (k : Fin K) : f k ≤ maxFin f := by
  induction K with
  | zero => cases k; omega
  | succ K ih =>
      by_cases hlast : k.val = K
      · have hk : k = Fin.last K := Fin.ext hlast
        subst k
        simp [maxFin, Nat.le_max_right]
      · have hklt : k.val < K := by omega
        have hcast : k = (⟨k.val, hklt⟩ : Fin K).castSucc := by
          apply Fin.ext
          simp
        rw [hcast]
        have hge := ih (fun i : Fin K => f i.castSucc) ⟨k.val, hklt⟩
        simpa [maxFin] using Nat.le_trans hge (Nat.le_max_left _ _)

theorem maxFin_le {K : Nat} (f : Fin K → Nat) (M : Nat) (h : ∀ k, f k ≤ M) :
    maxFin f ≤ M := by
  induction K with
  | zero => simp [maxFin]
  | succ K ih =>
      simp [maxFin]
      have hmax : maxFin (fun i : Fin K => f i.castSucc) ≤ M :=
        ih (fun i : Fin K => f i.castSucc) (fun i => h i.castSucc)
      have hlast : f (Fin.last K) ≤ M := h (Fin.last K)
      exact Nat.max_le.mpr ⟨hmax, hlast⟩

/-- Absolute difference of two naturals. -/
def absDiff (a b : Nat) : Nat :=
  if _ : a ≤ b then b - a else a - b

theorem absDiff_symm (a b : Nat) : absDiff a b = absDiff b a := by
  by_cases h : a ≤ b
  · by_cases hb : b ≤ a
    · have hab : a = b := Nat.le_antisymm h hb
      simp [absDiff, h, hb]
    · simp [absDiff, h, hb]
  · have hb : b ≤ a := Nat.le_of_lt (Nat.lt_of_not_ge h)
    simp [absDiff, h, hb]

theorem sub_le_absDiff (a b : Nat) : a - b ≤ absDiff a b := by
  by_cases h : a ≤ b
  · simp [absDiff, h]
  · simp [absDiff, h]

/-- The number of active (nonzero) channels never exceeds the channel count. -/
def active_channels {K : Nat} (v : SCV K) : Nat :=
  sumFin (fun k : Fin K => if 0 < v.counts k then 1 else 0)

theorem active_channels_le {K : Nat} (v : SCV K) : active_channels v ≤ K := by
  unfold active_channels
  have h := sumFin_le (fun k : Fin K => if 0 < v.counts k then 1 else 0) 1
    (by
      intro k
      by_cases hk : 0 < v.counts k <;> simp [hk])
  rw [Nat.mul_one K] at h
  exact h

/-! ## Channel growth and aggregation -/

/-- A channel growth profile: a monotone function from load to scale (paper A1). -/
structure Growth where
  apply : Nat → Nat
  monotone : ∀ {a b : Nat}, a ≤ b → apply a ≤ apply b

/-- A capped growth profile `min x τ` with explicit capacity `τ`. -/
def capped (τ : Nat) : Growth where
  apply := fun x => Nat.min x τ
  monotone := by
    intro a b hab
    unfold Nat.min
    by_cases ha : a ≤ τ
    · by_cases hb : b ≤ τ
      · simp [ha, hb, hab]
      · have hmin : min b τ = τ := Nat.min_eq_right (by omega)
        simp [hmin, ha]
    · by_cases hb : b ≤ τ
      · have hmin : min a τ = τ := Nat.min_eq_right (by omega)
        simp [hmin, hb]
        omega
      · omega

theorem capped_le (τ x : Nat) : (capped τ).apply x ≤ τ := by
  simp [capped, Nat.min_le_right]

/-- A channel specification: a weight `ω_k` and a growth profile per channel. -/
structure ChannelSpec (K : Nat) where
  weight : Channels K → Nat
  growth : Channels K → Growth

/-- The aggregate score `W(v) = Σ_k ω_k · s_k(v.k)` (paper eq. 5). -/
def aggregate {K : Nat} (spec : ChannelSpec K) (v : SCV K) : Nat :=
  sumFin (fun k => spec.weight k * (spec.growth k).apply (v.counts k))

/--
**A1 (Monotone aggregation).**  Coordinatewise growth of the counts (in
particular, monotone intervention effects) cannot decrease the aggregate.
-/
theorem aggregate_monotone {K : Nat} (spec : ChannelSpec K) (v w : SCV K)
    (h : ∀ k, v.counts k ≤ w.counts k) : aggregate spec v ≤ aggregate spec w := by
  unfold aggregate
  apply sumFin_mono
  intro k
  exact Nat.mul_le_mul_left (spec.weight k) ((spec.growth k).monotone (h k))

/--
**A2 (Bounded aggregation).**  If every channel's scale at the current load is
bounded by `C`, the aggregate is bounded by `Σ_k ω_k·C`.
-/
theorem aggregate_bounded {K : Nat} (spec : ChannelSpec K) (v : SCV K) (C : Nat)
    (h : ∀ k, (spec.growth k).apply (v.counts k) ≤ C) :
    aggregate spec v ≤ sumFin (fun k => spec.weight k * C) := by
  unfold aggregate
  apply sumFin_mono
  intro k
  exact Nat.mul_le_mul_left (spec.weight k) (h k)

/-- A specification whose channels all use the same cap `τ`. -/
def cappedSpec (K : Nat) (τ : Nat) (w : Channels K → Nat) : ChannelSpec K where
  weight := w
  growth := fun _ => capped τ

/-- The aggregate under a uniform cap `τ` is bounded by `Σ_k ω_k·τ`. -/
theorem aggregate_capped_le (K : Nat) (w : Channels K → Nat) (τ : Nat) (v : SCV K) :
    aggregate (cappedSpec K τ w) v ≤ sumFin (fun k => w k * τ) := by
  apply aggregate_bounded (cappedSpec K τ w) v τ
  intro k
  exact capped_le τ (v.counts k)

end Multiplicity.Core

end Multiplicity.IntegrativeSolver
