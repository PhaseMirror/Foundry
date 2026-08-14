# Oracle provenance

Every external validation artifact this repository checks against, with its authority,
pin, license, and checksum. The machine-readable twin is
[`../model/oracles.toml`](../model/oracles.toml); `cargo run -p xtask -- oracle-verify`
(and CI) assert the two agree and that each committed artifact matches its `sha256`.

| Oracle | Authority | Pin | License | Artifact | Verified by |
|---|---|---|---|---|---|
| `f1-atlas` | F1 — UOR Atlas (Lean 4, machine-checked, sorry-free) | tag `v0.21.0` / commit `b64df2a` | MIT | `oracles/f1/atlas-constants.json` (sha256 `196edc3f…`) | sha256 + `atlas-pin-check` (live tip) |
| `uor-addr-composition` | uor-addr — realized g2/f4/e6/e7/e8 composition | `0.2.0` (crates.io) | Apache-2.0 | _(linked code; via facade)_ | byte-for-byte κ reduction in witnesses |
| `holospaces-cc` | holospaces `vv` witnesses (CC-1/2/29/30) | commit `f241562…` | MIT | _(linked code; via facade)_ | facade against holospaces public API |
| `mtc-axioms` | MTC axioms (hexagon, Yang–Baxter, SL(2,ℤ), Verlinde) | Bakalov–Kirillov; Turaev; Kitaev App. E; Rowell–Stong–Wang | — | _(executable predicates in `tqc-mtc`)_ | axiom predicates; unit-tested on small `D(Z_n)` |

## F1 re-derivation (manual procedure)

The `f1-atlas` artifact is a committed snapshot of `decide`-proved theorem values from F1 at
the pinned release tag. `cargo run -p xtask -- oracle-verify` re-derives its `sha256` and
checks it against `model/oracles.toml`; `cargo run -p xtask -- atlas-pin-check` confirms the
pinned commit is a live upstream ref tip.

To regenerate the snapshot from F1 (the devcontainer provides Lean/elan):

1. `git clone https://github.com/afflom/F1 && cd F1 && git checkout v0.21.0`
2. `lake build` (compiles `F1Square/Square/Atlas*`).
3. Read the relevant `decide`-proved constants (spectrum, classes, generator orders, E8 seed,
   modular coefficients, Coxeter data) and write them into `oracles/f1/atlas-constants.json`
   (RH-free; this repository carries no crux key).
4. Recompute the digest: `sha256sum oracles/f1/atlas-constants.json`.
5. Update `sha256` in `model/oracles.toml` and this table, then run
   `cargo run -p xtask -- oracle-verify`.

A fully automated `lake`-based extractor is not yet wired; the procedure above is the
authoritative re-derivation.
