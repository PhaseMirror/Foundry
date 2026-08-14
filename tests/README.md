# Prime / Tests

This directory contains the integration and unit testing framework for the Prime Materia Commons.

## Overview

The test suites here validate the Rust engine, the Lean 4 integration, and the system's resilience against bypass and drift.

### Key Components

- **Integration Tests:** `lean_integration.rs` verifies the boundary between the Rust engine and the Lean 4 formalizations, ensuring that the theoretical guarantees are upheld at runtime.
- **Serialization & Fuzzing:** `serialization_tests.rs` ensures stable round-trip data encoding.
- **Regression Testing:** `c4_regression.py` serves as a regression harness.
- **Fixtures:** `fixtures/` contains mock data and state files used during tests.

### Running Tests

All tests can be executed via the standard cargo command:
```bash
cargo test
```

To run the specific governance test suite mandated by the CFP:
```bash
cargo test --test governance
```

All CI pipelines must pass these tests before any code is merged into the `Prime` core.
