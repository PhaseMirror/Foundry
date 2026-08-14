# VALIDATION

How a third party reproduces every claim in this repository, without trusting it.

## The short version

```sh
git clone https://github.com/UOR-Foundation/matmul && cd matmul
just vv
```

`just vv` is the whole normative gate. Everything below explains what it does
and how to check it independently.

## Reproducing the cross-library agreement

`CX-01` .. `CX-04` compare against `ndarray` and `nalgebra`. The resolved
versions are in the committed `Cargo.lock`, because the version of an oracle is
part of the claim made against it.

```sh
cargo test -p uor-matmul-validate --test cross_library -- --nocapture
```

The comparison is byte equality on the output buffer, under
`EncodeMode::Wrapping`, over the whole corpus with **no exempted region**. That
is not a convenience: reduction modulo `2^w` is a ring homomorphism, so reducing
the exact sum once at the end equals reducing at every step, and there is no
depth at which an integer oracle is permitted to differ.

Past the depth where an `i32` accumulator wraps, `ndarray` and `nalgebra` panic
rather than wrap under a debug-assertions build. That is a property of those
crates, not a permitted difference, so the witness for the deep half is
`reference_wrapping_i32` --- a three-loop classical accumulator written
independently in this repository, which the test also proves actually wraps.

## Reproducing the NumPy agreement

`CX-10` is the one oracle outside the Rust ecosystem. Its artifacts are
committed, so the claim reproduces with no Python toolchain:

```sh
cargo test -p uor-matmul-validate --test numpy -- --nocapture
```

To regenerate them from scratch and confirm they were not fabricated:

```sh
pip install numpy && python3 oracles/numpy/generate.py
git diff --stat oracles/numpy/     # must be empty
```

Each artifact's SHA-256 is recorded in `oracles/numpy/manifest.json` and
verified by the test before the bytes are believed.

## Reproducing the float measurements

`CX-05` .. `CX-09` report how far a classical `f32`/`f64` GEMM is from the exact
value, in ulps:

```sh
cargo test -p uor-matmul-validate --test float_oracles -- --nocapture
```

These do **not** assert agreement, and reproducing another library's rounding is
non-goal N1. On the reference run, `matrixmultiply` deviated from the exact
value by up to 139 ulp. That figure describes the oracle, not this library.

## Reproducing the environment claims

```sh
just no-alloc     # CA-03: builds for thumbv7em and wasm32
just cross        # CA-02: the corpus digest, off the host
just checked      # CT-02: every accumulator operation checked
cargo run -p xtask -- audit-disassembly   # CU-01
```

`CA-02` compares against a committed digest constant. Running the same test on
any target must reproduce it; if it does not, either the library's output has
moved or the target disagrees, and both are worth knowing.

## Checking that the gates can fail

The most useful thing a sceptic can do is break something and confirm the suite
notices. `VERIFICATION.md` lists each gate with the defect that was planted to
prove it fires. To repeat one:

```sh
# R2: plant a float add in a shipped crate.
echo 'pub fn probe(x: &[f32]) -> f32 { let mut s = 0.0; for v in x { s += *v; } s }' \
  >> crates/uor-matmul-kernels/src/isa/portable.rs
cargo run -p xtask -- audit-purity    # must fail
git checkout crates/uor-matmul-kernels/src/isa/portable.rs
```

## What reproduction does not establish

The upstream formalization's theorems. Everything here is evidence that the
kernels realize an identity that is stated and proved elsewhere; none of it is a
proof of the identity. `model/authorities.toml` records exactly what is cited
and from where.
