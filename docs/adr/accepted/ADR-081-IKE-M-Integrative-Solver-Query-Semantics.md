# ADR-081: IKE / M-Integrative Solver Query Semantics

## Status
**Adopted**

## Context
The publication `Machine Teaching for Information Extraction/IKE_AKBC16_v5.tex` (22 KB) describes the **IKE (Interactive Knowledge Extraction) system** and the **M-Integrative Solver**, which provide:

- **Chunk-based query language**: A structured query language with capture groups for information extraction.
- **Set expansion**: Cosine-similarity-based expansion of entity sets from seed examples.
- **Query narrowing/broadening**: Adaptive query modification based on result quality.
- **Query suggestor ranking**: Ranking of suggested queries by expected information gain.

These components are **high-value targets** because they form the **knowledge extraction and reasoning layer** of the Multiplicity Sovereign Core. They bridge the gap between raw data and the structured knowledge graphs consumed by the MOC/CRMF and Phase Mirror governance layers.

Currently, IKE and the M-Integrative Solver exist only as academic publication content. There is **no Lean 4 formalization** of the query semantics, set-expansion soundness, or ranking fairness. There is **no Rust implementation** in `Prime/crates/`.

Without formal ratification, the knowledge extraction layer risks:
- **Query semantics drift**: Different implementations may interpret the same query differently.
- **Set expansion unsoundness**: Cosine-similarity expansion may introduce irrelevant or incorrect entities.
- **Ranking bias**: The query suggestor may systematically favor certain entity types or sources.

## Decision
We will implement IKE and the M-Integrative Solver as **formally verified, production-grade knowledge extraction and reasoning components** with the following mandates:

### 1. Lean 4 Formalization as Query Semantics Ground Truth
- Create `Prime/lean/IKE/IKESemantics.lean` with:
  - `Chunk` — a structured text fragment with capture groups
  - `Query` — inductive type for query expressions (match, expand, narrow, broaden)
  - `EntitySet` — set of entities with cosine-similarity scores
  - `QueryResult` — ranked list of results with confidence scores
- Prove:
  - `set_expansion_sound`: Cosine-similarity expansion preserves entity type consistency.
  - `query_narrowing_complete`: Narrowing a query does not discard valid results.
  - `ranking_fairness`: The query suggestor ranking is monotonic in expected information gain.

### 2. Rust Implementation
- Create `Prime/crates/ike/` with:
  - `QueryEngine::compile(source: &str) -> Result<Query, ParseError>`
  - `QueryEngine::execute(query: &Query, context: &KnowledgeGraph) -> Result<QueryResult, ExecutionError>`
  - `SetExpander::expand(seed: &EntitySet, similarity_threshold: f64) -> Result<EntitySet, ExpansionError>`
- The Rust implementation must:
  - Use exact cosine-similarity computation (no floating-point drift in ranking)
  - Emit `IKEExecutionWitness` to `Archivum` on every query execution

### 3. Kani Verification
- Implement Kani harnesses in `Prime/crates/ike/tests/kani/` proving:
  - `proof_set_expansion_sound`: `expand` only adds entities with similarity ≥ threshold.
  - `proof_query_deterministic`: `execute` returns the same result for the same query and context.
  - `proof_ranking_monotonic`: Ranking is monotonic in information gain.

### 4. CI/CD and Triple-Lock Integration
- CI must run `lake build` on `Prime/lean/IKE/` and `cargo kani -p ike` on every PR.
- The Guardian lock must verify the `IKEExecutionWitness` before approving knowledge extraction.
- The Examiner lock must audit query traces for soundness.
- The Publisher lock must sign extracted knowledge into `Archivum`.

## Formal Proof Obligations

