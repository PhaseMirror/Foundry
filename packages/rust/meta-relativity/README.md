# Meta-Relativity (MR)

Meta-Relativity (MR) is a mathematically rigorous, auditable framework for modeling
complex physical and computational systems. It is based on prime-gated modeling, frame
relativity, and recursive evolution, ensuring stability and predictability through formal
certification.

This package carries the **Rust implementation** and the research/ADR trail of the
framework. The **production Lean 4 formal model** for the current freeze
(**ADR-0112 / "Meta-Relativity F1"**, internal formal id `ADR-0070`) lives in the Foundry
root (`ADR/MetaRelativity.lean`) and is verified by the repository-wide formal harness
(`lake test`). This README documents both, including the **latest verified test result**.

## Layout

```
packages/rust/meta-relativity/
├── README.md                        # ← this file
├── Cargo.toml                       # crate manifest (1.0.0-alpha)
├── Meta-Relativity_Specification.md # PhaseSpace ensemble-metrics contract
├── Adapter_Fidelity_Report.md       # substrate rooting/phase-boundary attestation
├── docs/
│   ├── adr/                         # ADR-090..ADR-104 + roadmap (crate implementation ADRs)
│   ├── research/                    # research corpus (primes, spin foam, number theory, dynamics)
│   ├── old/                         # retired phase ADRs (ADR-088..ADR-095)
│   ├── meta-relativity.tex          # LaTeX formal-spec draft
│   ├── references.bib
│   └── timewheel_example.png
├── formal/                          # DEPRECATED Lean formalization (see its README)
│   └── MetaRelativityFormalized/    #   replaced by ADR/MetaRelativity.lean in Foundry root
├── src/                             # Rust implementation
│   ├── lib.rs
│   ├── axioms.rs                    # prime-gated axioms (Axiom AP, lattice, norm S₀)
│   ├── space.rs                     # prime frame space ℓ²(𝔓) ⊗ L²(ℝ) ⊗ ℂᵈ (SpaceFrame)
│   ├── operators.rs                 # operator stack 𝒰 = A + B + E (UniversalOperator)
│   ├── invariants.rs                # invariant checks
│   ├── certification.rs             # GapLB / SlopeUB certification gate
│   ├── dissipative.rs               # dissipative regimes, triple-lock iteration
│   ├── security.rs                  # containment authorization
│   ├── exemplars.rs                 # concrete exemplar runs
│   ├── gates.rs                     # infrastructure gates
│   ├── unbounded.rs                 # unbounded-extension scaffolding
│   └── triple_lock.rs               # triple-lock feature (archivum-linked)
└── tests/
    └── integration.rs               # ADR-099-based end-to-end certification workflow
```

### Legend

| Path | Purpose |
| :--- | :--- |
| `src/axioms.rs` | Encodes the core MR axioms (operator-norm discipline, prime labelling). |
| `src/space.rs` | `SpaceFrame`: the prime-gated Hilbert space and frame decomposition. |
| `src/operators.rs` | `UniversalOperator::assemble` — folds the prime block, time sieve, and internal block into 𝒰 = A + B + E. |
| `src/certification.rs` | `certify_operator` — GapLB/SlopeUB certificate decision (mirrors the Lean Stage-1 rule). |
| `src/dissipative.rs` | Contractivity analysis and dissipation regimes. |
| `src/security.rs` | Root execution-boundary containment. |
| `src/exemplars.rs` | Full-stack demonstration runs. |
| `src/triple_lock.rs` | Optional `triple-lock` feature combining contractivity, archive, and audit gates. |
| `formal/` | **Deprecated** Lean 4 formalization (23 unsound axioms). Retained for history only; see `formal/README.md`. |
| `docs/adr/` | Design record trail for the Rust implementation (ADR-090..ADR-104). |

---

## ADR-0112 / ADR-0070 "Meta-Relativity F1" — Formal Verification Result

The current governing architecture state is recorded in
`docs/adr/completed/ADR-0112-Meta-Relativity F1.md`. Its **zero-sorry Lean 4 formal model**
is `ADR/MetaRelativity.lean` in the Foundry root (namespace `ADR.MetaRelativity`), with the
formal ADR record transcribed as `ADR_0070`.

### Executed on

