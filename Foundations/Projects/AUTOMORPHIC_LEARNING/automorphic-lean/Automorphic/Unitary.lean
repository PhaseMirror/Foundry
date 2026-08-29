import Automorphic.Group
import Automorphic.Projection

/-!
# Automorphic Learning: Permutation-Equivariant Unitarization

Matrix operations and unitarity bounds.
-/

namespace Automorphic

structure CMatrix (n : Nat) where
  entries : Fin n → Fin n → Float × Float

def CMatrix.identity (n : Nat) : CMatrix n :=
  ⟨fun i j => if i = j then (1.0, 0.0) else (0.0, 0.0)⟩

def CMatrix.add {n : Nat} (A B : CMatrix n) : CMatrix n :=
  ⟨fun i j =>
    let (r1, i1) := A.entries i j
    let (r2, i2) := B.entries i j
    (r1 + r2, i1 + i2)⟩

def CMatrix.scale {n : Nat} (c : Float) (A : CMatrix n) : CMatrix n :=
  ⟨fun i j =>
    let (r, im) := A.entries i j
    (c * r, c * im)⟩

def CMatrix.frobeniusNormSq {n : Nat} (A : CMatrix n) : Float :=
  (List.range n).foldl (fun acc i =>
    (List.range n).foldl (fun acc2 j =>
      if h1 : i < n then
        if h2 : j < n then
          let (r, im) := A.entries ⟨i, h1⟩ ⟨j, h2⟩
          acc2 + (r * r + im * im)
        else acc2
      else acc2
    ) acc
  ) 0.0

end Automorphic
