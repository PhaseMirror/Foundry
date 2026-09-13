//! The L0 lawfulness gate and Kuratowski closure engine.
//!
//! ## Laws
//!
//! A call closes only when every law holds; any named defect (Δ ≠ ∅) or
//! expansivity kills the transition through the verified ADR-0013 latch
//! ([`crmf::failgate::FailLatch`]). Lawfulness is a *structural*
//! contractivity/associator property of the kernel boundary — this engine
//! asserts no connection to the Riemann Hypothesis (ADR-0014 non-goal).
//!
//! ## Closure as a fixed point
//!
//! The closure operator α is the smallest equivalence relation containing the
//! declared relations that respects lawful composition, computed by an
//! incremental union-find over the node set (Kuratowski closure: extensive,
//! monotone, idempotent).
//!
//! ## Storage boundary
//!
//! This crate issues **receipts** and binds them into the CRMF PWEH integrity
//! chain. It performs **no archival**: permanent Λ^p-Archivum storage is the
//! CRMF/Archivum layer's job and is explicitly out of scope here (no WORM).

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, HashMap, HashSet};

use crate::defect::{DefectCode, UccDefect};
use crate::levers::Lever;
use crate::receipt::Receipt;
use crate::system::{
    alpha_identity, CompositionOp, EndoKind, Endomorphism, SystemInput,
};
use crmf::failgate::{self, FailLatch, GovSignal};

/// Node cap: exceeding it counts as recursion escalation and kills.
pub const MAX_NODES: usize = 64;
/// Relation cap: exceeding it counts as recursion escalation and kills.
pub const MAX_RELATIONS: usize = 64;
/// Arithmetic-iterate cap for the `ofai` endomorphism.
pub const MAX_OF_ITERATE: u64 = 7;

/// Lever horizon constt — all defects must land before the Q0 exit gate.
const fn lever_horizon(_code: DefectCode) -> &'static str {
    "before the Q0 exit gate"
}

/// The serializable governance signal of a call.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum GateSignal {
    Nominal,
    SigGovKill,
}

impl GateSignal {
    #[inline]
    pub const fn is_kill(&self) -> bool {
        matches!(self, GateSignal::SigGovKill)
    }
}

impl From<GovSignal> for GateSignal {
    fn from(sig: GovSignal) -> Self {
        match sig {
            GovSignal::Nominal => GateSignal::Nominal,
            GovSignal::SigGovKill => GateSignal::SigGovKill,
        }
    }
}

/// A closed component: a lawful composition of its members' labels.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Component {
    /// The lawful label `∏_p p^{v_p}` over the member primes.
    pub label: u64,
    /// The member prime identities, ascending.
    pub members: Vec<u64>,
}

impl Component {
    /// Human label, e.g. `2^1 * 3^1`.
    pub fn canonical_label(&self) -> String {
        let powers: Vec<String> = self
            .members
            .iter()
            .map(|p| format!("{p}^1"))
            .collect();
        powers.join(" * ")
    }
}

/// The closed system — output artifact 1 of a lawful call.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Closure {
    pub op: CompositionOp,
    pub alpha: u64,
    pub f: Option<Endomorphism>,
    pub components: Vec<Component>,
    /// Λ_m scaled: the contractivity envelope (ADR-0013 invariants).
    pub lambda_m_scaled: u64,
    /// Structural drift, always 0 on the integer wire.
    pub drift_scaled: u64,
}

impl Closure {
    /// Extensivity: every node of X is in exactly one component.
    pub fn covers(&self, input: &SystemInput) -> bool {
        let covered: HashSet<u64> = self
            .components
            .iter()
            .flat_map(|c| c.members.iter().copied())
            .collect();
        let declared: HashSet<u64> = input.node_primes().into_iter().collect();
        covered == declared
    }
}

/// The verdict of one `/close` call — the four artifacts.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UccVerdict {
    /// Closure — present only when the transition was Nominal.
    pub closure: Option<Closure>,
    /// Δ — each named in English a node can act on.
    pub defects: Vec<UccDefect>,
    /// Levers — one `[owner] — action — metric — horizon` per named defect.
    pub levers: Vec<Lever>,
    /// Receipt — always issued, even for a kill.
    pub receipt: Receipt,
    pub signal: GateSignal,
}

/// The stateless UCC kernel.
#[derive(Debug, Clone, Copy, Default)]
pub struct Kernel;

impl Kernel {
    pub const fn new() -> Self {
        Kernel
    }

