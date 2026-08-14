@row:braiding-r-matrix @stage:S2 @status:some-true @oracle:mtc-axioms
Feature: Braiding R-matrix
  Constructed as the bicharacter braiding of the generic representative quantum double D(Z_n) (n = context) and
  validated against the MTC axioms only: unitary R-phases, the hexagon (bimultiplicativity in
  both arguments / Yang-Baxter for a pointed category), and the monodromy R_xy R_yx tying R to
  the modular data S. (status: some-true; D(Z_O) is the Atlas-parameterized stand-in, not the Atlas-native category.)

  Scenario: the R-matrix satisfies the hexagon and Yang-Baxter for the Atlas
    Given the UOR Atlas use-case
    Then the braiding R satisfies the hexagon and Yang-Baxter

  Scenario Outline: the braiding holds for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the braiding R satisfies the hexagon and Yang-Baxter

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
