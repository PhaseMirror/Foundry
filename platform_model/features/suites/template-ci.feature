Feature: template-ci

  @TM-01 @build
  Scenario: The versioned UOR template contract preserves repository honesty, anti-vacuity, generated registers, and planted-defect policy.
    Given the locked PrismPM production fixture
    When the TM-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @TM-02 @build
  Scenario: Template-derived devcontainers consume the exact signed SDK manifest digest with no floating feature, installer, action, or host-tool fallback.
    Given the locked PrismPM production fixture
    When the TM-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @TM-03 @build
  Scenario: Full-SHA-pinned actions and reusable workflows invoke the same SDK digest and CLI and return declared release, plan, and evidence digests.
    Given the locked PrismPM production fixture
    When the TM-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @TM-04 @build
  Scenario: Least-privilege jobs build once and pass the exact digest through protected signing, publication, deployment, and verification boundaries.
    Given the locked PrismPM production fixture
    When the TM-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @TM-05 @build
  Scenario: Template checks are read-only and explicit updates produce reviewable downstream patches or pull requests without hidden branch mutation.
    Given the locked PrismPM production fixture
    When the TM-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @TM-06 @build
  Scenario: All in-scope UOR and Prism repositories use the common SDK bootstrap while preserving their repository-specific acceptance gates.
    Given the locked PrismPM production fixture
    When the TM-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
