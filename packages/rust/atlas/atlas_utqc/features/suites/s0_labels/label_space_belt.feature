@row:label-space-belt @stage:S0 @status:some-true @oracle:f1-atlas
Feature: Label / state-space index (the belt)
  The 12288 = 96x128 = 48x256 belt is a parametric function of the use-case and matches F1.

  Scenario: the belt extent and factorizations reproduce F1
    Given the F1 oracle constants
    And the UOR Atlas use-case
    Then the label-space belt witness reproduces the F1 Atlas
