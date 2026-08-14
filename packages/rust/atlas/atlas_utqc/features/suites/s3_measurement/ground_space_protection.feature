@row:ground-space-protection @stage:S3 @status:some-true @oracle:holospaces-cc
Feature: Ground space / topological protection
  Content-addressing is a faithful round-trip on the holospaces substrate: a state's kappa is
  stable (CC-1), content re-derives to its kappa (pi.iota = id), and distinct content has a
  distinct kappa (eviction drops bytes, not identity).

  Scenario: a TQC holospace round-trips with no loss for the Atlas
    Given the UOR Atlas use-case
    Then the ground space round-trips with no loss

  Scenario Outline: the ground space round-trips for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the ground space round-trips with no loss

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
