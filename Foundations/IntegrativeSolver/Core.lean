/-!
# Foundations.IntegrativeSolver.Core — M-Integrative Solver Core Finite Arithmetic

Formalizes System Configuration Vectors (SCV), finite sums, channel growth profiles, and monotone aggregation.
-/

namespace Foundations.IntegrativeSolver

abbrev Channels (K : Nat) := Fin K

structure SCV (K : Nat) where
  counts : Channels K → Nat

theorem scv_eq_iff {K : Nat} (v w : SCV K) : v = w ↔ ∀ k, v.counts k = w.counts k := by
  constructor
  · intro h k
    rw [h]
  · cases v
    cases w
    intro h
    congr
    funext k
    exact h k

def support {K : Nat} (v : SCV K) : Channels K → Prop :=
  fun k => 0 < v.counts k

noncomputable def restrict {K : Nat} (v : SCV K) (s : Channels K → Prop) : Channels K → Nat := by
  classical
  exact fun k => if s k then v.counts k else 0

def sumFin : {K : Nat} → (Fin K → Nat) → Nat
  | 0, _ => 0
  | K + 1, f => sumFin (fun i : Fin K => f i.castSucc) + f (Fin.last K)

theorem sumFin_succ (K : Nat) (f : Fin (K + 1) → Nat) :
    sumFin f = sumFin (fun i : Fin K => f i.castSucc) + f (Fin.last K) := rfl

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

def absDiff (a b : Nat) : Nat :=
  if a ≤ b then b - a else a - b

theorem absDiff_symm (a b : Nat) : absDiff a b = absDiff b a := by
  unfold absDiff
  split <;> split <;> omega

structure Growth where
  apply : Nat → Nat
  monotone : ∀ {a b : Nat}, a ≤ b → apply a ≤ apply b

def capped (τ : Nat) : Growth where
  apply := fun x => Nat.min x τ
  monotone := by
    intro a b hab
    apply Nat.le_min.mpr
    constructor
    · exact Nat.le_trans (Nat.min_le_left a τ) hab
    · exact Nat.min_le_right a τ

theorem capped_le (τ x : Nat) : (capped τ).apply x ≤ τ := by
  simp [capped, Nat.min_le_right]

structure ChannelSpec (K : Nat) where
  weight : Channels K → Nat
  growth : Channels K → Growth

def aggregate {K : Nat} (spec : ChannelSpec K) (v : SCV K) : Nat :=
  sumFin (fun k => spec.weight k * (spec.growth k).apply (v.counts k))

theorem aggregate_monotone {K : Nat} (spec : ChannelSpec K) (v w : SCV K)
    (h : ∀ k, v.counts k ≤ w.counts k) : aggregate spec v ≤ aggregate spec w := by
  unfold aggregate
  apply sumFin_mono
  intro k
  exact Nat.mul_le_mul_left (spec.weight k) ((spec.growth k).monotone (h k))

theorem aggregate_bounded {K : Nat} (spec : ChannelSpec K) (v : SCV K) (C : Nat)
    (h : ∀ k, (spec.growth k).apply (v.counts k) ≤ C) :
    aggregate spec v ≤ sumFin (fun k => spec.weight k * C) := by
  unfold aggregate
  apply sumFin_mono
  intro k
  exact Nat.mul_le_mul_left (spec.weight k) (h k)

def cappedSpec (K : Nat) (τ : Nat) (w : Channels K → Nat) : ChannelSpec K where
  weight := w
  growth := fun _ => capped τ

theorem aggregate_capped_le (K : Nat) (w : Channels K → Nat) (τ : Nat) (v : SCV K) :
    aggregate (cappedSpec K τ w) v ≤ sumFin (fun k => w k * τ) := by
  apply aggregate_bounded (cappedSpec K τ w) v τ
  intro k
  exact capped_le τ (v.counts k)

end Foundations.IntegrativeSolver
