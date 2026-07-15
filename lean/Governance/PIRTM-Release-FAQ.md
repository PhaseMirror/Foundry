# PIRTM 1.0 Public Release
**Mathematical Certification for AI and Legal Workflows**

We are thrilled to announce the 1.0 release of the **Prime-Indexed Recursive Tensor Mathematics (PIRTM)** stack. With this release, PIRTM.com becomes the exclusive hub for mathematically certified software, delivering a "Certificate-First" architecture powered by the high-throughput **Goldilocks Kernel**.

This release completes the vertical integration of the PIRTM execution runtime:
1. **Natural Language Intent**: Translating regulatory and stability requirements directly into machine-verifiable constraints.
2. **Prime-Indexed Bytecode**: Isolating sessions using strict prime number topologies rather than fragile string aliases.
3. **Governance-Sealed Binary**: Enforcing network-wide stability via a 3-pass certified linking pipeline.
4. **Hardware-Accelerated Execution**: Running state transitions on a $p = 2^{64} - 2^{32} + 1$ arithmetic rail for zero-knowledge readiness and extreme performance.

---

## Technical FAQ: Getting Started with PIRTM

### Q: What is the `nl_to_pirtm.py` transpiler?
The `nl_to_pirtm.py` transpiler is the "Front Door" to the PIRTM architecture. It allows developers and legal engineers to write stability and safety constraints in plain natural language. The transpiler maps these semantic intents (like "10% margin") into strict EBNF-aligned MLIR bytecode and dual-hash witness commitments (SHA256 and Poseidon).

### Q: How do I use the transpiler for my first certified project?
You can generate your first mathematically certified MLIR module by feeding your stability requirements to the transpiler script:

```bash
python scripts/nl_to_pirtm.py "Ensure stability margin of 0.08 and spectral radius of 0.85 for prime index 13"
```

**Output:**
The transpiler will emit a `!pirtm.module` with a typed `!pirtm.tensor<mod=13>`. This bytecode encapsulates your design-time static proofs (Contractive Typing, L0.1) before any execution occurs.

### Q: Why does PIRTM use "Prime Indices" instead of session names?
To mathematically eliminate session hijacking and state spoofing. By enforcing the **L0.6 Unique Identity Invariant**, human-readable strings (e.g., "SessionA") are stripped during the pre-link phase. Sessions are strictly identified by unique prime numbers. The coprime structure of the resulting tensors guarantees that channels cannot accidentally merge or be maliciously injected.

### Q: What is the `PirtmLinkWithEnsemble` pass?
It is our terminal verification gate. When you link multiple PIRTM modules together to form an application, the linker constructs a global coupling matrix ($\Psi$) and runs a **Spectral Small-Gain** test. 
* If the global spectral radius $r(\Psi) < 1.0$, the system is mathematically stable and emits a **GovernanceSeal**.
* If $r(\Psi) \ge 1.0$, the linker vetoes the build. No non-contractive system can reach the execution kernel.

### Q: How do I verify a PIRTM executable?
Every `pirtm_runtime.bin` executable is a self-certifying document. It separates executable logic from compliance metadata into non-allocating binary sections (`!pirtm_proof` and `!pirtm_governance`). You can audit any binary without running it by using our offline inspection utility:

```bash
pirtm inspect application_runtime.bin
```

This will reveal the exact stability margins, the ensemble hash, and the link-time contractivity seal. For runtime execution trails, you will refer to the immutable `LambdaTraceBridge` logs, completing the requirements for **21 CFR Part 11 Auditability**.

---
*Visit [PIRTM.com](https://pirtm.com) to download the SDK and read the full Compliance & Security Architecture Whitepaper.*