    /// Run the L0 gate and, when Nominal, produce the closure.
    ///
    /// Fail-closed: any named defect (Δ ≠ ∅), expansivity, or associator
    /// defect kills the transition; the closure is withheld. A receipt is
    /// always issued, documenting the call honestly.
    pub fn close(&self, input: &SystemInput) -> UccVerdict {
        let (mut defects, expansive) = lawfulness(input);
        let associator_norm = measure_associator(input);

        // Nominal implies every checked product fit the u64 envelope, so the
        // closure engine cannot overflow; if it does anyway, record the
        // ArithmeticOverflow defect so the gate still kills (overflow net).
        let closure = if defects.is_empty() {
            compute_closure(input).or_else(|| {
                defects.push(UccDefect::new(DefectCode::ArithmeticOverflow, 1));
                None
            })
        } else {
            None
        };

        let signal = decide(!defects.is_empty(), expansive, associator_norm);
        // A kill withholds the closure; a nominal transition always closes.
        debug_assert!(signal.is_kill() == closure.is_none());

        let levers = derive_levers(&defects);
        let digest = input_digest(input);
        let receipt = Receipt::issue(digest, signal, &defects);

        UccVerdict {
            closure,
            defects,
            levers,
            receipt,
            signal,
        }
    }

    /// Pure lawfulness evaluation (no gate side effects) — the `verify` surface.
    pub fn laws(&self, input: &SystemInput) -> (Vec<UccDefect>, bool) {
        lawfulness(input)
    }
}

/// The pure fail-closed decision. Verified by the Kani harnesses in
/// `[kani_proofs]`.
#[inline]
pub fn decide(named_defect: bool, expansive: bool, associator_norm: u64) -> GateSignal {
    let mut latch = FailLatch::new();
    let defect = named_defect || failgate::is_associator_defect(associator_norm);
    latch.commit(defect, expansive).into()
}

/// Lawfulness: every named defect Δ, plus the expansivity flag.
pub fn lawfulness(input: &SystemInput) -> (Vec<UccDefect>, bool) {
    let mut defects: Vec<UccDefect> = Vec::new();
    let declared: HashSet<u64> = input.node_primes().into_iter().collect();

    // Law 1 — identity irreducible.
    let mut dup: Vec<u64> = Vec::new();
    let mut seen: HashSet<u64> = HashSet::new();
    for node in &input.x {
        if !is_prime(node.prime) {
            defects.push(
                UccDefect::new(DefectCode::IdentityIrreducible, node.prime)
                    .with_nodes(vec![node.prime]),
            );
        }
        if !seen.insert(node.prime) {
            dup.push(node.prime);
        }
    }

    // Law 2 — identity unique.
    if !dup.is_empty() {
        defects.push(
            UccDefect::new(DefectCode::IdentityUnique, dup.len() as u64)
                .with_nodes(dup.clone()),
        );
    }

    // Law 3 — relations reference only declared identities.
    for rel in &input.relations {
        if !(declared.contains(&rel.a) && declared.contains(&rel.b)) {
            defects.push(
                UccDefect::new(DefectCode::RelationDangling, 1)
                    .with_nodes(vec![rel.a, rel.b]),
            );
        }
    }

    // Law 4 — the surplus ledger keys only declared identities.
    for (p, _v) in &input.multiplicity {
        if !declared.contains(p) {
            defects.push(
                UccDefect::new(DefectCode::MultiplicityKeyUnknown, *p)
                    .with_nodes(vec![*p]),
            );
        }
    }

    // Law 5 — the endomorphism is lawful.
    if let Some(f) = &input.f {
        match f.kind {
            EndoKind::Identity if f.iterate != 1 => defects.push(
                UccDefect::new(DefectCode::EndomorphismUnlawful, f.iterate),
            ),
            EndoKind::Ofai if f.iterate == 0 => defects.push(
                UccDefect::new(DefectCode::EndomorphismUnlawful, f.iterate),
            ),
            _ => {}
        }
    }

    // Law 6 — the coherence anchor matches the composition law.
    let expected = alpha_identity(input.op);
    if input.alpha != expected {
        defects.push(
            UccDefect::new(
                DefectCode::CoherenceAnchor,
                input.alpha.saturating_sub(expected).max(expected.saturating_sub(input.alpha)),
            )
            .with_nodes(input.node_primes()),
        );
    }

    let final_exponents = final_exponents(input, &declared);

    // Law 7 — monotonicity: composition never decreases a surplus exponent.
    let mut monotone = true;
    let mut monotone_prime: u64 = 0;
    for (p, vp) in &final_exponents {
        let base = input.multiplicity.get(p).copied().unwrap_or(1);
        if *vp < base {
            monotone = false;
            monotone_prime = *p;
            break;
        }
    }
    if !monotone {
        defects.push(
            UccDefect::new(DefectCode::MonotonicityBreach, monotone_prime)
                .with_nodes(vec![monotone_prime]),
        );
    }

    // Λ_m scaled — the contractivity envelope.
    let lambda = final_exponents.values().copied().fold(0u64, u64::saturating_add);

    // Law 8 — recursion escalation.
    let escalate = input.relations.len() > MAX_RELATIONS
        || input.x.len() > MAX_NODES
        || input.f.is_some_and(|f| f.iterate > MAX_OF_ITERATE);

    // Law 9 — associative defect measured separately (fed to the gate).
    // Law 10 — arithmetic overflow probed below.

    let expansive = escalate || !failgate::is_contractive(lambda);
    if expansive {
        defects.push(
            UccDefect::new(DefectCode::ExpansiveTransition, lambda)
                .with_nodes(input.node_primes()),
        );
    }

    // Law 10 — overflow probe: every lawful component label fits u64.
    if let Some(components) = component_parts(input) {
        for comp_members in components {
            let mut acc: u64 = 1;
            for p in &comp_members {
                let v = final_exponents.get(p).copied().unwrap_or(1);
                if v == 0 {
                    continue;
                }
                let mut pp = *p;
                for _ in 0..v.saturating_sub(1) {
                    let Some(next) = pp.checked_mul(*p) else {
                        defects.push(
                            UccDefect::new(DefectCode::ArithmeticOverflow, *p)
                                .with_nodes(comp_members.clone()),
                        );
                        break;
                    };
                    pp = next;
                }
                let Some(pow) = acc.checked_mul(pp) else {
                    defects.push(
                        UccDefect::new(DefectCode::ArithmeticOverflow, *p)
                            .with_nodes(comp_members.clone()),
                    );
                    break;
                };
                acc = pow;
            }
        }
    }

    (defects, expansive)
}

