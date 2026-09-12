@row:coxeter-weyl @stage:S1 @status:some-true @oracle:f1-atlas
Feature: Coxeter / Weyl group
  The E8 Coxeter number is 30; its totient is the rank, which equals the context O = 8.

  Scenario: the rank is phi(h) and equals the context
    Given the F1 oracle constants
    And the UOR Atlas use-case
    Then the Coxeter rank equals phi of the Coxeter number and the context
