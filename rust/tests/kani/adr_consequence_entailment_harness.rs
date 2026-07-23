//! Kani harness for ADR consequence entailment.
//!
//! Verifies bounded instances of consequence checking:
//! 1. Empty consequences are always invalid.
//! 2. Non-empty context + decision + consequence is sound.
//! 3. Every accepted ADR has at least one link.

#[derive(Debug, Clone)]
struct AdrRecord {
    id_value: u32,
    context_nonempty: bool,
    decision_nonempty: bool,
    consequences_len: u8,
    links_len: u8,
    status: u8, // 0=Proposed, 1=Accepted, 2=Deprecated, 3=Superseded
}

impl AdrRecord {
    fn valid(&self) -> bool {
        self.id_value > 0
            && self.context_nonempty
            && self.decision_nonempty
            && self.consequences_len > 0
            && (self.status != 1 || self.links_len > 0)
    }

    fn accepted(&self) -> bool {
        self.status == 1
    }

    fn entails(&self, consequence_nonempty: bool) -> bool {
        self.context_nonempty && self.decision_nonempty && consequence_nonempty
    }
}

#[kani::proof]
fn consequence_nonempty_required() {
    let rec = AdrRecord {
        id_value: 1,
        context_nonempty: true,
        decision_nonempty: true,
        consequences_len: 0,
        links_len: 0,
        status: 0,
    };
    kani::assert(!rec.valid(), "ADRs with zero consequences are invalid");
}

#[kani::proof]
fn accepted_requires_link() {
    let rec = AdrRecord {
        id_value: 1,
        context_nonempty: true,
        decision_nonempty: true,
        consequences_len: 1,
        links_len: 0,
        status: 1, // Accepted
    };
    kani::assert(!rec.valid(), "Accepted ADRs must have at least one link");
}

#[kani::proof]
fn accepted_with_link_is_valid() {
    let rec = AdrRecord {
        id_value: 1,
        context_nonempty: true,
        decision_nonempty: true,
        consequences_len: 1,
        links_len: 1,
        status: 1, // Accepted
    };
    kani::assert(rec.valid(), "Accepted ADR with link and consequences should be valid");
}

#[kani::proof]
fn entailment_sound_for_nonempty_consequence() {
    let rec = AdrRecord {
        id_value: 1,
        context_nonempty: true,
        decision_nonempty: true,
        consequences_len: 1,
        links_len: 1,
        status: 1,
    };
    kani::assert(
        rec.entails(true),
        "Non-empty consequence is entailed by non-empty context+decision",
    );
}

#[kani::proof]
fn no_entailment_with_empty_context() {
    let rec = AdrRecord {
        id_value: 1,
        context_nonempty: false,
        decision_nonempty: true,
        consequences_len: 1,
        links_len: 1,
        status: 0,
    };
    kani::assert(
        !rec.entails(true),
        "Empty context breaks consequence entailment",
    );
}
