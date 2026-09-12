Feature: Codec

  The codec is not an argument of the arithmetic.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CK-01 @build
  Scenario: Two codecs with equal decodes give equal output bytes
    Given the standing corpus
    When the suite exercises CK-01
    Then the claim holds byte for byte

  @CK-02 @build
  Scenario: Codec-invariance holds when both operands are coded
    Given the standing corpus
    When the suite exercises CK-02
    Then the claim holds byte for byte

  @CK-03 @build
  Scenario: The packed panels themselves are byte-equal across codecs that decode equally
    Given the standing corpus
    When the suite exercises CK-03
    Then the claim holds byte for byte

  @CK-04 @build
  Scenario: A transcoded stream equals the composite codec
    Given the standing corpus
    When the suite exercises CK-04
    Then the claim holds byte for byte

  @CK-05 @build
  Scenario: Two `CodedMatrix` values with different kappa labels and equal decodes give equal output bytes
    Given the standing corpus
    When the suite exercises CK-05
    Then the claim holds byte for byte

  @CK-06 @build
  Scenario: A run codec's returned counts sum to the declared row width on every row
    Given the standing corpus
    When the suite exercises CK-06
    Then the claim holds byte for byte

  @CK-08 @build
  Scenario: The canonical manifest is byte-stable, a short buffer reports the need, and a malformed digest is rejected
    Given the standing corpus
    When the suite exercises CK-08
    Then the claim holds byte for byte