### 1. Set Expansion Soundness
```lean
namespace ADR.IKE

structure Entity where
  id : Nat
  label : String
  embedding : List ℝ
  deriving Repr

structure EntitySet where
  entities : List Entity
  similarity_threshold : ℝ
  deriving Repr

def cosine_similarity (e₁ e₂ : Entity) : ℝ :=
  -- Cosine similarity between embedding vectors
  sorry  -- mechanized: dot product / (norm₁ * norm₂)

def expand_set (seed : EntitySet) (candidate : Entity) : EntitySet :=
  if seed.entities.all (λ e => cosine_similarity e candidate ≥ seed.similarity_threshold) then
    { seed with entities := seed.entities ++ [candidate] }
  else seed

@[proof]
theorem set_expansion_sound (seed : EntitySet) (candidate : Entity)
  (h_expand : expand_set seed candidate = seed') :
  candidate ∈ seed'.entities → seed'.entities.all (λ e => e.embedding = candidate.embedding ∨ cosine_similarity e candidate ≥ seed.similarity_threshold) := by
  -- Proof that any expanded entity meets the similarity threshold
  -- with respect to all existing entities in the set.
  sorry

end ADR.IKE
```

### 2. Rust Runtime Contract
```rust
// crates/ike/src/lib.rs
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entity {
    pub id: u64,
    pub label: String,
    pub embedding: Vec<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntitySet {
    pub entities: Vec<Entity>,
    pub similarity_threshold: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryResult {
    pub entities: Vec<Entity>,
    pub scores: Vec<f64>,
}

#[derive(Debug, thiserror::Error)]
pub enum ExpansionError {
    #[error("candidate similarity {actual} below threshold {threshold}")]
    BelowThreshold { actual: f64, threshold: f64 },
}

impl SetExpander {
    pub fn expand(&self, seed: &EntitySet, candidate: &Entity) -> Result<EntitySet, ExpansionError> {
        for e in &seed.entities {
            let sim = cosine_similarity(e, candidate);
            if sim < seed.similarity_threshold {
                return Err(ExpansionError::BelowThreshold { actual: sim, threshold: seed.similarity_threshold });
            }
        }
        let mut new_set = seed.clone();
        new_set.entities.push(candidate.clone());
        Ok(new_set)
    }
}
```

## Consequences

### Positive
- **Verified Knowledge Extraction**: Lean 4 + Kani guarantees that set expansion and query execution are semantically sound.
- **Deterministic Querying**: The same query always returns the same result, enabling reproducible knowledge graphs.
- **Audit-Ready Extraction**: Every query execution emits an `IKEExecutionWitness` to `Archivum`.
- **M-Integrative Solver Foundation**: Provides the formal substrate for the M-Integrative Solver's reasoning layer.

### Negative
- **Embedding Dependency**: Cosine-similarity expansion requires pre-computed entity embeddings; embedding quality directly affects extraction correctness.
- **Performance Overhead**: Exact cosine-similarity computation over large entity sets is `O(n·d)` per candidate.
- **Ranking Calibration**: The information-gain ranking function must be calibrated against human evaluators; formal fairness does not guarantee practical usefulness.

## Implementation Steps

1. **Define `IKESemantics.lean`** in `Prime/lean/IKE/` with `Chunk`, `Query`, `EntitySet`, `QueryResult`.
2. **Prove core theorems** in `Prime/lean/adr-governance/ADR/IKESemanticsProofs.lean`.
3. **Create `Prime/crates/ike/`** with `QueryEngine`, `SetExpander`, and execution APIs.
4. **Implement Kani harness** proving set expansion soundness and query determinism.
5. **Wire Triple-Lock integration**: Guardian → query approval → Examiner → `IKEExecutionWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `cargo kani -p ike`.
7. **Emit Archivum witness** `IKEExecutionProof` on every query.
8. **Benchmark extraction precision/recall** against baseline IE systems.

## References
- `Machine Teaching for Information Extraction/IKE_AKBC16_v5.tex` — Primary source (22 KB)
- `Prime/lean/IKE/` — To be created
- `Prime/crates/ike/` — To be created
- ADR-074 (ALP Verification SDK) — Policy gate for knowledge extraction
- ADR-068 (MOC/CRMF) — Contraction certificates for reasoning layer
- `Prime/crates/verification-sdk/` — WASM verification SDK
