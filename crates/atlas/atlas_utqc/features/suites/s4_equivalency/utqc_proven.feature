@row:utqc-proven @stage:S4 @status:some-true @oracle:mtc-axioms
Feature: UTQC proven roll-up
  The UTQC proven roll-up goes some-true only when the other four pillars hold.

  Scenario: Roll-up
    Given the UOR Atlas use-case
    Then the UTQC is proven
