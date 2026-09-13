//! End-to-end gate tests for the UCC Q0 slice (ADR-0014).

use std::collections::BTreeMap;

use ucc::defect::DefectCode;
use ucc::kernel::{GateSignal, Kernel};
use ucc::levers::Lever;
use ucc::receipt::KANI_HARNESSES;
use ucc::system::{
    alpha_identity, CompositionOp, EndoKind, Endomorphism, NodeRef, Relation, SystemInput,
};

fn triad(input: SystemInput) -> UccVerdictHelper {
    UccVerdictHelper(Kernel::new().close(&input))
}

struct UccVerdictHelper(ucc::kernel::UccVerdict);

impl UccVerdictHelper {
    fn signal(&self) -> GateSignal {
        self.0.signal
    }
    fn defects(&self) -> &[ucc::UccDefect] {
        &self.0.defects
    }
    fn levers(&self) -> &[Lever] {
        &self.0.levers
    }
    fn closure(&self) -> Option<&ucc::kernel::Closure> {
        self.0.closure.as_ref()
    }
}

fn lawful_triad() -> SystemInput {
    SystemInput {
        x: vec![
            NodeRef {
                prime: 2,
                label: "alpha".into(),
            },
            NodeRef {
                prime: 3,
                label: "beta".into(),
            },
            NodeRef {
                prime: 5,
                label: "gamma".into(),
            },
        ],
        op: CompositionOp::Join,
        alpha: alpha_identity(CompositionOp::Join),
        multiplicity: BTreeMap::new(),
        f: Some(Endomorphism {
            kind: EndoKind::Identity,
            iterate: 1,
        }),
        relations: vec![Relation { a: 2, b: 3 }],
        delta: None,
    }
}

#[test]
fn lawful_triad_closes_nominal_with_receipt() {
    let v = triad(lawful_triad());
    assert_eq!(v.signal(), GateSignal::Nominal);
    assert!(v.defects().is_empty());
    let closure = v.closure().expect("nominal closes");
    assert!(closure.covers(&lawful_triad()));
    assert_eq!(closure.components.len(), 2);
    assert_eq!(closure.lambda_m_scaled, 3);
    assert_eq!(v.0.receipt.input_sha256.len(), 64);
    assert!(v.0.receipt.pweh_chain_root.len() == 64);
    assert!(!KANI_HARNESSES.is_empty());
}

#[test]
fn closure_is_extensive_idempotent_monotone() {
    let input = lawful_triad();
    let closed = Kernel::new().close(&input);
    let closure = closed.closure.expect("nominal closes");
    // Extensivity: every declared node is covered exactly once.
    assert!(closure.covers(&input));

    // Idempotence: closing an already-closed system yields the same components.
    let reclosed = SystemInput {
        relations: closure
            .components
            .iter()
            .filter_map(|c| match c.members.as_slice() {
                [a, b] => Some(Relation { a: *a, b: *b }),
                _ => None,
            })
            .collect(),
        ..input.clone()
    };
    let second = Kernel::new().close(&reclosed).closure.expect("nominal");
    assert_eq!(second.components, closure.components);

    // Monotonicity: adding a third relation only merges components.
    let larger = SystemInput {
        relations: vec![Relation { a: 2, b: 3 }, Relation { a: 3, b: 5 }],
        ..input.clone()
    };
    let bigger = Kernel::new().close(&larger).closure.expect("nominal");
    assert_eq!(bigger.components.len(), 1);
}

#[test]
fn composite_identity_is_named_in_english() {
    let input = SystemInput {
        x: vec![NodeRef {
            prime: 6,
            label: "not-prime".into(),
        }],
        ..lawful_triad()
    };
    let v = triad(input);
    assert_eq!(v.signal(), GateSignal::SigGovKill);
    assert!(v.closure().is_none());
    assert!(v
        .defects()
        .iter()
        .any(|d| d.code == DefectCode::IdentityIrreducible));
    for d in v.defects() {
        assert!(!d.english.is_empty());
    }
}

#[test]
fn every_defect_has_actionable_lever() {
    let input = SystemInput {
        relations: vec![Relation { a: 2, b: 11 }],
        ..lawful_triad()
    };
    let v = triad(input);
    assert_eq!(v.signal(), GateSignal::SigGovKill);
    assert!(!v.levers().is_empty());
    for l in v.levers() {
        assert!(!l.action.is_empty());
    }
}

#[test]
fn duplicate_identity_kills() {
    let input = SystemInput {
        x: vec![
            NodeRef {
                prime: 2,
                label: "a".into(),
            },
            NodeRef {
                prime: 2,
                label: "b".into(),
            },
        ],
        relations: vec![],
        ..lawful_triad()
    };
    let v = triad(input);
    assert_eq!(v.signal(), GateSignal::SigGovKill);
    assert!(v
        .defects()
        .iter()
        .any(|d| d.code == DefectCode::IdentityUnique));
}

#[test]
fn eskew_anchor_kills() {
    let input = SystemInput {
        alpha: 7,
        ..lawful_triad()
    };
    let v = triad(input);
    assert_eq!(v.signal(), GateSignal::SigGovKill);
    assert!(v
        .defects()
        .iter()
        .any(|d| d.code == DefectCode::CoherenceAnchor));
}
