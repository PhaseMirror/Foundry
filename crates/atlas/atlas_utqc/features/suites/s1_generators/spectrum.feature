@row:spectrum @stage:S1 @status:some-true @oracle:f1-atlas
Feature: Spectrum / superselection
  The balanced spectral operator M = (O+2)I - T*Pi_T - O*Pi_O has block eigenvalues derived
  parametrically; the F1 multiplicities reconcile to the F1 signature (10,14) and trace 24.

  Scenario: the block eigenvalues and F1 multiplicities reconcile to the F1 signature
    Given the F1 oracle constants
    And the UOR Atlas use-case
    Then the spectrum reconciles with the F1 multiplicities and signature
