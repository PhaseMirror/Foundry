Feature: system

  @SY-01 @build
  Scenario: Prism system models cover product, components, interfaces, topology, configuration, data, operations, and lifecycle.
    Given the locked PrismPM production fixture
    When the SY-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SY-02 @build
  Scenario: System validation enforces closure, uniqueness, references, compatibility, capabilities, ordering, and release completeness.
    Given the locked PrismPM production fixture
    When the SY-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SY-03 @build
  Scenario: All Prism system semantics and validators are authored in LexLean and exported only from generated Lean roots.
    Given the locked PrismPM production fixture
    When the SY-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SY-04 @build
  Scenario: System models deterministically project OpenAPI, AsyncAPI, CloudEvents, SPDX, OpenTelemetry, Compose, and Kubernetes inputs.
    Given the locked PrismPM production fixture
    When the SY-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SY-05 @build
  Scenario: Late-bound configuration is typed and secret values remain external references excluded from artifacts and evidence.
    Given the locked PrismPM production fixture
    When the SY-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SY-06 @build
  Scenario: Migrations, recovery, rollout, rollback, drift, retirement, and positive and negative acceptance are explicit modeled values.
    Given the locked PrismPM production fixture
    When the SY-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
