Feature: supply-chain

  @SC-01 @build
  Scenario: SPDX 3.0.1 BOMs close over SDK, build, oracle, adapter, application, and runtime dependencies and match OCI closure.
    Given the locked PrismPM production fixture
    When the SC-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SC-02 @build
  Scenario: in-toto Statement v1 and SLSA 1.2 provenance bind subjects, builders, sources, parameters, dependencies, and objectively supported build level.
    Given the locked PrismPM production fixture
    When the SC-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SC-03 @build
  Scenario: Sigstore verification enforces exact trusted issuer, subject, repository, workflow, ref, environment, certificate, and transparency policy.
    Given the locked PrismPM production fixture
    When the SC-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SC-04 @build
  Scenario: Vulnerability and license results identify their immutable inputs and freshness and stale evidence cannot satisfy current policy.
    Given the locked PrismPM production fixture
    When the SC-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SC-05 @build
  Scenario: Source, locks, artifacts, plans, OCI content, BOMs, attestations, logs, and evidence are verified free of secret values.
    Given the locked PrismPM production fixture
    When the SC-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @SC-06 @build
  Scenario: Supply-chain policy rejects wrong subjects or builders, incomplete graphs, tampering, unsigned promotion, and unsupported claims.
    Given the locked PrismPM production fixture
    When the SC-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
