# Changelog

All notable changes to the SpiralCore formalization are recorded here.

## [Unreleased]

### Added (ADR-0030..0043 implementation)

- **ADR-0030 (Feynman path)** — `SpiralCore/FeynmanPath.lean` and Rust `feynman_path`:
  path count, equal unit amplitudes, total-amplitude identity, and the fail-closed
  fidelity gate with in-tolerance/out-of-tolerance acceptance proofs.
- **ADR-0031 (Canopies)** — `SpiralCore/PersistenceCanopies.lean` and Rust
  `persistence_canopies`: augmented/diminished diagram predicates, diagonal split,
  pairing-count identity, and order-compatibility checks.
- **ADR-0032 (R2 subset selection)** — `SpiralCore/SubsetSelection.lean` and Rust
  `subset_selection`: weighted Tchebycheff loss bounds, triangular feasibility,
  and Monge (constant + additive-separable) certificates.
- **ADR-0033 (Fisher geometric sharpness)** — `SpiralCore/FisherSharpness.lean`
  and Rust `fisher_sharpness`: FIM symmetry/PSD certificate, stationary-mass
  monotonicity, admissible flatness metrics.
- **ADR-0034 (GK-Mapper)** — `SpiralCore/GkMapper.lean` and Rust `gk_mapper`:
  fuzzifier domain (>1), membership overlap bound and commutativity, edge
  threshold, symmetric ellipsoidal distance.
- **ADR-0035 (Hodge spectral surrogates)** — `SpiralCore/HodgeSurrogates.lean`
  and Rust `hodge_surrogates`: boundary B² lowering, zero-modes=Betti, hard-limit
  kernel preservation.
- **ADR-0036 (Vertex-guard policy)** — `SpiralCore/VertexGuard.lean` and Rust
  `vertex_guard`: coverage feasibility, under-coverage escalation, reward bounds.
- **ADR-0037 (Geometric trees)** — `SpiralCore/GeometricTrees.lean` and Rust
  `geometric_trees`: quadratic-form symmetry, diagonal-dominance PSD certificate,
  simplex normalization.
- **ADR-0038 (SpiralCore v13)** — `SpiralCore/SpiralcoreV13.lean` and Rust
  `spiralcore_v13`: v13 constants (dim 81, L0 floor 83, fractal offset 26),
  bifurcation pair (27,28), Collatz escape, MOD-gate locks.
- **ADR-0039 (v13 Python test suite)** — `SpiralCore/SpiralcoreV13Test.lean`:
  black-box runtime gates matching the reference Python assertions.
- **ADR-0041 (Morse transform)** — `SpiralCore/MorseTransform.lean` and Rust
  `morse_transform`: reduced-Betti critical-type classification (peak/trough/
  saddle), vectorization independence.
- **ADR-0042 (V4P-VSAM)** — `SpiralCore/V4pVsam.lean` and Rust `v4p_vsam`:
  octet domain, nibble split/recombine round-trip, no-permission-by-address,
  conflict policy.
- **ADR-0043 (WADA-LADA)** — `SpiralCore/WadaLada.lean` and Rust `wada_lada`:
  fail-closed drop decision (self-in-path, TTL, signature, basis, policy, class),
  root hysteresis, manual-override health requirements, worker authorization.
- **Rust/Kani** — engine modules appended to `rust/src/lib.rs`; 40 new harnesses
  added to `rust/tests/kani_verify.rs` (67 total).
- **Docs** — ADR-0030..0043 promoted from `Proposed` to `Accepted`; front-matter
  `lean_module` pointers corrected to the `SpiralCore.*` modules; README structure
  extended.

### Fixed

- `rust/Cargo.toml`: removed broken kani path dev-dependency so `cargo test` and
  `cargo kani` resolve against the installed `cargo-kani`.
