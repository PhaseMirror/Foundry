# PrismPM

PrismPM compiles authoritative Prism models into verified software artifacts. A
model is a closed `.lex.tex` source graph: LexLean produces its semantic
snapshot and Lean, Lean checks the proofs, `lean4-prod` exports only named
verified roots, and generic generators produce Cargo, Core-Wasm, View, browser,
and Hologram artifacts. Prism application behavior is never supplied by
handwritten Lean or target-specific application code.

The historical `v0.1.0` release is a systems-modeling prototype and `v0.2.0`
is the completed portable-application line. The production-system SDK is
`v0.3.0`, and it is releasable only when the generated
`prism-stdlib` and `prism-calculator` crates, `Calculator.holo`, the independent
Hologram execution evidence, and the public `calculator-example` Pages
application and complete CalculatorSystem reference all pass the atomic release
contract in [SPEC.md](SPEC.md).

## Artifact model

```text
authoritative .lex.tex + lock
             |
             +-- LexLean snapshot, generated Lean/LaTeX, proof evidence
             +-- lean4-prod LCNF and named-root coverage
             +-- generated Cargo crate and registry package
             +-- import-free hologram:guest/core-wasm@1 guest
             +-- evaluated View -> portable HOLOVIEW + browser adapter/assets
             `-- binary Hologram v4 ApplicationName.holo
```

Holo/1 is the Prism profile defined by `prism-stdlib`; its physical container
is Hologram archive version 4. Every `.holo` begins with `HOLO\x04\x00`.
`model.prism.json` is the separate canonical Prism model document. JSON is
never accepted as a `.holo` archive.

## Calculator: getting started

Open this repository in its VS Code devcontainer. From the container shell:

```sh
cargo run --locked --offline -p prismpm -- \
  --project examples/Calculator check
cargo run --locked --offline -p prismpm -- \
  --project examples/Calculator build
cargo run --locked --offline -p prismpm -- \
  --project examples/Calculator verify
```

The project root is [examples/Calculator](examples/Calculator). Its sole
application authority is `src/Calculator.lex.tex` plus `lexlean.lock`.
Successful verification writes a content-addressed build beneath
`examples/Calculator/.prism/build/` and an acceptance result beneath
`examples/Calculator/.prism/verified/`. The build contains:

- `Calculator.holo`, the composed Core-Wasm plus portable View application;
- `cargo/prism-calculator-0.1.0.crate` and its complete generated package;
- `core-wasm/prism_calculator_core_wasm.wasm`;
- generated Hologram and browser View artifacts; and
- the model, Lean, LCNF, provenance, identity, and manifest evidence.

Inspect and headlessly plan the archive with the pinned Hologram Live binary:

```sh
hologram --json holo inspect path/to/Calculator.holo
hologram --json holo plan path/to/Calculator.holo
```

The ordinary headless plan intentionally reports that the `portable` View
surface is unavailable. `prismpm verify` also builds the pinned independent
Hologram oracle and opens the same archive with a display-independent portable
surface, runs every modeled request directly and through View intents, then
checks detach and idempotent shutdown.

After publication, ordinary Rust consumers use the generated API:

```toml
[dependencies]
prism-calculator = "=0.1.0"
```

```rust
use prism_calculator::{calculate, Operation};

assert_eq!(calculate(Operation::Add, 20, 22), Ok(42));
```

The public reference application is
[`UOR-Foundation/calculator-example`](https://github.com/UOR-Foundation/calculator-example).
It mirrors the exact content-addressed model, reruns PrismPM acceptance, imports
the registry crate, and deploys only the generated six-file browser closure.

## Development and acceptance

The host needs only Git, Docker with Buildx, the Dev Container CLI, and
repository credentials. Rust, Lean, Wasm, Node, browser, and conformance tools
run inside the pinned devcontainers. Dependency acquisition is an explicit
setup phase; build and acceptance are locked and offline afterward.

```sh
just vv
```

`just vv` is the normative repository gate. Application completion is reported
only by `prismpm/application-acceptance/1`, and ecosystem completion additionally
requires the final cross-repository release manifest. See [CONFORMANCE.md](CONFORMANCE.md),
[ERRORS.md](ERRORS.md), and [VERIFICATION.md](VERIFICATION.md).

For a built immutable product release, `prismpm conformance
NAME@sha256:DIGEST` runs the SDK-contained 147-feature and 83-diagnostic corpus
and attaches its digest-bound canonical production-acceptance transcript. The
same command is available through the shared action; it does not rebuild the
release or infer coverage from registry membership.
