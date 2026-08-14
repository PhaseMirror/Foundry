@row:two-qubit-universality @stage:S4 @status:build @oracle:mtc-axioms
Feature: Two-Qubit Universality Proof

  @row:two-qubit-universality
  Scenario: A native entangling gate is derived from the coherent abelian construction
    Given the UOR Atlas use-case
    When a two-qubit entangling gate is natively constructed from the abelian category
    Then the gate establishes full multi-qubit universality
    And it does not induce a theory collision with the non-abelian construction
