@row:holospace-cycle @stage:S3 @status:some-true @oracle:holospaces-cc
Feature: Braid -> fuse -> read holospace cycle
  The UTQC runs as one holospace on the content-addressing substrate: an amplitude-space state is
  encoded to a kappa (CC-1), a generator braid word re-addresses deterministically (CC-2),
  isotopic words (same operator) collapse to the same kappa, the composition outcome reads out, and
  the state round-trips with no loss (CC-29/30). The holospace cycle executes generator gates through the native Hologram execution path in `tqc-substrate`: a permutation gate is compiled to a Hologram archive and run through `hologram_exec::InferenceSession`. Persisted `.holo` artifacts are written and addressable.
  Scenario: a braid -> fuse -> read cycle runs and is resumable for the Atlas
    Given the UOR Atlas use-case
    Then the braid-fuse-read holospace cycle runs and round-trips

  Scenario Outline: the cycle runs for arbitrary use-cases
    Given an arbitrary use-case with scope <q> modality <T> context <O>
    Then the braid-fuse-read holospace cycle runs and round-trips

    Examples:
      | q | T | O |
      | 4 | 3 | 8 |
      | 2 | 2 | 4 |
