@row:s4-modal-logic @stage:S4 @status:some-true @oracle:mtc-axioms
Feature: Non-Pointed S4 Modal Logic
  Scenario: the Atlas evaluates within the S4 topological space
    Given the UOR Atlas use-case
    Then the S4 modal logic frame satisfies reflexivity and transitivity
