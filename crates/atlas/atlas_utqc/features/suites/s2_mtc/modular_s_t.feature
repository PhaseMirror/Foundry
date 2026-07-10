@row:modular-s-t @stage:S2 @status:some-true @oracle:mtc-axioms
Feature: Modular S/T matrices
  Constructed as the generic representative quantum double D(Z_n) (n = context) — an anomaly-free pointed modular
  category — and validated against the MTC axioms only: S symmetric and unitary, T of finite
  order, S^4 = 1, (ST)^3 = S^2, S^2 = C (charge conjugation), and Verlinde reproduces the
  group-law fusion. (status: some-true; D(Z_O) is the Atlas-parameterized stand-in, not the Atlas-native category.)

  Scenario: S and T satisfy the SL(2,Z) relations for the Atlas
    Given the UOR Atlas use-case
    Then the modular S and T satisfy the SL(2,Z) relations

  Scenario Outline: the modular data holds for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the modular S and T satisfy the SL(2,Z) relations

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
