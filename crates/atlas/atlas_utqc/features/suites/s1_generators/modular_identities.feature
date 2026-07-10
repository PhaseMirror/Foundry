@row:modular-identities @stage:S1 @status:some-true @oracle:f1-atlas
Feature: Modular identities
  The identity E4^3 = E6^2 + 1728*Delta holds on the F1 q-expansion coefficients (cross-checkable
  against LMFDB / OEIS), and the weight T*O/2 = 12 is consistent with the carrier dimension.

  Scenario: E4 cubed equals E6 squared plus 1728 Delta
    Given the F1 oracle constants
    And the UOR Atlas use-case
    Then the modular identity holds on the F1 coefficients
