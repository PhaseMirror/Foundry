# SNAPKITTY-PROOFS

Formal verification artifacts for the SnapKitty Sovereign OS. Three proof languages, one truth.

## Structure

```
proofs/
├── lean4/
│   ├── policy-kernel/      — Sovereign Policy Kernel (verdict algebra, policy DSL)
│   └── bifrost-policy/     — Bifrost event validity (JitCompile, CapTransfer, Attestation)
├── prolog/
│   ├── shrew_observer.pl   — SHREW: 4-level attestation witness (read-only)
│   ├── edaulc_verify.pl    — EDAULC: 5-pass ERE verification engine
│   └── quantum_monad.pl    — Quantum monad: Watchtowers, METATRON, 49th Call
└── haskell/
    ├── quantum_monad.hs    — Quantum superposition monad (Born-rule collapse)
    ├── no_cloning.hs       — No-Cloning Theorem (LinearTypes GADT, v2.0)
    └── thermal.hs          — Thermodynamic Window Engine (proven lo < hi)
```

## The Proof Stack

| Language | Role | Tool |
|----------|------|------|
| **Lean 4** | Propositions as types, soundness theorems | `lake build` |
| **Prolog** | Logic constraints, attestation rules, ERE passes | SWI-Prolog |
| **Haskell** | Compiler-enforced invariants, LinearTypes | GHC 9.4.8 |

## Key Theorems

### Lean 4 — Bifrost Policy Soundness
```lean
theorem decide_sound (e : Event) (s : State)
    (h : decide e s = true) : validEvent e s
```
Status: `sorry` placeholder (tracked Week 3 obligation for Policy Engineer)

### Haskell — No-Cloning Theorem
```haskell
noCloningProof :: QuantumTemp %1 -> ObservationResult
```
Compiler-enforced: GHC rejects any second `observe` call. Full LinearTypes propagation through GADT constructor boundary (v2.0).

### Haskell — Thermal Window Invariant
```
lo(f) ≤ 16383 < 49151 ≤ hi(f)   for all f ∈ [0,1]
```
Proven algebraically; `mkThermalWindow` smart constructor enforces at runtime.

### Prolog — Mirror Identity
```prolog
mirror_identity(X) :- call_49(X, Once), call_49(Once, Twice), Twice = X.
```
Structural coherence proof: `reverse(reverse(X)) = X`.

## Sources

These files are canonical copies from:
- `DEVFLOW-FINANCE/lean4-policy-kernel/` → `lean4/policy-kernel/`
- `snap-os/bifrost-policy/lean/` → `lean4/bifrost-policy/`
- `DEVFLOW-FINANCE/bridges/prolog/` → `prolog/`
- `DEVFLOW-FINANCE/bridges/haskell/` → `haskell/`

## Running the Proofs

```bash
# Lean 4 (policy kernel)
cd lean4/policy-kernel && lake build

# Prolog (quantum monad with sovereign defaults)
swipl -g main -t halt prolog/quantum_monad.pl -- 53 49 106 7

# Prolog (SHREW attestation)
swipl -g "attest_all, halt" prolog/shrew_observer.pl > shrew_report.txt

# Haskell (no-cloning pipeline)
echo -e "32767\n1\n1\n1\n1\n1" | runghc haskell/no_cloning.hs

# Haskell (thermal engine)
echo -e "0.3\n0.6" | runghc haskell/thermal.hs
```

## License

Sovereign Source License v1.0
