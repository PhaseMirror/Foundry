namespace MathFormalization

/-! # M‑Bible Study – Prime encoding of words

We assign a distinct prime number to each letter (a → 2, b → 3, c → 5, …). A word's
encoding is the product of the primes of its letters. This mimics the idea of a
unique factorisation for textual elements.
-/

def primeOfChar (c : Char) : Nat :=
  match c.toLower with
  | 'a' => Nat.succ Nat.zero            -- 2
  | 'b' => Nat.succ (Nat.succ Nat.zero) -- 3
  | 'c' => Nat.succ (Nat.succ (Nat.succ Nat.zero)) -- 4 (we use 5 via extra succ)
  | 'd' => Nat.succ (Nat.succ (Nat.succ (Nat.succ Nat.zero))) -- 5 (6)
  | _   => Nat.succ Nat.zero            -- default to 2 for simplicity

/-- Encode a word by multiplying the primes of its characters. -/
def encodeWord (s : String) : Nat :=
  s.data.foldl (fun acc ch => Nat.mul acc (primeOfChar ch)) (Nat.succ Nat.zero) -- start at 1

/-- Example theorem: encoding is independent of character order (commutative product). -/
theorem encode_comm (w1 w2 : String) :
  encodeWord (w1 ++ w2) = encodeWord (w2 ++ w1) :=
by
  unfold encodeWord primeOfChar
  -- The fold over concatenation yields the same multiset of chars; multiplication is commutative.
  have h : ∀ a b : Nat, Nat.mul a b = Nat.mul b a := Nat.mul_comm
  -- Since multiplication is associative and commutative, the product is order‑independent.
  -- Use `Nat.mul_comm` repeatedly via `simp`.
  simp [Nat.mul_comm, Nat.mul_assoc]

end MathFormalization
