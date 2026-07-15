# ADR-003: Controlled Natural Language Compiler over Phase Mirror / PIRTM

**Status:** Proposed
**Date:** 2026-06-30
**Domain:** `commander-core` / `pirtm-apps`

## 1. Context & Problem Statement

Large Language Models (LLMs) excel at natural language parsing but are inherently probabilistic, expensive to run, and opaque in their reasoning. This makes them dangerous for high-stakes domains (e.g., DevOps orchestration, legal execution) where hallucinations can cause catastrophic failures.

Conversely, the Phase Mirror architecture (via the Atomic Language Policy and PIRTM compute models) provides an axiomatic, perfectly bounded, and auditable ledger of operations governed by lean-proven physics (Contraction Bound $c$, Resonance Tension $R_{sc}$). However, raw mathematical operators are unapproachable for human users.

**Opportunity:** By mapping a domain-specific vocabulary to Prime-Indexed Operators (`Ap(p)`), we can create a Controlled Natural Language (CNL) interface. This replaces the LLM entirely, providing a deterministic, auditable, and CPU-lightweight Natural Language interface for high-stakes execution, backed by topological proofs.

## 2. Decision

**We will implement a domain-specific CNL compiler on top of `pirtm-apps`.** 
This compiler will use:
- **A Lexical Anchor Table** mapping domain tokens directly to prime-indexed operators (`Ap(p)`).
- **A Formal Grammar** that compiles user input into `StratumBoundary` ensembles.
- **Phase Mirror Invariants** (`R_sc`, `c`) as the absolute gate for semantic validity.
- **A DialogueFrame** utilizing specific retraction meta-operators for safe multi-turn conversations.
- **A Topological Suggestion Engine** for real-time, mathematically derived fault correction (Topological Auto-Complete).

**We will NOT** attempt to parse arbitrary human language, metaphors, or unstructured prose. Any sentence failing to cleanly map into the safe geometric constraints of the Phase Mirror will be rejected with explicit, auditable diagnostics.

## 3. Architectural Components

The CNL Compiler pipeline is structured as follows:

```
User Input 
   ↓
Tokenizer & Lexical Anchor Table (maps text to primes)
   ↓
MOCWord Compiler (constructs operator trees)
   ↓
DialogueFrame (stack context management)
   ↓
Invariant Enforcer (Gate1: Resonance, Gate2: Contraction)
   ↓ (pass)                       ↓ (fail)
Execution Bridge (API calls)    Suggestion Engine (Topological Auto-Complete)
                                  ↓
                                User-facing Correction
```

* **Lexical Anchor Table:** A statically verified dictionary linking strings to primes.
* **MOCWord Compiler:** Aggregates operators sequentially into Composites and wraps them in a `StratumBoundary`.
* **DialogueFrame:** Manages multi-turn state (`Mode::Assert`, `Mode::Retract`). Safe retractions are computed mathematically without violating topological bounds.
* **Invariant Enforcer:** The absolute authority derived from `MOC.Core` Lean proofs.
* **Suggestion Engine:** Uses the Adjacency Graph of primes to find the mathematically closest valid token sequence when a failure occurs.

## 4. Key Design Decisions & Trade-offs

1. **Strict Prohibition of `Ap(1)`:** Natural language negation (e.g., "not", "all") is topologically expansive. Mapping it to `Ap(1)` instantly triggers the `L0_08_PrimeOneForbidden` limit. Retractions are instead handled via a dedicated `Revoke` operator (`Ap(19)`) which algebraically neutralizes a prior command without unbounded expansion.
2. **Lexicon Pre-Verification:** An offline tool (`lexicon_verify`) brute-forces all allowed `MOCWord` permutations up to length *L*, pre-computing invariants. This ensures no "lexicon holes" (where a valid English sentence mathematically breaks the mirror, or vice-versa) enter production. Trade-off: High up-front compute for guaranteed $O(1)$ runtime safety.
3. **Topological Auto-Complete:** Instead of searching vectors in a neural net, suggestions are found by calculating the prime-index distance and invariant drift between the failed sequence and the nearest valid sequence in the adjacency graph.
4. **Stratum Nesting:** Retraction involves constructing a cancellation stratum that inverses the prior command. The composition evaluates to a safe neutral ground state, preserving $c < 1.0$ and $R_{sc} \ge 1.0$.

## 5. Invariants & Failure Modes

The compiler strictly relies on the 10 constitutional L0 invariants. Key protections include:

| Invariant | Guards Against | Diagnostic / Suggestion |
| :--- | :--- | :--- |
| `L0_08_PrimeOneForbidden` | Unbounded expansion, raw negation, universally ambiguous quantifiers (e.g., "all") | "The use of negation ('not') or unbounded operators violates topological limits. Nearest valid substitute: [Token]" |
| `L0_02_Gate2_ContractionBound` | Semantically contradictory, overly complex, or physically impossible compound sentences. | "The sentence is too complex or semantically contradictory. Try breaking it into smaller commands." |
| `L0_01_Gate1_Resonance` | Execution paths that lack sufficient computational 'tension' to safely ground an action. | "Action lacks sufficient context. Please specify a target object." |

## 6. Implementation Status & Evidence

The prototype is fully operational within the `pirtm-apps` crate.

### Evidence 1: Static Pre-verification (`bin/lexicon_verify.rs`)
Offline generation correctly bounded safe grammar and flagged illegal structures:
```
[VALID]   "deploy scale scale" (c: 0.5833, Rsc: 3.2500)
[VALID]   "deploy destroy destroy" (c: 0.3088, Rsc: 18.8638)
```

### Evidence 2: Dialogue & Suggestion Engine (`bin/cnl.rs`)
A live 3-turn trace demonstrating `Assert`, `Retract`, and `Topological Auto-Complete`:
```
User: "deploy web-service cluster"
✅ Asserted. Current context depth: 1

User: "revoke it"
🔄 Retraction detected. Neutralizing previous stratum...
✅ Context cleared. Current context depth: 0

User: "deploy all cluster"
❌ Invariant Failed: L0_08_PrimeOneForbidden: Prime index 1 is strictly expansive
💡 Suggestion Engine: Scanning adjacency graph...
   -> 'all' maps to Ap(1) [Forbidden]. Nearest valid topological substitutes:
      - 'web-service' (Ap(5), cost distance 4)
      - 'database' (Ap(7), cost distance 6)
   -> Did you mean: 'deploy web-service cluster'?
```

## 7. Future Extensions

1. **Execution Bridge:** Wire passing, validated `MOCWord` ensembles strictly to physical APIs (e.g., Kubernetes clients) to perform domain actions with 100% auditable provenance.
2. **Domain Scaling:** Expand the `lexicon_verify` graph to accommodate the Legalese Substrate (Legal CNL).
3. **Formal Lean 4 Proofs:** Formally model the Lexical Anchor Table in Lean to mathematically prove that no valid dictionary sequence can ever breach `c = 1.0`.
