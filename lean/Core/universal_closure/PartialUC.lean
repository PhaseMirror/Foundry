/-!
# Partial Universal Closure System — Formal Spec

Pure definition. No proofs. No sorry. No Mathlib.
Kani verifies the implementation satisfies this spec.
-/

structure PartialUC (X : Type) where
  compose_p : X → X → Option X
  closure_p : X → Option X

def is_defined_compose (P : PartialUC X) (x y : X) : Prop :=
  (P.compose_p x y).isSome

def is_defined_closure (P : PartialUC X) (x : X) : Prop :=
  (P.closure_p x).isSome

def defined_compose_val (P : PartialUC X) (x y : X) (h : is_defined_compose P x y) : X :=
  (P.compose_p x y).get h

def defined_closure_val (P : PartialUC X) (x : X) (h : is_defined_closure P x) : X :=
  (P.closure_p x).get h
