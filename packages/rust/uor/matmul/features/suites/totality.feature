Feature: Totality

  The operation is infallible on everything it can represent.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CT-01 @build
  Scenario: No representable input errors or panics: fuzzed shapes, strides, magnitudes, and depths, under a checked-arithmetic build
    Given the standing corpus
    When the suite exercises CT-01
    Then the claim holds byte for byte

  @CT-02 @build
  Scenario: No accumulation overflows: the whole corpus under checked arithmetic, zero overflow events
    Given the standing corpus
    When the suite exercises CT-02
    Then the claim holds byte for byte

  @CT-03 @build
  Scenario: Non-finite float codes propagate by the IEEE rules and never error
    Given the standing corpus
    When the suite exercises CT-03
    Then the claim holds byte for byte

  @CT-04 @build
  Scenario: Zero, one, and prime dimensions take the same path as any other, and a zero-extent view constructs rather than erroring
    Given the standing corpus
    When the suite exercises CT-04
    Then the claim holds byte for byte

  @CT-05 @build
  Scenario: The two reportable conditions are the only ones, and both are decided at view construction before any arithmetic is named
    Given the standing corpus
    When the suite exercises CT-05
    Then the claim holds byte for byte

  @CT-06 @build
  Scenario: A super-massive product is exact, on every traversal the offer admits
    Given the standing corpus
    When the suite exercises CT-06
    Then the claim holds byte for byte
