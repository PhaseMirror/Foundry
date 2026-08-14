Feature: Structural

  The public GEMM face: shapes, strides, views, and the epilogue.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CS-01 @build
  Scenario: `C <- alpha*A*B + beta*C` with A `m x k`, B `k x n`, C `m x n`
    Given the standing corpus
    When the suite exercises CS-01
    Then the claim holds byte for byte

  @CS-02 @build
  Scenario: A and B strides are arbitrary: negative, zero, and non-contiguous all give the defined result
    Given the standing corpus
    When the suite exercises CS-02
    Then the claim holds byte for byte

  @CS-03 @build
  Scenario: Output strides that alias are rejected at `Triple::new` and nowhere else
    Given the standing corpus
    When the suite exercises CS-03
    Then the claim holds byte for byte

  @CS-04 @build
  Scenario: `beta == 0` overwrites C without reading it, so uninitialized or NaN-filled C is admissible
    Given the standing corpus
    When the suite exercises CS-04
    Then the claim holds byte for byte

  @CS-05 @build
  Scenario: The raw-pointer entry points are signature-identical to `matrixmultiply` and produce the same bytes as the safe API on the same inputs
    Given the standing corpus
    When the suite exercises CS-05
    Then the claim holds byte for byte

  @CS-06 @build
  Scenario: `m`, `n`, `k` that are not multiples of `MR`, `NR`, or `K_GROUP` take the same path and give the same result
    Given the standing corpus
    When the suite exercises CS-06
    Then the claim holds byte for byte

  @CS-07 @build
  Scenario: The generated `133144` pin equals `k_max(127, i32::MAX)` recomputed at test time
    Given the standing corpus
    When the suite exercises CS-07
    Then the claim holds byte for byte