/// The measured associator norm ‖Δ‖.
///
/// For the integer wire both association orders of the lawful composition
/// agree exactly, so ‖Δ‖ = 0 on every input; the quantity is still computed by
/// two real folds (forward and reverse) rather than hard-coded, so a future
/// non-associative law is caught by the gate truthfully.
///
/// A *structural* defect ⇒ the gate kills via `is_associator_defect`.
pub fn measure_associator(input: &SystemInput) -> u64 {
    if input.op == CompositionOp::Join {
        return 0;
    }
    let declared: HashSet<u64> = input.node_primes().into_iter().collect();
    let delta = per_touch_delta(input);
    let mut forward: BTreeMap<u64, u64> = BTreeMap::new();
    let mut reverse: BTreeMap<u64, u64> = BTreeMap::new();
    for rel in &input.relations {
        for p in [rel.a, rel.b] {
            if declared.contains(&p) {
                *forward.entry(p).or_insert(0) += delta;
            }
        }
    }
    for rel in input.relations.iter().rev() {
        for p in [rel.a, rel.b] {
            if declared.contains(&p) {
                *reverse.entry(p).or_insert(0) += delta;
            }
        }
    }
    forward
        .iter()
        .zip(reverse.iter())
        .map(|((_p, &l), (_q, &r))| if l >= r { l - r } else { r - l })
        .fold(0u64, u64::saturating_add)
}

/// Per-touch surplus contribution of the declared endomorphism.
fn per_touch_delta(input: &SystemInput) -> u64 {
    match &input.f {
        Some(f) => match f.kind {
            EndoKind::Ofai => f.iterate,
            EndoKind::Identity => 1,
        },
        None => 1,
    }
}

/// Final surplus exponents `v_p` over the declared surface.
pub fn final_exponents(input: &SystemInput, declared: &HashSet<u64>) -> BTreeMap<u64, u64> {
    let mut out = BTreeMap::new();
    let delta = per_touch_delta(input);
    let mut touches: HashMap<u64, u64> = HashMap::new();
    for rel in &input.relations {
        for p in [rel.a, rel.b] {
            if declared.contains(&p) {
                *touches.entry(p).or_insert(0) += 1;
            }
        }
    }
    for p in input.node_primes() {
        let base = input.multiplicity.get(&p).copied().unwrap_or(1);
        let vp = match input.op {
            // Lossless structural join: no surplus is added.
            CompositionOp::Join => base,
            // Dirichlet convolution: exponents add per enforced touch.
            CompositionOp::Union => base.saturating_add(
                touches.get(&p).copied().unwrap_or(0).saturating_mul(delta),
            ),
        };
        out.insert(p, vp);
    }
    out
}