| Item | Value |
| :--- | :--- |
| Date | 2026-09-16 |
| Command | `lake test` (Foundry root) |
| Driver | `lean_exe adrTest` (root `ADR.Test`, see `lakefile.lean`) |
| Toolchain | `leanprover/lean4:v4.34.0-rc2` (see `lean-toolchain`) |
| Exit status | **PASS — all proofs checked and tests passed successfully** |

### Verified checks (grouped)

**1. Stage-1 certificate rule** (`η < 1` passes, `η ≥ 1` rejects):

```
Checking ADR-0070 Stage-1 certificate rule (declare (α,σ,η,P), η < 1 passes, η ≥ 1 rejects)...
  ✓ operator-norm budget lock: ‖B‖ + ‖E‖ = η·p_max^(-σ) exactly (B:E = 1:1 split).
  ✓ GapLB arithmetic: η=0.5 gives (1−η)·floor = 0.0508; η=1.0/1.1 collapse to 0.
  ✓ pass ⇔ η < 1; reject ⇔ η ≥ 1 (rejection is conservative, never indefiniteness).
  ✓ all nine η < 1 cells of the Stage-1 table (σ = 0.5/1.0/1.5 × η = 0.25/0.5/0.75) pass.
  ✓ observed λ_min(U) covers GapLB in every pass cell (the bound is not vacuous).
  ✓ Stage-1 table locked. Stop rule armed: If the Stage-1 table ever breaks, stop: the branch or the weight is wrong.
  ✓ reject ≠ indefinite: some rejected cell still has λ_min(U) = 0.061 > 0.
  ✓ any pass cell forces η < 1 (the gate is strict, not vacuous).
```

**2. Fold-K correction and P-scale stability**:

```
Checking ADR-0070 fold-K correction and P-scale stability...
  ✓ ‖K‖₂ data recorded: 0.163 (α = 1.5), 0.381 (α = 1.0).
  ✓ separate-‖K‖ form is vacuous: ‖K‖₂ > floor ⇒ triangle bound collapses to 0.
  ✓ λ_min(A) = floor − floor/1000 in every row (A = D_σ + K, part-in-10³ support).
  ✓ P-scale (α,σ,η) = (1.5,0.5,0.5): passes at P = 25/50/100 with λ_min(U) ≥ GapLB.
  ✓ the floor falls as p_max^(-σ) while ‖K‖₂ stays frozen at 0.163 (fold-K must stay).
```

**3. Sharp Weyl: bottom vs spread, and the three named windows**:

```
Checking ADR-0070 sharp Weyl bottom/spread separation and the paper cap...
  ✓ sharp certificate: η_B < 1 certifies the bottom; η_B ≥ 1 rejects exactly.
  ✓ PSD E-block: λ_min(E) = 0 drops the E-norm out of the sharp bound.
  ✓ two constraints decoupled: λ_min(Ξ) = 0 (bottom fine) while ‖Ξ‖₂ > 1 (cap violated).
  ✓ reject ≠ indefinite survives the sharp certificate (cell with GapLB = 0, λ_min > 0).
  ✓ three windows named: MR-written and sharp+cap reject raw H; sharp-cap-off is a different object with no essential-spectrum inheritance.
  ✓ lift is normalization-only: hard truncation vacuous (γ₁ ≈ 14.13 > 1).
```

**4. Boundary not-list, composition gate, SFPT discipline**:

```
Checking ADR-0070 boundary not-list, composition gate, and SFPT discipline...
  ✓ composition gate closed: no explicit h = φ·Reζ(½+i·) with HS/sign checks, so no composition.
  ✓ Section 9 typing does not license τ(היה) = 𝒰: operatorRep is constant none.
  ✓ boundary not-list (6): not RH, not Hilbert–Pólya, not det_reg, not SR, not finite Arakelov–Hodge, not a τ-license.
  ✓ SFPT: Δ_V = |C_expl − ∫W·arg ζ| is the only SBM object; Δ_{N,T} is a Hadamard-tail diagnostic.
  ✓ forbidden-set discipline: Δ_{N,T} is never zero-free evidence, never scanned to b = 1/2.
  ✓ Stage 2 (b ∈ (1/2,1)) and Stage 3 (scan to 1/2) are not run.
  ✓ corrections attached: g(z) uses c² − (z−b)²; C_expl(½;3/2,7/2) = (π/20)·log(18π²/245).
```

