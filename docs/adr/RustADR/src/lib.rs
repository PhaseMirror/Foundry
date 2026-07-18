#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ADRStatus {
    Proposed,
    Accepted,
    Deprecated,
    Superseded,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArtifactLink {
    pub url: &'static str,
    pub description: &'static str,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ADR {
    pub id: u32,
    pub title: &'static str,
    pub status: ADRStatus,
    pub context: &'static str,
    pub decision: &'static str,
    pub consequences: &'static [&'static str],
    pub supersedes: Option<u32>,
    pub links: &'static [ArtifactLink],
}

pub fn is_valid_transition(old: ADRStatus, new: ADRStatus) -> bool {
    match (old, new) {
        (ADRStatus::Proposed, _) => true,
        (ADRStatus::Accepted, ADRStatus::Superseded) => true,
        (ADRStatus::Accepted, ADRStatus::Deprecated) => true,
        (ADRStatus::Accepted, _) => false,
        (ADRStatus::Superseded, _) => false,
        (ADRStatus::Deprecated, _) => false,
    }
}

pub mod examples {
    use super::*;

    pub fn riemann_adr() -> ADR {
        ADR {
            id: 1,
            title: "Riemann Hypothesis Computational Implementation",
            status: ADRStatus::Accepted,
            context: "Need robust zero boundary computation.",
            decision: "Implement Odlyzko-Schonhage with arbitrary precision bounds.",
            consequences: &["High latency", "Rigorous proofs of zero loci"],
            supersedes: None,
            links: &[],
        }
    }

    pub fn collatz_adr() -> ADR {
        ADR {
            id: 2,
            title: "Collatz Conjecture Computational Verification",
            status: ADRStatus::Accepted,
            context: "Massive-scale validation required.",
            decision: "Build highly parallelized Rust engine using SIMD and GPU acceleration.",
            consequences: &["Hardware dependencies", "Massive speedup"],
            supersedes: None,
            links: &[],
        }
    }

    pub fn pells_adr() -> ADR {
        ADR {
            id: 3,
            title: "Pell's Equation Implementation",
            status: ADRStatus::Proposed,
            context: "Requirement for computing large fundamental solutions.",
            decision: "Implement cyclic continued fractions algorithm with big integer support.",
            consequences: &["Exact integer computation", "High memory usage for massive D"],
            supersedes: None,
            links: &[],
        }
    }

    pub fn pirtm_compiler_adr() -> ADR {
        ADR {
            id: 4,
            title: "PIRTM Compiler Implementation (Phase B)",
            status: ADRStatus::Accepted,
            context: "Need to enforce Prime Successor Predicate via programmable language.",
            decision: "Implement the Sig library (Multiplicity Functor) in crates/pirtm-compiler.",
            consequences: &["Requires strict tree-sitter integration", "Enables ACE invariant checks"],
            supersedes: None,
            links: &[],
        }
    }

    pub fn ace_runtime_adr() -> ADR {
        ADR {
            id: 5,
            title: "Attested Convergence Envelope (ACE) Runtime",
            status: ADRStatus::Proposed,
            context: "Requires standalone enforcement layer for budget and invariant checks.",
            decision: "Implement ACE invariant checks inside the Rust Engine with hardware-level memory boundaries.",
            consequences: &["Zero-drift risk modeling", "High computational overhead for budget assertions"],
            supersedes: None,
            links: &[],
        }
    }

    pub fn dynamic_recursive_meta_math_adr() -> ADR {
        ADR {
            id: 6,
            title: "Dynamic Recursive Meta-Mathematics (DRMM)",
            status: ADRStatus::Proposed,
            context: "Need formal logic framework that dynamically adjusts to multi-scale constraints.",
            decision: "Implement the contractive recursive operator framework into the MOC sovereign domain.",
            consequences: &["Ensures axiomatic purity", "Increases theorem prover latency"],
            supersedes: None,
            links: &[],
        }
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    impl kani::Arbitrary for ADRStatus {
        fn any() -> Self {
            match kani::any::<u8>() % 4 {
                0 => ADRStatus::Proposed,
                1 => ADRStatus::Accepted,
                2 => ADRStatus::Deprecated,
                _ => ADRStatus::Superseded,
            }
        }
    }

    #[kani::proof]
    fn proof_accepted_is_irreversible() {
        let old_status = ADRStatus::Accepted;
        let new_status: ADRStatus = kani::any();

        // We verify that an Accepted ADR cannot transition to anything EXCEPT Superseded or Deprecated.
        // Therefore, if it is NOT Superseded and NOT Deprecated, the transition must be INVALID.
        kani::assume(new_status != ADRStatus::Superseded);
        kani::assume(new_status != ADRStatus::Deprecated);

        assert!(!is_valid_transition(old_status, new_status));
    }

    #[kani::proof]
    fn proof_proposed_is_always_valid_to_leave() {
        let old_status = ADRStatus::Proposed;
        let new_status: ADRStatus = kani::any();

        // From proposed, we can go to any valid status
        assert!(is_valid_transition(old_status, new_status));
    }
    
    #[kani::proof]
    fn proof_superseded_is_terminal() {
        let old_status = ADRStatus::Superseded;
        let new_status: ADRStatus = kani::any();

        // Cannot leave Superseded
        assert!(!is_valid_transition(old_status, new_status));
    }
}
