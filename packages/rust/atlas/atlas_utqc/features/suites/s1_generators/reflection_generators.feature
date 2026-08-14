@row:reflection-generators @stage:S1 @status:some-true @oracle:f1-atlas
Feature: Reflection generators are unitary without invoking the crux
  sigma, tau and mu are coordinate (class) permutations. Because every permutation preserves
  sum x_i^2, the generators are orthogonal — hence unitary — with no positivity assumption.
  This is "the unlock": braiding unitarity is established; the RH crux is untouched.

  Scenario: the generators have the F1 orders and preserve the Euclidean norm
    Given the F1 oracle constants
    And the UOR Atlas use-case
    Then the generators have the F1 orders and preserve the inner product

  Scenario Outline: generator orders follow the parameters for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the generators have orders scope, context and two

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 5 | 2 | 3 |
