Feature: operations

  @OP-01 @build
  Scenario: Modeled OpenTelemetry logs, metrics, traces, resource attributes, and correlation reach an unmodified pinned Collector.
    Given the locked PrismPM production fixture
    When the OP-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OP-02 @build
  Scenario: Startup, readiness, liveness, SLIs, SLOs, alerts, and finite evaluation windows are modeled and measured against exact releases.
    Given the locked PrismPM production fixture
    When the OP-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OP-03 @build
  Scenario: Backup is accepted only with a successful clean-target restore, integrity proof, application acceptance, and measured RPO and RTO.
    Given the locked PrismPM production fixture
    When the OP-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OP-04 @build
  Scenario: Bounded load, dependency, process, network, resource, rollout, credential, telemetry, and registry fault scenarios follow modeled policy.
    Given the locked PrismPM production fixture
    When the OP-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OP-05 @build
  Scenario: Observed deployment, health, drift, recovery, and failure evidence remains distinct from proof and binds the deployed release digest.
    Given the locked PrismPM production fixture
    When the OP-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @OP-06 @build
  Scenario: Sensitive fields, credentials, tokens, operands, history, labels, and secret values are redacted from source-derived and observed evidence.
    Given the locked PrismPM production fixture
    When the OP-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
