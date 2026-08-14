Feature: Determinism

  Same inputs, same bytes, whatever the schedule.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CD-01 @build
  Scenario: Backend choice does not change output bytes
    Given the standing corpus
    When the suite exercises CD-01
    Then the claim holds byte for byte

  @CD-02 @build
  Scenario: Tile count and completion order do not change output bytes, over `{1,2,3,5,8,64,m*n}` and shuffled orders
    Given the standing corpus
    When the suite exercises CD-02
    Then the claim holds byte for byte

  @CD-03 @build
  Scenario: Every partial sum stays inside the accumulator, measured by `dot_instrumented`, never inferred
    Given the standing corpus
    When the suite exercises CD-03
    Then the claim holds byte for byte

  @CD-04 @build
  Scenario: Traversal and blocking preset do not change output bytes, including deliberately bad presets
    Given the standing corpus
    When the suite exercises CD-04
    Then the claim holds byte for byte

  @CD-05 @build
  Scenario: Encode mode is the only thing that changes the output bytes for a fixed accumulation
    Given the standing corpus
    When the suite exercises CD-05
    Then the claim holds byte for byte

  @CD-06 @build
  Scenario: Big-endian and little-endian targets agree on the serialized output
    Given the standing corpus
    When the suite exercises CD-06
    Then the claim holds byte for byte

  @CD-07 @build
  Scenario: Splitting the operand stream at any index sums the parts
    Given the standing corpus
    When the suite exercises CD-07
    Then the claim holds byte for byte

  @CD-08 @build
  Scenario: Two tiles reduce in either order
    Given the standing corpus
    When the suite exercises CD-08
    Then the claim holds byte for byte

  @CD-09 @build
  Scenario: The narrow-register tile path agrees with `dot_wide`
    Given the standing corpus
    When the suite exercises CD-09
    Then the claim holds byte for byte

  @CD-10 @build
  Scenario: `Scratch::None`, one byte, `suggested_scratch - 1`, `suggested_scratch`, and ten times it all give the same bytes
    Given the standing corpus
    When the suite exercises CD-10
    Then the claim holds byte for byte

  @CD-11 @build
  Scenario: Forcing a wider accumulator than necessary changes nothing but the room
    Given the standing corpus
    When the suite exercises CD-11
    Then the claim holds byte for byte

  @CD-12 @build
  Scenario: Collapsing equal rows of A cannot change a byte, at every degeneracy and every offer
    Given the standing corpus
    When the suite exercises CD-12
    Then the claim holds byte for byte
