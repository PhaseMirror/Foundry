@row:atlas-native-mtc @stage:S2 @status:some-true @oracle:mtc-axioms
Feature: Atlas-native MTC construction
  Scenario: the Atlas-native construction resolves obstructions
    Given the UOR Atlas use-case
    Then the Atlas-native MTC construction successfully resolves topological obstructions
