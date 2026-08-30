PHASE MIRROR AUDIT — v1 (HISTORICAL)
Universal Closure Calculator
github.com/PhaseMirror/UCC  ·  default branch main  ·  inspected commit 5da5157a67746e76317814c0e11464402d3cb67b

**STATUS: SUPERSEDED** — This audit was performed against SHA 5da5157a. The repository
has since been modified to address some of the issues identified here. A subsequent
audit (v2) is available at `docs/PHASE MIRROR AUDIT.md` which scores the remediation
effort against HEAD.

This file is retained for historical reference. Facts described here (e.g., committed
target/, MIT Cargo field, Foundry badge, placeholder PASSED certificates) may no
longer be accurate at HEAD.

Status: conjecture stack with local algebraic fragments. The published RH equivalence is a tautology. Certificates are generated as PASSED when no verifier logs exist. Circom, Groth16, and EVM attestation layers named in the README are not in this repository.
1. Mirror
Stated intent: a substrate-agnostic computational law, encoded as the sextuple (X, ∘, α, μ, Φ, Δ), with lawfulness equivalent to the Riemann Hypothesis, cryptographically sealed, fail-closed at L0, and independently verified in Lean 4, Kani, Circom, and Solidity.
Operating artifact: a split tree. lean/Core is a small typeclass file set with no Mathlib and no sorry. Foundations/ is a larger Lean tree that imports modules that are not present here (Foundations.F1.*, Foundations.Care.*). crates/ucc-engine is a rational-interval gate over three integers. docs/certificates are written by scripts/generate_certificates.py. target/ is committed.
The README verification badge points at CitizenGardens/Foundry, not PhaseMirror/UCC. Cargo.toml repository and homepage fields also point at Foundry. License field in Cargo.toml is MIT. LICENSE file is Prime Materia Open Commons and Bound Works License v1.0, copyright 2024 Multiplicity / Citizen Gardens.
2. Dissonance
D1. The RH theorem does not mention the Riemann Hypothesis
Foundations/universal_closure/UCC_RH.lean builds concreteUCC with associator := True, mu := constant 0, li := constant one, closure := id. Lawfulness is defined as ucc.associator. The headline theorem is:
Lawfulness concreteUCC ↔ LiCrux concreteUCC.li
Proof: left-to-right applies Pos_one to every n. Right-to-left is trivial. That is True ↔ (∀ n, 1 is positive). It does not constrain zeros of ζ. Dirichlet associativity in the same file is marked TODO: replace sorry.
D2. Certificates do not certify
scripts/generate_certificates.py parses target/kani/*.log. If no logs exist it emits four harnesses with status PASSED and a 16-hex SHA-256 prefix of the harness name as contract_hash. Checked files docs/certificates/kani_certificates.json and lean_proxy.json match that placeholder path. Identical timestamps across both files. CI job Generate Certificates runs this script. CI does not install or invoke Kani.
D3. Named layers are missing
README lists ACEGuardian Circom, ACEVerifier.sol, AttestationRegistry.sol, Poseidon2 Bn254, Groth16 public signals, and a 60-plus page monograph as live stack. This repository contains no circuits/ directory, no .circom, no .sol, no .zkey. docs/The Universal Calculator.tex exists. Workspace Cargo.toml members list only crates/ucc-engine. crates/resolvent-verify exists and is unused by the workspace.
D4. Two Lean worlds, one claim
CI builds only lean/ via lake build. Zero-sorry grep is Core/*.lean only. Foundations/ is outside that gate. lean/lakefile.lean requires lean4-stdlib at tag v4.0.0 while the workflow pins leanprover/lean4:v4.32.0-rc1. Homestead/Core.lean and Bridge.lean import Foundations.Care.Core, Foundations.CareViability.Core, Foundations.F1.Li, Foundations.F1.Crux, Foundations.F1.Square.Spectral. Those paths are not in the tree.
D5. CRat is not one object
Lean Axioms.CRat uses interval order: x.center + x.radius ≤ y.center − y.radius. Lean UCCState.is_contractive treats center + radius as an integer and compares to 1. Rust is_contractive treats lambda_m as Ratio(center, radius) and treats state norms as Ratio(center, 1). EPSILON is ⟨1, 1000⟩ in both trees and is compared under different predicates. Cross-language parity in universal_closure.yaml (byte_exact: true between Core.Foundations.UniversalClosure and pirtm_engine.ofa) names modules that do not exist under those paths.
D6. Kani harnesses prove the assumptions they install
verify_closure_idempotent sets double_closed = closed and asserts equality. verify_defect_nonnegative assumes x ≥ 0 and asserts center ≥ 0. verify_ucc_contractivity_enforcement samples numerators and denominators, stores only numerators in UCCState, then asserts a separate formula that still uses the unused denominators. That is not a proof that the runtime gate matches the claimed Banach recursion.
D7. Integrity theater
Workflow path filters omit Foundations/, docs/, and LICENSE. Foundry is installed and never used. cargo test is not Kani. Committing target/debug plus incremental object files inflates the tree past 1,000 blobs and freezes a local build into the claimed source of truth.
3. Claim versus mechanism
Claim	Bound mechanism in this SHA	Residual
Δ ≡ 0 ⇔ RH	associator field hardcoded True; Li coeffs hardcoded one	No zeta, no Li sequence, no zeros
Lean 4 axiom-clean core	lean/Core typeclasses; no instances wired to RH	Foundations tree unbuilt, imports missing
11/11 Kani harnesses	4 placeholder JSON rows; 4 local kani_harness.rs proofs	Kani not in CI; 11 never appears as a count
Fail-closed L0_HALT	Rust Result<&'static str> on three integer checks	No SIG handler, no interlock, no plant
zk-SNARK governance seal	Described in README only	No circuit, no proving key, no verifier
EVM attestation	Described in README only	No Solidity in repo
Kuratowski closure proven	Idempotence of id on ArithFunc	Extensivity, monotonicity, union not shown here
Homestead care bridge	l0Gate is a boolean conjunction; Seal implies each conjunct	Depends on missing Care modules
Byte-exact Lean↔Rust parity	YAML flag	CRat semantics diverge; module names mismatch

4. What is actually there
Keep these. They are real and small.
    • A typeclass sketch of closure, defect, associator bound over a custom interval type.
    • A Rust gate that rejects some integer triples when a Lipschitz product is ≥ 1 or a defect integer is ≥ ε under one encoding.
    • A YAML file that records intended numeric tolerances.
    • Homestead theorems of the form (A ∧ B ∧ C ∧ D) → A, and the contrapositive halt. Locally valid if the missing Care imports resolve.
    • An explicit-formula and Li-decomposition wrapper in Bridge.lean that sets the archimedean side to zero and recovers an identity.
None of those objects is a proof of RH. None is a cryptographic seal. None is a hardware interlock.
5. Hidden assumptions
    1. Naming a field associator and setting it to True is equivalent to assuming lawfulness.
    2. Constant-one Li coefficients satisfy every positivity criterion, so any biconditional with that sequence is free.
    3. Identity as closure operator makes idempotence, and often defect-zero, definitional.
    4. Interval CRat and ratio CRat can be swapped in prose without a conversion lemma.
    5. A JSON file labeled certificate is treated as a verifier transcript.
    6. Extraction from Foundry preserves completeness of imports and of the circuit/EVM packages.
    7. Zero-Mathlib is a soundness property rather than a dependency policy.
6. Phase
Owner for all actions below: repository maintainer of PhaseMirror/UCC. Metric is a public CI log plus a file that exists at the named path.
    A1. Relabel the RH theorem. Status column in README becomes Conjecture. File header in UCC_RH.lean states that concreteUCC is a dummy instance. Metric: grep -n "Proven in Lean 4" README.md returns empty.
    A2. Delete placeholder certificate emission. generate_certificates.py must exit nonzero when target/kani is empty. Metric: running the script on a clean clone fails.
    A3. Add a Kani job or remove the Kani status row. Metric: workflow yaml contains cargo kani, or README verification table no longer lists Kani 0.67.0 as passing.
    A4. Either vendor Foundations.F1 and Foundations.Care or stop importing them. Metric: lake build of the Foundations tree on a clean clone exits 0, or those imports are gone.
    A5. Remove target/ from version control. Metric: .gitignore contains /target and git ls-files target | wc -l is 0.
    A6. One CRat semantics. Write a single conversion lemma used by Lean and Rust, or stop claiming byte-exact parity. Metric: a test that encodes 0.99 and ε = 10⁻³ the same way on both sides.
    A7. Drop Circom/Solidity rows until the files exist in this repo. Metric: path circuits/ace.circom and a .sol verifier, or those rows deleted.
    A8. Align license metadata. Cargo.toml license field must match LICENSE, or LICENSE must be SPDX MIT. Metric: one string in both places.
    A9. Point the verification badge at this repository’s workflow. Metric: README badge URL contains PhaseMirror/UCC.
7. Test program
ID	Test	Pass criterion
T1	Clone, cargo test --workspace	Exit 0 without committed target/
T2	lake build in lean/	Exit 0 on the pinned toolchain
T3	lake build covering Foundations/	Exit 0 or tree declared out of scope
T4	grep sorry Foundations/	Empty, or each sorry listed as axiom
T5	generate_certificates.py on clean tree	Nonzero exit
T6	cargo kani -p ucc-engine	Transcript committed, not a JSON stub
T7	Encode Λ_m = 99/100 and ε = 1/1000 in Lean and Rust	Same accept/reject on 10 shared fixtures
T8	Instantiate UCCSextuple.li from a published Li table for n ≤ 20	Positivity check is data, not constant one

8. Hard stops
This audit does not decide RH. It does not treat a typeclass plus True as a millennium-problem proof. It does not treat SIG_GOV_KILL strings as an operating-system kill. It does not treat a custom license plus MIT Cargo field as dual-licensed without an explicit grant.
Citizen Gardens / Multiplicity / Foundry relationship is provenance, not a validity certificate.
9. Verdict
Intent: universal lawful computation sealed against cheat.
Incentive: the headline theorem and the PASSED certificate file produce the appearance of a closed stack.
Binding that restores coherence: publish the dummy instance as dummy, delete self-PASSED certificates, build only what is in the tree, and move RH to the conjecture column until a Li sequence that is not constantly one is connected to a defect that is not constantly zero.
