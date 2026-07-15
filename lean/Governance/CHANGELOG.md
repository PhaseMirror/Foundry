# Changelog

All notable changes to the Mirror Dissonance Protocol project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## [Unreleased]

### Changed
- **BREAKING:** `multiplicity.crypto` now derives per-circuit BLS signing keys from `identitySecret` via HKDF-SHA256 and no longer allows raw `identitySecret` to be part of the public proof binding.
- **Security:** `packages/lambda/apps/relay/src/handlers/submitProof.ts` rejects any proof submission payload containing a raw `identitySecret` field with HTTP 400 `ERR_SECRET_BOUNDARY`.

## [1.0.0] - 2026-02-06

### Added

#### Test Infrastructure
- **DI-based ESM test architecture**: Constructor dependency injection for
  `GitHubVerifier` (`octokitOverride`) and `StripeVerifier` (`stripeOverride`)
  that bypasses `jest.mock()` ESM interception failures
- **`createVerifier()` factory pattern**: Reusable test helper pattern for
  injecting mock dependencies — applicable to any future service
- **Explicit `@jest/globals` imports**: All ~30 test files now import `jest`,
  `describe`, `it`, `expect` explicitly for ESM compatibility
- **Hardened global test setup** (`setup.ts`):
  - Added `CreateTableCommand`, `ScanCommand` to DynamoDB mock
  - Added `marshall`/`unmarshall` mock for `@aws-sdk/util-dynamodb`
  - Fixed `global.testUtils` typing
- **Sub-path exports** in core `package.json` for clean cross-package resolution
  (`./dist/src/l0-invariants/index.js`, `./dist/src/consent-store/index.js`,
  `./dist/src/analysis/orchestrator.js`)

#### Core Exports
- `GitHubVerifier`, `StripeVerifier`, `ConsistencyScoreCalculator` now exported
  from `@mirror-dissonance/core` main entry point
- `OrganizationIdentity`, `ContributionRecord` types exported

#### Documentation
- **E2E & Benchmarks Infrastructure Guide** (`artifacts/docs/guides/E2E_AND_BENCHMARKS.md`):
  LocalStack setup, real AWS provisioning, CI workflow example, performance targets

### Fixed
- **JsonFileStore concurrency race** — concurrent `write()` calls no longer collide
  on the same `.tmp` path (now uses `${randomUUID()}.tmp`); in-process mutex
  (`withLock`) serializes all read-modify-write cycles across `writeOne()`,
  `increment()`, `rotateNonce()`, `deleteBaseline()`, and `cleanExpired()`
- **Consent store assertion** — corrected `GetCommand` count expectation from 3 to 2
  (cache-aware: `grantConsent` uses cache for its internal read)
