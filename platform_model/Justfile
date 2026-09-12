set shell := ["bash", "-c"]

default:
    @just --list

# Run full non-mutating verification and acceptance gates
vv:
    ./scripts/vv.sh

# Validate claim registers and spec links
validate:
    cargo run --package xtask -- validate

# Check all positive and negative fixture suites
check-fixtures:
    cargo run --package xtask -- check-fixtures

# Rewrite fixture expected outputs
fixtures-write:
    cargo run --package xtask -- check-fixtures --write

# Backward-compatible spelling; the normative rewrite command is fixtures-write.
write-fixtures: fixtures-write

# Verify reproducibility across two distinct build roots
check-reproducibility:
    cargo run --package xtask -- check-reproducibility

# Verify the Cargo-selected package and its downstream public API
package-api:
    cargo run --package xtask -- package-api

# Reproduce the exact prebuilt dependency and stdlib crate archives.
package-release-crates-check:
    ./scripts/package-release-crates.sh --check

# Verify examples and standard library
verify-examples:
    cargo run --package xtask -- verify-examples

# Verify golden outputs
golden-check:
    cargo run --package xtask -- check-golden

# Rewrite committed golden outputs for review. Acceptance never invokes this recipe.
golden-write reason:
    PRISMPM_GOLDEN_REASON='{{reason}}' cargo run --package xtask -- check-golden --write

# Backward-compatible spelling; the normative check command is golden-check.
check-golden: golden-check

# Regenerate model artifacts and documentation
codegen:
    cargo run --package xtask -- validate-model --write

# Check release readiness
release-check:
    cargo run --package xtask -- release-check

# Stage release artifacts
release-artifacts:
    cargo run --package xtask -- release-artifacts
