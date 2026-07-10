@row:mac-lane-coherence @stage:S2 @status:some-true @oracle:mtc-axioms
Feature: Mac Lane Coherence
  Scenario: the categorical structure obeys coherence axioms
    Given the UOR Atlas use-case
    Then the Mac Lane Pentagon identity is parametrically tested