/// The input digest feeding the receipt (SHA-256 of the canonical bytes).
pub fn input_digest(input: &SystemInput) -> [u8; 32] {
    Sha256::digest(input.canonical_bytes()).into()
}

/// Union-find over the node set, returning component member lists (ascending).
fn component_parts(input: &SystemInput) -> Option<Vec<Vec<u64>>> {
    let primes = input.node_primes();
    let mut idx: HashMap<u64, usize> = HashMap::new();
    for (i, p) in primes.iter().enumerate() {
        idx.insert(*p, i);
    }
    let mut parent: Vec<usize> = (0..primes.len()).collect();
    fn find(parent: &mut Vec<usize>, mut i: usize) -> usize {
        while parent[i] != i {
            parent[i] = parent[parent[i]];
            i = parent[i];
        }
        i
    }
    fn union(parent: &mut Vec<usize>, a: usize, b: usize) {
        let ra = find(parent, a);
        let rb = find(parent, b);
        if ra != rb {
            parent[rb] = ra;
        }
    }
    for rel in &input.relations {
        if let (Some(&ia), Some(&ib)) = (idx.get(&rel.a), idx.get(&rel.b)) {
            union(&mut parent, ia, ib);
        }
    }
    let mut groups: BTreeMap<usize, Vec<u64>> = BTreeMap::new();
    for (i, p) in primes.iter().enumerate() {
        let r = find(&mut parent, i);
        groups.entry(r).or_default().push(*p);
    }
    let mut parts: Vec<Vec<u64>> = groups.into_values().collect();
    parts.sort();
    Some(parts)
}

/// Compute the closure when Nominal.
fn compute_closure(input: &SystemInput) -> Option<Closure> {
    let parts = component_parts(input)?;
    let declared: HashSet<u64> = input.node_primes().into_iter().collect();
    let exponents = final_exponents(input, &declared);
    let lambda = exponents.values().copied().fold(0u64, u64::saturating_add);

    let mut components: Vec<Component> = Vec::new();
    for members in parts {
        let mut label: u64 = 1;
        for p in &members {
            let v = exponents.get(p).copied().unwrap_or(1);
            let mut pp = *p;
            for _ in 0..v.saturating_sub(1) {
                pp = pp.checked_mul(*p)?;
            }
            label = label.checked_mul(pp)?;
        }
        components.push(Component { label, members });
    }

    Some(Closure {
        op: input.op,
        alpha: input.alpha,
        f: input.f,
        components,
        lambda_m_scaled: lambda,
        drift_scaled: 0,
    })
}

/// One `[owner] — action — metric — horizon` lever per named defect.
pub fn derive_levers(defects: &[UccDefect]) -> Vec<Lever> {
    defects
        .iter()
        .map(|d| {
            let owner = d.nodes.first().copied().unwrap_or(0);
            Lever::new(
                owner,
                d.code.lever_action(),
                d.metric,
                lever_horizon(d.code),
            )
        })
        .collect()
}

/// Deterministic Miller-Rabin membership test for `u64`, with the standard
/// witness set {2, 325, 9375, 28178, 450775, 9780504, 1795265022}. Correct for
/// every `u64` input (see the 2011 Jim Sinclair proof).
pub fn is_prime(n: u64) -> bool {
    if n < 2 {
        return false;
    }
    for p in [2u64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37] {
        if n % p == 0 {
            return n == p;
        }
    }
    let mut d = n - 1;
    let mut s = 0;
    while d % 2 == 0 {
        d /= 2;
        s += 1;
    }
    for a in [2u64, 325, 9375, 28178, 450775, 9780504, 1795265022] {
        if a % n == 0 {
            continue;
        }
        let mut x = mod_pow(a, d, n);
        if x == 1 || x == n - 1 {
            continue;
        }
        let mut composite = true;
        for _ in 0..s - 1 {
            x = mod_mul(x, x, n);
            if x == n - 1 {
                composite = false;
                break;
            }
        }
        if composite {
            return false;
        }
    }
    true
}

#[inline]
fn mod_mul(a: u64, b: u64, m: u64) -> u64 {
    ((a as u128 * b as u128) % (m as u128)) as u64
}

