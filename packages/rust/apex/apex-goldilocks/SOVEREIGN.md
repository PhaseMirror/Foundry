# SOVEREIGN BY DESIGN

The system is designed to run, verify, and persist its core state on user-controlled infrastructure by default. Remote services are optional adapters, not the source of truth. The purpose of this covenant is to preserve operational independence, protect user autonomy, and keep the chain of custody inside the verified boundary of the system.

## Core Commitments

### Local First

Local computation is the default.
Local storage is the default.
Local verification is the default.

A feature may use a remote service only when the local boundary cannot satisfy a clearly stated requirement. Even then, the remote path must remain optional, explicit, and removable.

### Non-Surveillance

The system does not exist to observe users.

We do not collect behavioral telemetry by default.
We do not build hidden analytics pipelines.
We do not ship background tracking, silent identifiers, or undeclared data exports.

Any telemetry that exists must be minimal, documented, and justified by an operational need that cannot be satisfied locally.

### Data Minimization

We collect only what is strictly necessary for the declared purpose.

If a field, event, or log line is not required for operation, recovery, verification, or user-visible function, it does not belong in the default data path.

Data retention is limited to the shortest period compatible with the system’s explicit recovery and audit requirements.

### User Control

The user controls their data, state, and execution environment.

Defaults must preserve privacy and local autonomy.
Opt-in features must be clearly labeled.
Opt-out must be meaningful.
Deletion, export, and inspection must be possible where technically feasible.

### Transparency

Behavior must be inspectable.
Configuration must be visible.
Data flows must be explainable.

No hidden channels, no undisclosed sinks, no silent policy shifts.

## What We Reject

We reject surveillance as a product strategy.
We reject compliance theater that substitutes paperwork for control.
We reject vendor lock-in as an architecture.
We reject systems that require trust in remote policy layers to function safely.

We do not reject responsibility.
We do not reject security.
We do not reject legal obligations.
We reject architectures that treat compliance as a reason to centralize control over the user.

## Boundary Rules

### Source of Truth

The local repository, local ledger, and local cryptographic keys are the primary source of truth.

If a remote service disagrees with local verified state, local verified state wins.

### Remote Services

Remote services are allowed only as adapters, mirrors, or optional collaborators.

Remote services must not:
- Become required for basic operation.
- Receive unnecessary user data.
- Hold unilateral authority over verification, recovery, or policy.
- Override local governance without an explicit, reviewed rule.

### Telemetry

Telemetry is disabled unless explicitly enabled.
Telemetry payloads must be bounded, documented, and purpose-limited.
Telemetry must not include secrets, stable device identifiers, or behavioral traces unless a feature cannot function without them and the user has been informed.

### Logs

Logs are operational records, not behavioral exhaust streams.

Logs must be minimized, redacted where necessary, and retained only as long as needed for recovery, debugging, or verified audit.

## Exceptions

Any exception to this covenant must be explicit.

An exception requires:
- A reason.
- A scope.
- A duration.
- An owner.
- A rollback path.

Exceptions are temporary by default.
Exceptions do not change the covenant.
Exceptions must be documented in an ADR or comparable governance artifact.

## Enforcement

This covenant is enforced by architecture, not by aspiration.

Enforcement mechanisms include:
- Local-first defaults in runtime and UI.
- Fail-closed behavior when privacy or custody invariants are violated.
- Build-time checks for unintended network access.
- Configuration review for data egress.
- Explicit review for any third-party integration.
- Separation between transport adapters and semantic authority.

If a feature cannot satisfy these rules, the feature does not ship in the default build.

## Relationship to Compliance

Compliance is a constraint, not a worldview.

Where external compliance obligations apply, the system should meet them through minimal, local, and auditable mechanisms whenever possible. But this covenant does not treat regulatory conformity as equivalent to user sovereignty, and it does not permit compliance tooling to become a surveillance layer.

## Maintenance

This document is part of the design contract of the project.

Any change to this covenant requires review with the same seriousness as a protocol or schema change.

If the implementation diverges from this covenant, the implementation is wrong, even if it is convenient.

## Ratification

This covenant affirms:
- Local first over remote dependence.
- User control over passive observation.
- Minimal data over maximal collection.
- Transparent operation over hidden instrumentation.
- Sovereign custody over external policy drift.
