# Changelog

## [0.3.0] - 2026-09-08

- Add the authoritative production-system model, immutable standards/oracle
  bindings, OCI release graphs, digest-only lifecycle controller, Compose and
  Kubernetes target projections, operations/supply-chain evidence, and the
  reproducible PrismPM SDK.
- Release `prism-stdlib` 0.2.0 with generated production-system validation
  support while preserving Holo/1 and the 0.1 application runtime API.
- Correct generated View field layout in `lean4-prod`; Calculator behavior and
  Holo/1 remain compatible.

### Compatibility

Holo/1 and accepted Prism application inputs remain stable. Additive contracts
use new registered schemas; an incompatible schema change requires a new schema
identifier and an explicit migration.

All notable changes to PrismPM will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-08-30

### Added
- Initial UOR-Foundation workspace layout and devcontainer.
- LexLean-authored Prism facet lexicons (`prism.arch`, `prism.sec`, `prism.qual`).
- Formal metamodel in `.lex.tex` defining ISO 42010, ISO 27034, ISO 27005, and ISO 25010 primitives.
- Canonical JSON Holo format (`prismpm/holo/1`) emitter and validator.
- Controller API, CLI commands (`check`, `build`, `verify`), and `vv` acceptance gates.

### Compatibility

- The `/1` project, Holo, build, verification, and evidence schemas are the
  initial stable schemas. An incompatible schema change requires a new schema
  identifier and a SemVer-major PrismPM release; compatible additive behavior
  may not weaken closed-object decoding or existing verification guarantees.
