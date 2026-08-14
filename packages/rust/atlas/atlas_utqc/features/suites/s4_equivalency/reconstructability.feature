@row:reconstructability @stage:S4 @status:some-true @oracle:mtc-axioms
Feature: Absolute Topological Reconstructability
  Scenario: a state can be perfectly reconstructed from the genesis hash and the braid word
    Given the UOR Atlas use-case
    Then any validator can perfectly mathematically reconstruct the final state and identical kappa from the genesis configuration and braid word
