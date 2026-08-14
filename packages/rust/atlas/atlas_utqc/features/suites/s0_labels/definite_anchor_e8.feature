@row:definite-anchor-e8 @stage:S0 @status:some-true @oracle:f1-atlas
Feature: Definite anchor — the E8 PSD seed
  The E8 root-lattice Gram is 4x the Cartan matrix (diagonal 8, edges -4) and is
  positive-definite — a manifest sum of squares — matching the F1 e8_seed. Generically, every
  use-case's Euclidean companion is positive-definite.

  Scenario: the E8 Gram equals 4x Cartan and is positive-definite
    Given the F1 oracle constants
    Then the E8 definite anchor reproduces the F1 Atlas

  Scenario Outline: the definite anchor is positive-definite for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the definite anchor is positive-definite

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