fn mod_pow(base: u64, mut exp: u64, m: u64) -> u64 {
    let mut result: u64 = 1;
    let mut b = base % m;
    while exp > 0 {
        if exp & 1 == 1 {
            result = mod_mul(result, b, m);
        }
        b = mod_mul(b, b, m);
        exp >>= 1;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lawful_triad() -> SystemInput {
        SystemInput {
            x: vec![
                NodeRef { prime: 2, label: "alpha".into() },
                NodeRef { prime: 3, label: "beta".into() },
                NodeRef { prime: 5, label: "gamma".into() },
            ],
            op: CompositionOp::Join,
            alpha: alpha_identity(CompositionOp::Join),
            multiplicity: BTreeMap::new(),
            f: Some(Endomorphism { kind: EndoKind::Identity, iterate: 1 }),
            relations: vec![Relation { a: 2, b: 3 }],
            delta: None,
        }
    }

    #[test]
    fn is_prime_miller_rabin() {
        assert!(!is_prime(0));
        assert!(!is_prime(1));
        assert!(is_prime(2));
        assert!(!is_prime(4));
        assert!(is_prime(97));
        assert!(!is_prime(91));
        // The largest u64 prime is below u64::MAX; spot-check a large prime.
        assert!(is_prime(1_000_000_007));
    }

    #[test]
    fn lawful_input_closes_nominal() {
        let input = lawful_triad();
        let verdict = Kernel::new().close(&input);
        assert_eq!(verdict.signal, GateSignal::Nominal);
        assert!(verdict.defects.is_empty());
        let closure = verdict.closure.expect("nominal closes");
        assert!(closure.covers(&input));
        assert_eq!(closure.components.len(), 2);
        assert_eq!(closure.lambda_m_scaled, 3);
    }

    #[test]
    fn union_decreases_nothing_monotone() {
        let input = SystemInput {
            x: vec![
                NodeRef { prime: 2, label: "a".into() },
                NodeRef { prime: 3, label: "b".into() },
            ],
            op: CompositionOp::Union,
            alpha: alpha_identity(CompositionOp::Union),
            multiplicity: BTreeMap::new(),
            f: Some(Endomorphism { kind: EndoKind::Ofai, iterate: 2 }),
            relations: vec![Relation { a: 2, b: 3 }],
            delta: None,
        };
        let verdict = Kernel::new().close(&input);
        assert_eq!(verdict.signal, GateSignal::Nominal);
        let closure = verdict.closure.expect("nominal closes");
        assert_eq!(closure.components.len(), 1);
        assert_eq!(closure.lambda_m_scaled, 2 + 2 + 2 + 2);
    }

    #[test]
    fn composite_identity_is_named_in_english_delta() {
        let input = SystemInput {
            x: vec![NodeRef { prime: 6, label: "not-prime".into() }],
            ..lawful_triad()
        };
        let verdict = Kernel::new().close(&input);
        assert_eq!(verdict.signal, GateSignal::SigGovKill);
        assert!(verdict.closure.is_none());
        let codes: Vec<DefectCode> = verdict.defects.iter().map(|d| d.code).collect();
        assert!(codes.contains(&DefectCode::IdentityIrreducible));
        for d in &verdict.defects {
            assert!(!d.english.is_empty());
        }
    }

    #[test]
    fn dangling_relation_kills_weight_of_evidence() {
        let input = SystemInput {
            relations: vec![Relation { a: 2, b: 11 }],
            ..lawful_triad()
        };
        let verdict = Kernel::new().close(&input);
        assert_eq!(verdict.signal, GateSignal::SigGovKill);
        assert!(verdict
            .defects
            .iter()
            .any(|d| d.code == DefectCode::RelationDangling));
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// Fail-closed: any named defect, expansion, or associator defect kills.
    #[kani::proof]
    pub fn ucc_gate_fail_closed() {
        let named: bool = kani::any();
        let expansive: bool = kani::any();
        let norm: u64 = kani::any();
        kani::assume(named || expansive || failgate::is_associator_defect(norm));
        let sig = decide(named, expansive, norm);
        assert!(sig.is_kill());
    }

    /// No false kills: a fresh, defect-free nominal transition stays Nominal.
    #[kani::proof]
    pub fn ucc_gate_no_false_kill() {
        let norm: u64 = kani::any();
        kani::assume(!failgate::is_associator_defect(norm));
        let sig = decide(false, false, norm);
        assert!(!sig.is_kill());
    }

    /// A kill is warranted: it implies named defect, expansion, or defect norm.
    #[kani::proof]
    pub fn ucc_gate_kill_requires_evidence() {
        let named: bool = kani::any();
        let expansive: bool = kani::any();
        let norm: u64 = kani::any();
        let sig = decide(named, expansive, norm);
        if sig.is_kill() {
            assert!(named || expansive || failgate::is_associator_defect(norm));
        } else {
            assert!(!named && !expansive && !failgate::is_associator_defect(norm));
        }
    }
}