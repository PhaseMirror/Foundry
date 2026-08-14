@row:objects-labels @stage:S0 @status:some-true @oracle:f1-atlas
Feature: Objects (anyon labels)
  The class label set is derived parametrically from the use-case parameters and matches the
  machine-checked F1 formalization of the UOR Atlas.

  Background:
    Given the F1 oracle constants

  Scenario: the Atlas class structure reproduces F1
    Given the UOR Atlas use-case
    Then the objects-labels witness reproduces the F1 Atlas

  Scenario Outline: classIndex is a bijection for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then classIndex is a bijection over the whole class space

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
      | 5 | 1 | 3 |
