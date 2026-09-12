@row:generative-closure @stage:S4 @status:some-true @oracle:mtc-axioms
Feature: Generative closure
  All S0 labels and operators are reachable from the single Atlas generator.

  Scenario: Reachability
    Given the UOR Atlas use-case
    Then all S0 labels and operators are reachable from the single Atlas generator
