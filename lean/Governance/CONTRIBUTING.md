# Contributing to Phase Mirror

Thank you for your interest in contributing to the Phase Mirror project! The Mirror Dissonance Protocol is a community-governed project under the stewardship of **Citizen Gardens Foundation**, a 501(c)(3) nonprofit.

This document explains how to participate, what's expected, and how decisions are made.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How to Contribute](#how-to-contribute)
3. [Reporting Bugs](#reporting-bugs)
4. [Proposing New Rules](#proposing-new-rules)
5. [Development Process](#development-process)
6. [Proposing Protocol Changes (MIP)](#proposing-protocol-changes-mip)
7. [Code Contributions](#code-contributions)
8. [Review Process](#review-process)
9. [Community Roles](#community-roles)
10. [Governance](#governance)
11. [Getting Help](#getting-help)

---

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. All participants are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

Violations: Report to [conduct@citizengardens.org](mailto:conduct@citizengardens.org).

---

## How to Contribute

There are several ways to contribute:

### 1. Report Bugs
Found a problem? [Open a bug report](https://github.com/citizen-gardens/phase-mirror/issues/new?template=bug_report.md).

### 2. Propose New Rules
Have an idea for detecting a new class of inconsistency? [Open a rule request](https://github.com/citizen-gardens/phase-mirror/issues/new?template=rule_request.md).

### 3. Improve Documentation
See a typo or unclear explanation? Submit a pull request to `/docs/`.

### 4. Contribute Code
Want to fix a bug or implement a feature? Follow the [Development Process](#development-process) and [Code Contributions](#code-contributions) workflow.

### 5. Participate in Discussions
Join the conversation in [GitHub Discussions](https://github.com/citizen-gardens/phase-mirror/discussions).

---

## Reporting Bugs

**Before reporting:**
1. Check [existing issues](https://github.com/citizen-gardens/phase-mirror/issues) to avoid duplicates.
2. Verify you're using the latest version.
3. Reproduce the bug in a minimal test case.

**When reporting, include:**
- Summary, Steps to Reproduce, Expected vs Actual Behavior, Environment, and Logs.
- Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).

---

## Proposing New Rules

Rules are the heart of the protocol. We welcome proposals, but they require:
1. **Clear specification** - What does the rule detect?
2. **Rationale** - Why is this valuable?
3. **Test cases** - Examples of true positives and false positives.
4. **Performance impact** - How much compute does it require?

**Process:**
1. Open a [Rule Request issue](https://github.com/citizen-gardens/phase-mirror/issues/new?template=rule_request.md).
2. Await community feedback (30-day comment period).
3. Implementation can be done by proposer or maintainer after approval.

---

## Development Process

### Branch Strategy and Commit Discipline

Phase Mirror follows a **point-by-point commit, phase-level PR** strategy. This approach provides:
- Clean `git bisect` history with atomic, verifiable commits.
- Reviewable narratives through coherent phase-level PRs.
- Clear architectural stories that map to project blueprints.

**📖 See [artifacts/docs/BRANCH_STRATEGY.md](artifacts/docs/BRANCH_STRATEGY.md) for complete guidelines.**  
**📖 See [artifacts/docs/COMMIT_DISCIPLINE.md](artifacts/docs/COMMIT_DISCIPLINE.md) for commit workflow.**

#### The Golden Rule
**Write the commit message before you write the code.** The message defines your scope boundary.

#### Phase Branches
Major work is organized into phase branches with multiple atomic commits:
- `fix/known-issues` - Phase 0: Critical error handling fixes
- `refactor/adapter-layer` - Phase 1: Cloud-agnostic abstraction
- `test/unit-coverage` - Phase 2: 80% test coverage
- `test/integration` - Phase 3: Integration test suite
- `docs/spec-documents` - Phase 4: Formal specifications
- `infra/staging-deploy` - Phase 5: Production infrastructure

---

## Proposing Protocol Changes (MIP)

Major changes to the protocol (architecture, licensing, governance) require a **Multiplicity Improvement Proposal (MIP)**.

**What requires an MIP:**
- Changes to L0/L1/L2 compute model.
- Changes to licensing or trademark policy.
- Changes to k-anonymity threshold.
- Changes to governance process.

**MIP Process:**
1. **Draft:** Author writes MIP using [template](docs/governance/mip-template.md).
2. **Public Comment (30 days):** Publish to GitHub Discussions.
3. **Vote (5 days):** Lead Architect + Certification Committee vote (2/3 majority required).
4. **Publication:** Approved MIPs are merged to `/docs/adr/` as Architecture Decision Records (ADRs).

See [MIP Process details](docs/adr/MIP_PROCESS.md) and the [MIP Index](docs/governance/mip-index.md).

---

## Code Contributions

### 1. Create a Branch
```bash
git checkout -b fix/my-bug-fix
# or
git checkout -b feat/my-new-feature
```

### 2. Make Changes
- Add tests (required for new features and bug fixes).
- Run tests: `pnpm test`.
- Run linter: `pnpm lint`.

### 3. Commit
Use [Conventional Commits](https://www.conventionalcommits.org/):
```bash
git commit -m "fix: handle special characters in orgid validation"
```

### 4. Push and Open PR
Open a Pull Request with a clear description, motivation, and testing checklist.

---

## Community Roles

### 1. Contributor
Anyone who submits an issue, comment, or PR.

### 2. Maintainer
Trusted contributors with write access to the repository.
- **Responsibilities:** Review PRs within 7 days, triage issues, participates in MIP votes.
- **Requirement:** 10+ meaningful contributions and deep protocol understanding.
- See [MAINTAINERS.md](MAINTAINERS.md) for current list.

### 3. Domain Expert (Certification Committee)
Subject matter experts who vote on MIPs and rule proposals.
- **Responsibilities:** Binding vote on MIPs, review rule proposals, technical guidance.
- See [GOVERNANCE.md](docs/governance/GOVERNANCE.md) for details.

### 4. Lead Architect
Technical authority for the protocol.
- **Responsibilities:** Final decision on architecture, break ties on MIP votes, appoint domain experts.
- **Current Lead Architect:** RyVanGyver (@RyVanGyver).

---

## Governance

### Decision-Making Process
- **Level 1: Day-to-Day:** Bug fixes, documentation, approval via maintainer review.
- **Level 2: Protocol Changes:** MIP required, 30-day comment + 5-day vote.
- **Level 3: Foundation Governance:** Board vote required for Bylaws or budget.

### Transparency
All governance decisions are documented in ADRs (`/docs/adr/`), board minutes (`/docs/governance/`), and GitHub Discussions.

### Escalation Path
1. **Maintainer:** GitHub Discussions / tag @maintainers.
2. **Lead Architect:** [architect@citizengardens.org](mailto:architect@citizengardens.org).
3. **Board of Directors:** [board@citizengardens.org](mailto:board@citizengardens.org).
4. **Independent Compliance Officer:** [conduct@citizengardens.org](mailto:conduct@citizengardens.org).

---

## Getting Help

- **Documentation:** [docs/](docs/)
- **GitHub Discussions:** [Ask questions](https://github.com/citizen-gardens/phase-mirror/discussions)
- **Email Support:** [support@citizengardens.org](mailto:support@citizengardens.org)

---

## License

By contributing, you agree that your contributions will be licensed under the [Apache 2.0 with Managed Service Restriction](LICENSE). Documentation is licensed under CC BY 4.0.
