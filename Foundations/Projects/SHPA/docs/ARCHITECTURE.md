# Project SHPA: Architecture Specification
### Stateless Hash-to-Prime Attestation in Prime-Indexed Multiplicity Spaces

---

## 1. System Overview & Problem Statement

Multiplicity Theory models nonlinear, emergent structures as recursively generated patterns of prime-indexed interactions:
- **Failure of Monotonic Registries:** Naive monotonic registries $R: \text{Image}(H) \hookrightarrow \mathbb{P}$ require global state consensus (Raft/PBFT/blockchain), which fail in distributed, partitioned networks.
- **Failure of Commutative Products:** The scalar product $\mathcal{M}(F) = \prod p_i^{m_i}$ destroys tree nesting and operator evaluation order.
- **The SHPA Solution:** A purely functional, stateless, canonical mapping $H(o) \mapsto p_{op}$ using **Binary Canonical Serialization (BCS)**, **non-commutative topological signatures**, **full-width 256-bit seed derivation**, **offset pinning ($k \le 65,536$)**, and **succinct first-prime gap attestation**.

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph Operator Layer
        Op[Operator Struct o] --> BCS[Binary Canonical Serialization sigma o]
        BCS --> Hash[Operator Identity Hash H op = SHA256 sigma o]
    end

    subgraph Topological Tree Layer
        Hash --> Topo[BCS Node Encoding H op || uleb128 count || child_sigs]
        Topo --> TreeSig[Topological Signature S node]
    end

    subgraph Stateless H2P Derivation
        Hash --> Seed[Derive Odd 256-bit Seed N]
        Seed --> Search[Incremental Search N + k for k in 0..k_max]
        Search --> Prime[Pinned Prime p_op = N + k*]
    end

    subgraph Succinct Gap Attestation
        Search --> GapWitnesses[Composite Witnesses in Gap N .. N+k*-2]
        GapWitnesses --> WitnessRoot[Witness Commitment Root / Pedersen Com]
        Prime --> Manifest[Execution Manifest]
        WitnessRoot --> Manifest
    end

    subgraph O 1 Verifier
        Manifest --> PrimalityTest[Single Baillie-PSW / Miller-Rabin Test on p_op]
        Manifest --> RootCheck[Witness Commitment Root Verification]
        PrimalityTest --> Valid[Verified Stateless Prime Attestation]
        RootCheck --> Valid
    end
```

---

## 3. Core Architectural Components

### 3.1 Binary Canonical Serialization (`rust/src/bcs.rs`)
- Enforces deterministic, cross-language byte encodings for all operator descriptors and trees.
- Variable-length fields use ULEB128 prefixes; floating-point types are prohibited.

### 3.2 Non-Commutative Topological Trees (`rust/src/topological.rs`)
- Evaluates tree signatures recursively:
  $$S(\text{leaf}) = \text{SHA256}(\text{BCS}(H(o), []))$$
  $$S(\text{node}) = \text{SHA256}(\text{BCS}(H(o), [S(T_1), \dots, S(T_k)]))$$
- Distinct child permutations produce completely distinct 256-bit cryptographic signatures.

### 3.3 Stateless H2P Engine (`rust/src/h2p.rs`)
- Converts the full 256-bit hash into an odd integer seed $N$.
- Searches even offsets $k \in [0, k_{\max}]$ with $k_{\max} = 65,536$ (guaranteed by Cramér gap bound $O((\log N)^2) \approx 31,000$).
- Enforces the first-prime rule: $p_{op} = \min \{ M \ge N \mid M \text{ is prime} \}$.

### 3.4 Gap Attestation & O(1) Verification (`rust/src/gap_attestation.rs`)
- Prover supplies compositeness witnesses (non-trivial factors / Fermat witnesses) for all candidates in the gap $[N, N+k^\star-2]$.
- Verifier checks only a single primality test for $p_{op}$ and validates the witness commitment root in $O(1)$ time.
