Feature: Statistical

  Randomized differential testing, with the sample size and seed recorded.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CP-01 @build
  Scenario: The randomized differential suite at the sample size derived in `ANALYSIS.md`, seeds recorded
    Given the standing corpus
    When the suite exercises CP-01
    Then the claim holds byte for byte
