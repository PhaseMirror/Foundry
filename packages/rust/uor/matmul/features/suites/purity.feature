Feature: Purity

  One method. No classical path, no fallback.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CU-01 @build
  Scenario: No float add, subtract, multiply, or FMA opcode appears in any shipped kernel's disassembly, on any target
    Given the standing corpus
    When the suite exercises CU-01
    Then the claim holds byte for byte

  @CU-02 @build
  Scenario: The instrumented count of narrow-path tiles matches `fits_narrow` exactly, so no tile takes an unintended path
    Given the standing corpus
    When the suite exercises CU-02
    Then the claim holds byte for byte

  @CU-03 @build
  Scenario: Every instruction sequence agrees at depths straddling its own threshold
    Given the standing corpus
    When the suite exercises CU-03
    Then the claim holds byte for byte

  @CU-04 @build
  Scenario: Float accumulation is order-independent: shuffled tiles and every backend agree bit for bit, including on catastrophic-cancellation cases
    Given the standing corpus
    When the suite exercises CU-04
    Then the claim holds byte for byte

  @CU-05 @build
  Scenario: There is exactly one accumulation path per element family, asserted by `audit-purity` over the call graph
    Given the standing corpus
    When the suite exercises CU-05
    Then the claim holds byte for byte
