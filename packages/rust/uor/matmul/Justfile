# `just vv` is the normative acceptance gate. Everything else is a slice of it.

default: vv

# The whole gate.
vv: fmt-check model lint test purity no-alloc bdd
    @echo "vv: the acceptance gate passed"

# R1, R2, R8, R10, R11, R13, R15 --- the repository gates, each falsifiable.
model:
    cargo run -q -p xtask -- validate

# Regenerate everything the model owns: the Rust consts and CONFORMANCE.md.
model-write:
    cargo run -q -p xtask -- check-model --write

fmt:
    cargo fmt --all

fmt-check:
    cargo fmt --all -- --check

lint:
    cargo clippy --workspace --all-targets -- -D warnings

test:
    cargo test --workspace

# CT-02: the whole corpus in a build where every accumulator operation is
# checked and any overflow panics. The width is derived so that this is
# unreachable; the profile exists to witness that, not to guard it.
checked:
    cargo test --workspace --profile checked

# R2, R3, R13, and CU-01's disassembly.
purity:
    cargo run -q -p xtask -- audit-purity
    cargo run -q -p xtask -- audit-disassembly

# R7, C1, CA-03: every shipped crate builds for a target with no allocator at
# all. A crate that had picked up an `alloc` dependency cannot link here.
no-alloc:
    cargo build -p uor-matmul --no-default-features --target thumbv7em-none-eabihf
    cargo build -p uor-matmul --no-default-features --target wasm32-unknown-unknown
    cargo build -p uor-matmul --no-default-features --target wasm32-unknown-unknown \
        --config 'build.rustflags=["-C","target-feature=+simd128"]'
    # The NEON kernels compile on no host that can run them, so a break in them
    # would otherwise reach CI before it reached the author. Building here does
    # not exercise them --- the `cross` job does that, natively --- but it does
    # mean the ISA the canonical instantiation cares about most cannot rot.
    cargo check -p uor-matmul --target aarch64-unknown-linux-gnu

# CA-02: the corpus digest is the same on every target.
cross: no-alloc
    cargo test -p uor-matmul-conformance --test environment

# CG-*: scaling is a V&V axis, not a benchmark. Every performance claim is a
# fitted exponent with a confidence interval, against the same fit for the
# oracle. Every figure it prints is `open`.
# `--release` is not optional here. `cargo test` builds at `opt-level = 0`, and a
# throughput figure from an unoptimised build is not a figure --- measured, the
# same shapes read two hundred times slower. The timed tests say so themselves if
# they are run without it.
scaling:
    cargo test --release -p uor-matmul-validate --test scaling_report -- --nocapture
    cargo bench -p uor-matmul-validate

# CG-09: throughput against the degeneracy of the operand, over the large shapes
# `just vv` has no time for. Minutes.
collapse:
    cargo run --release -p uor-matmul-validate --example collapse_sweep

# CT-06, CG-08: super-massive input. Minutes, and gigabytes of operands, so it is
# its own recipe rather than part of `vv`.
massive:
    cargo test --release -p uor-matmul-validate --test massive -- \
        --ignored --nocapture --test-threads=1

# R4's meta-gate: no `open` claim is asserted as established, and no cited
# authority is presented as this repository's own result.
honesty: bdd
    cargo run -q -p xtask -- check-model

# R9: every capability begins as a Gherkin scenario, and every scenario has a
# test whose name ends in its ID.
bdd:
    cargo test -p uor-matmul-conformance

# CT-01, CT-03, CK-06: the fuzz targets. Needs `cargo install cargo-fuzz` and a
# nightly toolchain, which is why it is not part of `just vv`.
fuzz duration="60":
    cargo +nightly fuzz run totality -- -max_total_time={{duration}}
    cargo +nightly fuzz run float_decode -- -max_total_time={{duration}}
    cargo +nightly fuzz run codec_shapes -- -max_total_time={{duration}}

# Regenerate the NumPy oracle artifacts. Run only when the corpus changes; the
# outputs are committed and their digests are recorded.
oracles:
    python3 oracles/numpy/generate.py
