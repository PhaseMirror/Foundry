Feature: Scaling

  Fitted exponents. Measured and reported, never asserted.

  Every scenario below names the conformance ID it discharges, and a test
  whose name ends in that ID runs it. `cargo xtask check-model` fails if an
  ID here has no register row, or a register row has no scenario (CM-02).

  @CG-01 @open
  Scenario: Arithmetic scaling exponent, this library and every oracle
    Given the standing sweep and its recorded seed
    When the harness measures CG-01
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-02 @open
  Scenario: Per-axis scaling exponents for `m`, `n`, `k` separately
    Given the standing sweep and its recorded seed
    When the harness measures CG-02
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-03 @open
  Scenario: Residency scaling: bytes of weight storage touched, per codec, against every oracle
    Given the standing sweep and its recorded seed
    When the harness measures CG-03
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-04 @open
  Scenario: Working-set scaling, `suggested_scratch` against each oracle's measured internal allocation
    Given the standing sweep and its recorded seed
    When the harness measures CG-04
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-05 @open
  Scenario: Allocation count and peak bytes: zero here, whatever the oracle does there
    Given the standing sweep and its recorded seed
    When the harness measures CG-05
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-06 @open
  Scenario: Parallel speedup against tile count, with byte-equality asserted inside the timed harness
    Given the standing sweep and its recorded seed
    When the harness measures CG-06
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-07 @open
  Scenario: Small-shape latency, where a heavyweight prologue costs more than an asymptote
    Given the standing sweep and its recorded seed
    When the harness measures CG-07
    Then the figure is reported with its confidence interval
    And nothing asserts it as established

  @CG-08 @open
  Scenario: Sustained throughput on super-massive input, reported per pass, against every oracle that finishes
    Given the standing corpus
    When the suite exercises CG-08
    Then the figure is reported and not asserted

  @CG-09 @open
  Scenario: Throughput against the degeneracy of the operand, including the price of looking when there is none
    Given the standing corpus
    When the suite exercises CG-09
    Then the figure is reported and not asserted
