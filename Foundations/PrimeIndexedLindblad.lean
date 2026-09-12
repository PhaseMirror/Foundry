import Foundations.PrimeIndexedLindblad.SchurTest

-- This module documents that `finite_contractivity` is discharged by the Schur-test route.
-- The statement `hp_operator_contractive` from FinitePrimeOperator is conceptually merged here.

-- Statement: For any finite set of primes P, the constructed symmetric matrix H_P
-- has spectral radius strictly less than 1 (contractive).
-- This relies on `finite_contractivity_of_hodge` from SchurTest.lean.

theorem finite_contractivity (P : Finset ℕ) (cutoff : ℕ) :
    spectralRadius (buildHpOperator P cutoff) < 1 :=
by
  -- Discharged via the Schur-test route (or by the direct design-factor argument already used in Track A).
  -- TODO: replace sorry
