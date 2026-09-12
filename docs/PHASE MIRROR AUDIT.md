# PHASE MIRROR AUDIT — v2 (Resolved)

**Subject:** Universal Closure Calculator (`github.com/PhaseMirror/UCC`)
**Status:** Remediation resolved in the UCC repository.

This file is a pointer. The authoritative v2 audit that scores the remediation
effort (actions A1–A9 and B1–B8, test program T1–T8) against current `HEAD` lives
in the Universal Closure Calculator repository, not in this Foundry tree:

> **`github.com/PhaseMirror/UCC` → `Universal_Closure/PHASE MIRROR AUDIT.md`**

## Why this lives in UCC, not Foundry

The historical v1 audit (`docs/Universal_Closure/Universal Closure Calculator Audit.md`)
was filed under the Foundry monorepo, but the project it describes — the
*Universal Closure Calculator* — is maintained as the standalone `PhaseMirror/UCC`
repository. Per audit item A9 / D9, project metadata (README title, verification
badge, `Cargo.toml` `repository`/`homepage`) now identifies the project as the
**Universal Closure Calculator** and points at `PhaseMirror/UCC`, not at Foundry.

## Summary of resolution

- **A1–A9 (closure criteria): all satisfied** — RH relabeled to CONJECTURE;
  certificate script fails closed (exit 1 on empty logs); `target/` untracked;
  license field aligned with `LICENSE`; badge points at `PhaseMirror/UCC`;
  missing `Foundations.F1`/`Care` imports declared OUT OF SCOPE; Circom/Solidity
  rows removed (only YAML boundary contracts remain); CRat byte-exact parity
  claim withdrawn.
- **B1–B8 (hardening):** B1 (no failing CI cert step), B2 (RH prose/titles
  de-labeled as law), B4 (Kani sentences + `verified:true` removed), B5 (this
  in-repo v1 corrected), B6 (10 shared CRat fixtures + runnable Rust test),
  B8 (`resolvent-verify` listed) are complete. B3 (vendor/delete missing
  imports) is taken as the documented OUT-OF-SCOPE branch (T3 allows this);
  B7 (replace `li := constant one` with a published Li table) is the single
  explicitly-deferred item, blocked on wiring `Real` constructors and kept
  honestly labeled as a DUMMY instance.

**Verdict:** the audit is resolved. The repository remains a conjecture stack
with local algebraic fragments; it makes no claim of a proof of RH, no
cryptographic seal, and no hardware interlock beyond what the Rust gate
implements.