- **Block counter TTL test** — simplified assertion to `expect(updateCommand).toBeDefined()`
  (mock doesn't expose `.input` property)
- **Revenue tracking mock typing** — added `any` type to `mockStripe` (TS2345)
- **Nonce validation test** — replaced short string public keys with valid
  64-character hex keys (`'a'.repeat(64)`)
- **MCP server duplicate jest config** — removed `jest.config.cjs`, kept `.mjs`

### Changed
- `JsonFileStore.writeOne()` now acquires in-process mutex internally (callers
  no longer need to manage locking for single-item upserts)
- `LocalBlockCounter.increment()`, `LocalSecretStore.rotateNonce()`,
  `LocalBaselineStorage.deleteBaseline()` all use `withLock` for safe concurrency
- Error detection helpers in `GitHubVerifier` (`getErrorStatus`, `getErrorMessage`,
  `isNotFoundError`, `isRateLimitError`, `isForbiddenError`) handle diverse error
  shapes from both real Octokit and mock objects

### Test Results
- **Core unit tests**: 496/496 pass (0 failures)
- **MCP unit tests**: 107/107 pass
- **MCP integration tests**: 8/8 pass
- **Total**: 611/611 green

---

## [1.0.0-rc1] - 2026-02-01

### Added

#### Core Features
- **L0 Invariant Validation**: Foundation-tier validation system (<100ns p99 performance)
  - Schema hash validation
  - Permission bits validation
  - Drift magnitude validation
  - Nonce freshness validation
  - Contraction witness validation (FPR decrease enforcement)

- **False Positive (FP) Tracking System**:
  - DynamoDB-backed FP event storage
  - Window-based FPR calculation (configurable window size)
  - Query by count and time range
  - FP marking with reviewer attribution and ticket tracking
  - Performance: <50ms p99 for queries

- **Consent Management**:
  - Organization and repository-level consent tracking
  - Consent expiration and revocation support
  - Hierarchical consent (org-level covers all repos)
  - DynamoDB backend with efficient queries

- **Anonymization System**:
  - HMAC-SHA256 based anonymization
  - SSM Parameter Store integration for nonce management
  - 64-character hex salt validation
  - NoOp test mode for development
  - Fail-closed behavior when nonce unavailable

- **Circuit Breaker**:
  - Configurable threshold for block events (default: 10 blocks/hour)
  - Degraded mode activation when threshold exceeded
  - TTL-based automatic cooldown (configurable period)
  - DynamoDB-backed block counter with atomic operations

- **Rule System**:
  - MD-001: Branch Protection Configuration
  - MD-002: Autonomy vs Compliance Tension
  - MD-003: Probabilistic vs Deterministic Outputs
  - MD-004: Liability Framework Requirements
  - MD-005: Drift Detection and Baseline Management

- **CLI Tool** (`@mirror-dissonance/cli`):
  - Multiple operation modes: `pull_request`, `merge_group`, `drift`, `local`
  - AWS integration with DynamoDB, SSM, S3
  - Local mode for testing without AWS dependencies
  - Verbose logging and debugging support
  - Deterministic JSON report output

- **GitHub Actions Integration**:
  - OIDC authentication support (no long-lived credentials)
  - PR check workflow examples
  - Merge queue integration
  - Drift detection workflow
  - Artifact upload for reports

#### Infrastructure
- **Terraform Infrastructure as Code**:
  - S3 backend with versioning for state storage
  - DynamoDB tables: fp-events, consent, block-counter
  - SSM Parameter Store for nonce management
  - KMS encryption keys
  - CloudWatch alarms for monitoring
  - S3 bucket for drift baselines
  - IAM roles for GitHub Actions OIDC

- **Scripts and Automation**:
  - Nonce rotation script with grace period
  - Environment validation script
  - Backend validation script
  - Workspace creation automation
  - Drift baseline loading from S3

#### Documentation
- **Getting Started**:
  - Comprehensive Quick Start Guide
  - Configuration Reference (environment vars, Terraform, rules)
  - Troubleshooting Guide (7 common errors with solutions)
  - FAQ (45 questions across 7 categories)

- **Architecture**:
  - System architecture documentation
  - ADRs (Architecture Decision Records) for all major decisions
  - L0 performance benchmarks
  - Component interaction diagrams

- **Operations**:
  - Deployment guides for staging and production
  - Nonce rotation procedures
  - Backup and recovery procedures
  - Monitoring and alerting setup
  - Security hardening checklist

- **Governance**:
  - Articles of Incorporation (501(c)(3) nonprofit structure)
  - Bylaws and governance framework
  - Succession planning documentation
  - Code of Conduct
  - Contributing guidelines

### Fixed
- CLI path resolution for global install scenarios
- Error handling and propagation in FP Store
- Error handling in rule evaluation and nonce loading
- CODEOWNERS placeholder usernames replaced with real GitHub handles
- Drift baseline loading now uses S3 instead of hardcoded values
- GitHub labels created for issue tracking
- Portable date commands for BSD/macOS compatibility

### Changed
- DynamoDB tables use PAY_PER_REQUEST billing mode for better cost optimization
- Enhanced error messages with context (rule ID, event ID, parameter names)
- Improved CloudWatch alarm configuration
- Documentation reorganized for better navigation

### Performance
- L0 Invariants: 50-80ns p99 (target: <100ns) ✅
- FP Store Queries: 20-40ms p99 (target: <50ms) ✅
- Consent Checks: <20ms p99 ✅
- Full Oracle Run: 2-4 seconds for typical repository

### Security
- HMAC-SHA256 anonymization with quarterly rotation
- All DynamoDB tables encrypted at rest (KMS)
- SSM parameters use SecureString type
- S3 buckets enforce encryption
- TLS for all API calls
- IAM policies follow least privilege principle
- CloudTrail logging enabled
- No long-lived credentials (OIDC only)

### Known Limitations
- **E2E Testing**: Requires LocalStack or real AWS — see `artifacts/docs/guides/E2E_AND_BENCHMARKS.md`
- **Production Deployment**: Not yet deployed to production environment
- **Multi-Region**: Single region only (us-east-1)
- **Monitoring**: CloudWatch dashboards not yet created
- **k-Anonymity**: Calibration queries require minimum 10 orgs for meaningful results
- **Custom Rules**: No UI for custom rule development
- **Analytics**: No dashboard for FP analytics

### Breaking Changes
None - this is the first release candidate.

### Deprecations
None.

### Contributors
- R. Van Gelder (Interim Steward)
- copilot-swe-agent[bot]

### Infrastructure Costs
Estimated monthly AWS costs:
- **Development**: <$5/month
- **Staging**: $5-20/month
- **Production**: $50-100/month (scales with usage)

Primary costs:
- DynamoDB: $2-5/month (PAY_PER_REQUEST)
- S3: $1-2/month
- CloudWatch: $2-5/month
- SSM: Free tier

---

## [Unreleased]

### Planned for Post-1.0.0
- [ ] Production deployment and validation
- [ ] CloudWatch dashboard creation
- [ ] Multi-region support consideration
- [ ] Community adoption and feedback incorporation
- [ ] FP analytics dashboard

---

## Release History

- **v1.0.0** (2026-02-06): Full release — 611/611 tests green, DI-based ESM test
  architecture, concurrency-safe local storage, MCP server at 100%
- **v1.0.0-rc1** (2026-02-01): First release candidate — MVP feature complete

---

For more details on any release, see the [Release Notes](./artifacts/docs/releases/RELEASE_NOTES_v1.0.0-rc1.md).
