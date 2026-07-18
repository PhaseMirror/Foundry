namespace MOC.Ramanujan

/-- Deligne's bound |a_p| ≤ 2 p^{(k-1)/2}, squared to avoid reals.
    `a` is the eigenvalue, `p` the prime, `k` the weight. -/
def deligne_bound (a : Int) (p k : Nat) : Prop :=
  a * a ≤ 4 * ((p : Int) ^ (k - 1))

/-- Hecke recurrence for the eigenvalue of a prime power:
    a_{p^{r+2}} = a_p * a_{p^{r+1}} - p^{k-1} * a_{p^r}. 
    Adapted for the exponent sequence `f(r) = a_{p^r}`. -/
def hecke_recurrence_seq (f : Nat → Int) (k p r : Nat) : Prop :=
  f (r + 2) = f 1 * f (r + 1) - ((p : Int) ^ (k - 1)) * f r

/-- 
  A PrimeBlock defines the base coefficients of a Hecke eigenform for a specific prime.
  Instead of verifying arbitrary limits, the validation occurs strictly by explicit computation
  up to a safe bound `r_max`.
-/
structure PrimeBlock where
  p : Nat
  k : Nat
  a_p : Int
  deriving Repr

/-- 
  Computes the coefficient sequence deterministically via the recurrence
  to guarantee `hecke_recurrence` holds by construction, rather than checking it.
-/
def compute_coeff (blk : PrimeBlock) : Nat → Int
  | 0 => 1
  | 1 => blk.a_p
  | (r + 2) => blk.a_p * compute_coeff blk (r + 1) - ((blk.p : Int) ^ (blk.k - 1)) * compute_coeff blk r

end MOC.Ramanujan
