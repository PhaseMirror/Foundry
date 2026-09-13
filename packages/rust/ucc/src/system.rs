//! The UCC sextuple wire schema `(X, ∘, α, μ, F, Δ)`.
//!
//! See `docs/specs/ucc_sextuple_v1.md` for the authoritative prose. The wire
//! format is integer-only; there is no floating-point field anywhere, so
//! platform-dependent drift is structurally impossible (ADR-0021).

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// Lawful anchor α of the `join` law: the identity of the `lcm` composition.
pub const ALPHA_JOIN_IDENTITY: u64 = 1;

/// Lawful anchor α of the `union` law: the empty exponent profile.
pub const ALPHA_UNION_IDENTITY: u64 = 0;

/// LawfulRecursionVersion cited in every receipt (ADR-0014 Q0 hygiene gate).
pub const LAWFUL_RECURSION_VERSION: &str = "1.0";

/// ∘ — the lawful composition law.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum CompositionOp {
    /// `K1 ⊗ K2 = lcm(K1, K2)`: lossless structural join. Member labels combine
    /// with the strongest exponent and no double count (ADR-0021).
    #[default]
    Join,
    /// `K1 ⊕ K2 = ∏_p p^(v_p(K1) + v_p(K2))`: exact exponent aggregation
    /// (Dirichlet convolution on multiplicative coefficients, ADR-0021).
    Union,
}

/// The lawful anchor for a composition law.
#[inline]
pub const fn alpha_identity(op: CompositionOp) -> u64 {
    match op {
        CompositionOp::Join => ALPHA_JOIN_IDENTITY,
        CompositionOp::Union => ALPHA_UNION_IDENTITY,
    }
}

/// F — the endomorphism applied per relation step.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum EndoKind {
    /// No growth: the identity endomorphism.
    #[default]
    Identity,
    /// Operator-first arithmetic iterate: surplus exponents accumulate by
    /// `iterate` per participation.
    Ofai,
}

/// The concrete endomorphism with its iterate.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Endomorphism {
    pub kind: EndoKind,
    #[serde(default = "default_iterate")]
    pub iterate: u64,
}

impl Default for Endomorphism {
    fn default() -> Self {
        Endomorphism {
            kind: EndoKind::Identity,
            iterate: default_iterate(),
        }
    }
}

const fn default_iterate() -> u64 {
    1
}

/// X — an object of the system, carrying an irreducible prime identity.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NodeRef {
    pub prime: u64,
    #[serde(default)]
    pub label: String,
}

/// A composition relation being closed over. Both endpoints must be in X.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Relation {
    pub a: u64,
    pub b: u64,
}

/// The wire form of the sextuple.
///
/// `X = x`, `∘ = op`, `α = alpha`, `μ = multiplicity`, `F = f`, and `Δ =
/// delta` (a carried prior defect label; the kernel always rederives Δ).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SystemInput {
    pub x: Vec<NodeRef>,
    #[serde(default)]
    pub op: CompositionOp,
    #[serde(default = "default_alpha")]
    pub alpha: u64,
    #[serde(default)]
    pub multiplicity: BTreeMap<u64, u64>,
    #[serde(default)]
    pub f: Option<Endomorphism>,
    #[serde(default)]
    pub relations: Vec<Relation>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub delta: Option<String>,
}

const fn default_alpha() -> u64 {
    ALPHA_JOIN_IDENTITY
}

impl SystemInput {
    /// Canonical integer form used for the input digest. Length-prefixed,
    /// fixed field order, ULEB128 element counts (ADR-0021 §BCS).
    pub fn canonical_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        out.extend_from_slice(&self.op_marker());
        out.extend_from_slice(&crmf::canonical::be_u64(self.alpha));
        append_uleb128_count(&mut out, self.x.len());
        for node in &self.x {
            out.extend_from_slice(&crmf::canonical::be_u64(node.prime));
            append_uleb128_count(&mut out, node.label.len());
            out.extend_from_slice(node.label.as_bytes());
        }
        append_uleb128_count(&mut out, self.multiplicity.len());
        for (p, v) in &self.multiplicity {
            out.extend_from_slice(&crmf::canonical::be_u64(*p));
            out.extend_from_slice(&crmf::canonical::be_u64(*v));
        }
        match &self.f {
            None => out.push(0x00),
            Some(f) => {
                out.push(0x01);
                out.push(match f.kind {
                    EndoKind::Identity => 0x00,
                    EndoKind::Ofai => 0x01,
                });
                out.extend_from_slice(&crmf::canonical::be_u64(f.iterate));
            }
        }
        append_uleb128_count(&mut out, self.relations.len());
        for rel in &self.relations {
            out.extend_from_slice(&crmf::canonical::be_u64(rel.a));
            out.extend_from_slice(&crmf::canonical::be_u64(rel.b));
        }
        if let Some(d) = &self.delta {
            out.push(0x01);
            append_uleb128_count(&mut out, d.len());
            out.extend_from_slice(d.as_bytes());
        } else {
            out.push(0x00);
        }
        out
    }

    fn op_marker(&self) -> [u8; 1] {
        [match self.op {
            CompositionOp::Join => 0x01,
            CompositionOp::Union => 0x02,
        }]
    }

    /// The set of declared prime identities.
    pub fn node_primes(&self) -> Vec<u64> {
        let mut primes: Vec<u64> = self.x.iter().map(|n| n.prime).collect();
        primes.sort_unstable();
        primes.dedup();
        primes
    }
}

fn append_uleb128_count(out: &mut Vec<u8>, len: usize) {
    out.extend_from_slice(&crmf::canonical::uleb128(len as u64));
}
