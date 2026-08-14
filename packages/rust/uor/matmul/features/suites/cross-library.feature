Feature: Cross-library agreement

  Byte equality with libraries that have never heard of this one.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CX-01 @build
  Scenario: `ndarray` `i32`, byte-identical over the whole corpus under `EncodeMode::Wrapping`
    Given the standing corpus
    When the suite exercises CX-01
    Then the claim holds byte for byte

  @CX-02 @build
  Scenario: `nalgebra` `i32`, likewise
    Given the standing corpus
    When the suite exercises CX-02
    Then the claim holds byte for byte

  @CX-03 @build
  Scenario: `ndarray` `i32` against our `i8` kernels on widened inputs
    Given the standing corpus
    When the suite exercises CX-03
    Then the claim holds byte for byte

  @CX-04 @build
  Scenario: `nalgebra` `i32` against our coded kernels on decoded weights
    Given the standing corpus
    When the suite exercises CX-04
    Then the claim holds byte for byte

  @CX-05 @open
  Scenario: `matrixmultiply` `sgemm`: deviation from our exact value, in ulps
    Given the standing sweep and its recorded seed
    When the harness measures CX-05
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CX-06 @open
  Scenario: `faer` `f32`: likewise
    Given the standing sweep and its recorded seed
    When the harness measures CX-06
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CX-07 @open
  Scenario: `ndarray` `f32`: likewise, recorded as not independent of `CX-05`
    Given the standing sweep and its recorded seed
    When the harness measures CX-07
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CX-08 @open
  Scenario: `gemm` crate `f32`: likewise
    Given the standing sweep and its recorded seed
    When the harness measures CX-08
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CX-09 @open
  Scenario: `matrixmultiply` `dgemm`: likewise at f64
    Given the standing sweep and its recorded seed
    When the harness measures CX-09
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CX-10 @build
  Scenario: NumPy `int64` out of process, byte-identical
    Given the standing corpus
    When the suite exercises CX-10
    Then the claim holds byte for byte
