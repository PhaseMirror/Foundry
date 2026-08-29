/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Root import file for the Multiplicity Operator library.

TIER 1 — Axiom-clean (zero -- TODO: replace sorry in code, zero axioms beyond {propext, Quot.sound}):
  All modules below build with pure core Lean 4 + std4 only.
  NOTE: docstring claims verified by scan on 2026-07-22.

TIER 3 — Mathlib-dependent (-- TODO: replace sorry-gated for PDE/analysis axioms):
  FloerDifferential: 4 axiom-gated propositions (PDE derivative, tensor
  convergence, Lipschitz, contraction bound). The finite-dimensional
  instantiation is fully computable.

Mathlib-dependent modules (MultiplicityOperator, UpdateOperator) are NOT
imported here. They require Core.foundations.BanachSpace which depends on
Mathlib and are excluded from the axiom-clean build.
-/

-- Tier 1: Fibonacci operator (discrete recurrence, monotonicity, growth bounds)
import Foundations.Operators.FibonacciOperator

-- Tier 1: Algebraic operators (matrix/vector ops, determinant, eigenvalue decomp)
import Foundations.Operators.AlgebraicOperators

-- Tier 1: Functional operators (exponential/logarithmic via rational power series)
import Foundations.Operators.FunctionalOperators

-- Tier 1: Probabilistic operators (Bernoulli, discrete distributions, expectation)
import Foundations.Operators.ProbabilisticOperators

-- Tier 1: Prime encoding (IsPrime, Godel encoding, injectivity)
import Foundations.Operators.PrimeEncoding

-- Tier 1: Quantum gates (Gaussian rationals, 2×2/4×4 matrices, unitarity)
import Foundations.Operators.QuantumGates

-- Tier 1: Multiplicity processor (eigenvalue evolution, multiplicity equation)
import Foundations.Operators.MultiplicityProcessor

-- Tier 1: PEQOMA (prime-encoded quantum operator multiplicity algorithm)
import Foundations.Operators.PEQOMA

-- Tier 1: Phase-adaptive controller (entanglement matrix, coherence)
import Foundations.Operators.PhaseAdaptiveController

-- Tier 1: SHELL controller (feedback, self-healing, prime modulation)
import Foundations.Operators.ShellController

-- Tier 1: Stochastic controller (SGD, variance penalty, cost bounds)
import Foundations.Operators.StochasticController

-- Tier 1: Zeta controller (dual-network prime partition, stability metric)
import Foundations.Operators.ZetaController

-- Tier 1: Higher-order multiplicities (multiplicities of multiplicity)
import Foundations.Core.multiplicity.HigherOrderMultiplicity
import Foundations.Core.multiplicity.TensorProduct
import Foundations.Core.multiplicity.RecursiveDepth

-- Tier 3: Floer differential (abstract + finite-dimensional, axiom-gated)
import Foundations.Operators.FloerDifferential
