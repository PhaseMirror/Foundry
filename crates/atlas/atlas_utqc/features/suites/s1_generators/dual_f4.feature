@row:dual-f4 @stage:S1 @status:some-true @oracle:uor-addr-composition
Feature: Dual / conjugation reduces to compose_f4_quotient
  The dual is the realized CS-F4 +/- mirror on every sigma-axis, and the conjugation generator
  mu is an order-2 involution on the class space.

  Scenario: the dual reduces to the realized f4 mirror for the Atlas
    Given the UOR Atlas use-case
    Then the dual reduces to the realized f4 mirror involution

  Scenario Outline: the dual holds for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the dual reduces to the realized f4 mirror involution

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
