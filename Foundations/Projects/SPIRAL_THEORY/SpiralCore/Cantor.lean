import Init
import SpiralCore.Core

/-! # Cantor Pairing and Zigzag Encoding

Formalizes the Cantor pairing function pi: NxN -> N and the bijective
zigzag encoding z: Z -> N used for Cantor-IP scalarization (Section 5.7).

Both operations are exact on bounded inputs; for unbounded integers,
arbitrary-precision or bounded hashes are required by [REQ].
-/

namespace SpiralCore.Cantor

/-- Cantor pairing function on nonnegative integers:
    pi(a, b) = ((a + b) * (a + b + 1)) / 2 + b. -/
def cantorPair (a b : Nat) : Nat :=
  let s := a + b
  (s * (s + 1)) / 2 + b

/-- Bijective zigzag encoding from Int to Nat:
    z(n) = 2n if n >= 0, z(n) = -2n - 1 if n < 0. -/
def zigzag (n : Int) : Nat :=
  if n >= 0 then
    2 * Int.toNat n
  else
    let m := Int.toNat (-n)
    2 * m - 1

/-- Inverse zigzag decoding from Nat to Int. -/
def zigzagInv (z : Nat) : Int :=
  if z % 2 == 0 then
    Int.ofNat (z / 2)
  else
    -Int.ofNat ((z + 1) / 2)

end SpiralCore.Cantor
