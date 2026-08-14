@row:quantum-realization @stage:S2 @status:some-true @oracle:mtc-axioms
Feature: Quantum realization
  The composition operators and the braiding act on C^d.
  They are unitary on C^d and exhibit destructive interference.

  Scenario: Unitarity and interference
    Given the UOR Atlas use-case
    Then the quantum realization is unitary and exhibits destructive interference
