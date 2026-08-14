@row:categorical-structure @stage:S1 @status:some-true @oracle:uor-addr-composition
Feature: Categorical structure e6/e7/e8
  The e6 (2-class grading), e7 (S4 orbit of size T*O) and e8 (embedding) operations are the
  realized CS-E6/E7/E8 compositions on every sigma-axis; the S4 orbit size is the carrier
  dimension T*O (24 for the Atlas), derived from the parameters.

  Scenario: e6/e7/e8 reduce to the realized operations for the Atlas
    Given the UOR Atlas use-case
    Then the e6/e7/e8 operations reduce to the realized operations

  Scenario Outline: the categorical structure holds for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the e6/e7/e8 operations reduce to the realized operations

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
