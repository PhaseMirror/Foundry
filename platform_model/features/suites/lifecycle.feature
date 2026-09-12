Feature: lifecycle

  @LC-01 @build
  Scenario: The Controller owns fetch, build, push, pull, inspect, run, plan, deploy, status, rollback, and explicit destroy operations.
    Given the locked PrismPM production fixture
    When the LC-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @LC-02 @build
  Scenario: Build, push, run, and deploy accept Docker-simple command forms and return stable pipe-safe canonical result values.
    Given the locked PrismPM production fixture
    When the LC-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @LC-03 @build
  Scenario: Local run uses unmodified OCI, container, Compose, and Hologram runtimes with modeled isolation, readiness, acceptance, signals, and shutdown.
    Given the locked PrismPM production fixture
    When the LC-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @LC-04 @build
  Scenario: Controller operations are bounded, cancellable, atomic, concurrent-safe, path-confined, and idempotent where declared.
    Given the locked PrismPM production fixture
    When the LC-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @LC-05 @build
  Scenario: All caller-controlled failure boundaries return registered diagnostics in stable public exit classes without panic.
    Given the locked PrismPM production fixture
    When the LC-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @LC-06 @build
  Scenario: Generated help and shell completions describe only executable command-contract examples verified in the SDK devcontainer.
    Given the locked PrismPM production fixture
    When the LC-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
