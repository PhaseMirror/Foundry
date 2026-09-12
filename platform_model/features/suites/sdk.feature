Feature: sdk

  @DK-01 @build
  Scenario: One versioned SDK inventory closes over PrismPM, LexLean, Lean, lean4-prod, stdlib, oracles, adapters, and schemas.
    Given the locked PrismPM production fixture
    When the DK-01 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DK-02 @build
  Scenario: Signed non-root amd64 and arm64 SDK images use digest-pinned bases and carry OCI, SPDX, and provenance evidence.
    Given the locked PrismPM production fixture
    When the DK-02 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DK-03 @build
  Scenario: Native Linux archives and OCI SDK execution produce identical platform-independent outputs and diagnostics.
    Given the locked PrismPM production fixture
    When the DK-03 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DK-04 @build
  Scenario: The complete SDK lock and explicit fetch phase permit all build and verification phases to run locked and offline.
    Given the locked PrismPM production fixture
    When the DK-04 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DK-05 @build
  Scenario: SDK bootstrap uses the prior accepted SDK, two clean self-rebuilds, and independent formal evidence verification without a trust cycle.
    Given the locked PrismPM production fixture
    When the DK-05 contract is exercised
    Then its positive evidence passes and its planted defect is rejected

  @DK-06 @build
  Scenario: SDK execution rejects undeclared PATH tools, tampered executables, base drift, mutable inputs, and circular self-attestation.
    Given the locked PrismPM production fixture
    When the DK-06 contract is exercised
    Then its positive evidence passes and its planted defect is rejected