**5. Consequence entailment (decision/context → consequences, machine-checked)**:

```
Checking ADR-0070 consequences as logical entailments of decision+context...
  ✓ consequence entailed: certified MR core.
  ✓ consequence entailed: Stage-1 declare rule (η < 1 pass / η ≥ 1 reject).
  ✓ consequence entailed: operator-norm budget lock.
  ✓ consequence entailed: fold K into A (separate ‖K‖ form never certified).
  ✓ consequence entailed: sharp Weyl separates bottom from spread.
  ✓ consequence entailed: MR-written cap stays on.
  ✓ consequence entailed: no composition without the explicit map.
  ✓ consequence entailed (context): not-RH boundary.
  ✓ consequence entailed (context): primes are data and the inequality is analysis.
  ✓ consequence entailed (context): SFPT discipline (Δ_{N,T} never zero-free evidence).
  ✓ consequence entailed: rejection is conservative — reject ≠ indefinite (modus ponens).
  ✓ consequence entailed: folding ⇒ K-separation vacuous (modus ponens).
```

**6. Registry invariants** (uniqueIds, acyclic, supersedesExist, supersededStatusConsistent,
noConflicts, traceability, immutability):

```
Checking ADR-0070 registry invariants (uniqueIds, acyclic, supersession, traceability)...
  ✓ ADR-0070 registry satisfies uniqueIds, acyclic, supersedesExist, supersededStatusConsistent, noConflicts.
  ✓ ADR-0070 possesses a reconstructible provenance path (traceability).
  ✓ ADR-0070 cannot revert to Proposed (immutability of accepted decisions).
```

> The suite runs as part of the full `adrTest` harness alongside the Prism, Archivum,
> OSCAL and textual-typing suites. The terminal line of the harness is
> `All proofs checked and tests passed successfully.`

### How to reproduce

```bash
# from the Foundry workspace root
lake test            # builds the ADR library + adrTest executable and runs every proof suite
lake build           # build-only (compiles ADR/MetaRelativity.lean among others)
```

Both `lake build && lake test` exit 0 on the verified state.

---

## Rust implementation

The crate mirrors the MR module structure
(`axioms`, `space`, `operators`, `invariants`, `certification`, `dissipative`,
`security`, `exemplars`, `gates`, `unbounded`) and exposes an ADR-099-style integration
test (`tests/integration.rs`) that assembles 𝒰 = A + B + E from a `PrimeBlock`,
`TimeSieve`, and `InternalBlock`, then runs the `certify_operator` workflow.

### Workspace note (known caveat)

`meta-relativity` is **not** currently listed in the Foundry root `Cargo.toml`
`[workspace.members]`, so an in-place `cargo test` fails with:

```
current package believes it's in a workspace when it's not:
  .../packages/rust/meta-relativity/Cargo.toml
workspace: .../Cargo.toml
```

Two resolutions, either of which is acceptable:

- add `"packages/rust/meta-relativity"` to `[workspace.members]` at the Foundry root, or
- add an empty `[workspace]` table to this crate's `Cargo.toml` to declare it standalone.

The crate's optional `archivum`/`triple-lock` dependency resolves to
`packages/rust/archivum`.

## Formal verification history

| Artifact | Status | Notes |
| :--- | :--- | :--- |
| `formal/MetaRelativityFormalized/` | **DEPRECATED** | 23-axiom `Real` reconstruction, unsound; see `formal/README.md` |
| `ADR/MetaRelativity.lean` (Foundry root) | Current | Zero-sorry model of ADR-0112/ADR-0070; verified by `lake test` |
| `docs/adr/completed/ADR-0112-Meta-Relativity F1.md` | Governing doc | Cross-cutting design record + numerical appendix |

## Related ADRs inside this crate

`docs/adr/` carries the implementation roadmap (`ADR-ROADMAP-META-RELATIVITY.md`) with
ADR-090 (Axioms), ADR-091 (Space & Frames), ADR-092 (Operators), ADR-093 (Invariants),
ADR-094 (Certification), ADR-095 (Dissipative Regimes), ADR-096 (Security),
ADR-097 (Implementation), ADR-098 (Exemplars), ADR-099 (Testing), ADR-100 (Unbounded
Extensions), ADR-101 (Integration), ADR-102 (Governance), ADR-103 (Documentation),
ADR-104 (Release).