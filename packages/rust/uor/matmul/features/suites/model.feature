Feature: Model integrity

  The model is the single source of every constant.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CM-01 @build
  Scenario: The generated Rust consts equal `model/constants.toml`
    Given the standing corpus
    When the suite exercises CM-01
    Then the claim holds byte for byte

  @CM-02 @build
  Scenario: Every ID in `model/ids.toml` has a scenario and a test, and every test's ID is in the register
    Given the standing corpus
    When the suite exercises CM-02
    Then the claim holds byte for byte

  @CM-03 @build
  Scenario: Every `some-true` claim has a row in `model/authorities.toml` with a citation
    Given the standing corpus
    When the suite exercises CM-03
    Then the claim holds byte for byte
