Feature: Allocation and environment

  Zero heap, no_std, and the same bytes off the host.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CA-01 @build
  Scenario: Zero allocations during any call, on every hosted target
    Given the standing corpus
    When the suite exercises CA-01
    Then the claim holds byte for byte

  @CA-02 @build
  Scenario: Identical bytes on `thumbv7em-none-eabihf` and both wasm targets as on x86-64
    Given the standing corpus
    When the suite exercises CA-02
    Then the claim holds byte for byte

  @CA-03 @build
  Scenario: No shipped crate links an allocator symbol on a `no_std` target
    Given the standing corpus
    When the suite exercises CA-03
    Then the claim holds byte for byte
