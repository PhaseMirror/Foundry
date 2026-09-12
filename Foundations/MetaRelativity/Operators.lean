import Foundations.MetaRelativity.Core

/-!
# Foundations.MetaRelativity.Operators — Universal Operator Stack U = A + B + E

Nat-based operator definitions for the Universal Operator U = A + B + E on discrete states.
-/

namespace Foundations.MetaRelativity

def PrimeBlock (n : Nat) : Type :=
  (Fin n → Nat) → (Fin n → Nat)

def TimeSieveBlock (n : Nat) : Type :=
  (Fin n → Nat) → (Fin n → Nat)

def InternalBlock (n : Nat) : Type :=
  (Fin n → Nat) → (Fin n → Nat)

def UniversalOperator (n : Nat) : Type :=
  (Fin n → Nat) → (Fin n → Nat)

def mkUniversalOperator {n : Nat}
    (a b e : (Fin n → Nat) → (Fin n → Nat)) :
    UniversalOperator n :=
  fun x i => a x i + b x i + e x i

theorem mkUniversalOperator_apply {n : Nat}
    (a b e : (Fin n → Nat) → (Fin n → Nat))
    (x : Fin n → Nat) (i : Fin n) :
    (mkUniversalOperator a b e) x i = a x i + b x i + e x i := rfl

def idOperator {n : Nat} : UniversalOperator n := fun x => x

def zeroOperator {n : Nat} : UniversalOperator n := fun _ _ => 0

theorem component_nonneg {n : Nat}
    (a b e : (Fin n → Nat) → (Fin n → Nat))
    (x : Fin n → Nat) (i : Fin n) :
    (mkUniversalOperator a b e) x i ≥ 0 :=
  Nat.zero_le _

theorem universal_operator_monotone {n : Nat}
    (a b e a' b' e' : (Fin n → Nat) → (Fin n → Nat))
    (x : Fin n → Nat) (i : Fin n)
    (ha : a x i ≤ a' x i) (hb : b x i ≤ b' x i) (he : e x i ≤ e' x i) :
    (mkUniversalOperator a b e) x i ≤ (mkUniversalOperator a' b' e') x i := by
  simp only [mkUniversalOperator]
  omega

theorem id_operator_fixed {n : Nat} (x : Fin n → Nat) (i : Fin n) :
    (idOperator : UniversalOperator n) x i = x i := rfl

theorem zero_operator_zero {n : Nat} (x : Fin n → Nat) (i : Fin n) :
    (zeroOperator : UniversalOperator n) x i = 0 := rfl

theorem universal_operator_comp_assoc {n : Nat}
    (u v w : UniversalOperator n) (x : Fin n → Nat) (i : Fin n) :
    (u ∘ v ∘ w) x i = (u ∘ (v ∘ w)) x i := rfl

theorem universal_operator_bounded_of_components {n : Nat}
    (a b e : (Fin n → Nat) → (Fin n → Nat))
    (x : Fin n → Nat) (i : Fin n)
    (ha : a x i ≤ scale) (hb : b x i ≤ scale) (he : e x i ≤ scale) :
    (mkUniversalOperator a b e) x i ≤ 3 * scale := by
  simp only [mkUniversalOperator]
  omega

theorem mkUniversalOperator_zero {n : Nat} (x : Fin n → Nat) (i : Fin n) :
    (mkUniversalOperator (n := n) (fun _ _ => 0) (fun _ _ => 0) (fun _ _ => 0)) x i = 0 := by
  simp only [mkUniversalOperator]

theorem mkUniversalOperator_id_right {n : Nat} (x : Fin n → Nat) (i : Fin n) :
    (mkUniversalOperator (n := n) (fun s j => s j) (fun _ _ => 0) (fun _ _ => 0)) x i = x i := by
  simp only [mkUniversalOperator]
  omega

end Foundations.MetaRelativity
