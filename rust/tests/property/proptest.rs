use prime_rust::completion::{complete, PartialSystem, MAX_TERMS};
use prime_rust::union_find::UnionFind;
use prime_rust::term::Term;

fn arb_partial_system(vars: u8) -> PartialSystem {
    let mut sys = PartialSystem::default();
    sys.vars = vars.min(MAX_TERMS as u8);
    sys
}

#[test]
fn completion_never_panics_zero_vars() {
    let sys = arb_partial_system(0);
    let _uf = complete(&sys);
}

#[test]
fn completion_never_panics_one_var() {
    let sys = arb_partial_system(1);
    let _uf = complete(&sys);
}

#[test]
fn completion_never_panics_max_vars() {
    let sys = arb_partial_system(MAX_TERMS as u8);
    let _uf = complete(&sys);
}

#[test]
fn completion_size_bounded() {
    for v in 0..=8u8 {
        let sys = arb_partial_system(v);
        let uf = complete(&sys);
        assert!(uf.size <= MAX_TERMS);
    }
}

#[test]
fn completion_preserves_variables_count() {
    for v in 0..=8u8 {
        let sys = arb_partial_system(v);
        let uf = complete(&sys);
        assert!(uf.size >= v as usize);
    }
}

#[test]
fn completion_deterministic() {
    let sys = arb_partial_system(5);
    let uf1 = complete(&sys);
    let uf2 = complete(&sys);
    assert_eq!(uf1.size, uf2.size);
}

#[test]
fn union_find_reflexivity() {
    let mut uf = UnionFind::new();
    let a = uf.add_node(Term::Var(0));
    assert!(uf.equivalent(a, a));
}

#[test]
fn union_find_symmetry() {
    let mut uf = UnionFind::new();
    let a = uf.add_node(Term::Var(0));
    let b = uf.add_node(Term::Var(1));
    uf.union(a, b);
    assert!(uf.equivalent(b, a));
}

#[test]
fn union_find_transitivity() {
    let mut uf = UnionFind::new();
    let a = uf.add_node(Term::Var(0));
    let b = uf.add_node(Term::Var(1));
    let c = uf.add_node(Term::Var(2));
    uf.union(a, b);
    uf.union(b, c);
    assert!(uf.equivalent(a, c));
}

#[test]
fn union_find_commutativity() {
    let mut uf1 = UnionFind::new();
    let mut uf2 = UnionFind::new();
    let a1 = uf1.add_node(Term::Var(0));
    let b1 = uf1.add_node(Term::Var(1));
    let a2 = uf2.add_node(Term::Var(0));
    let b2 = uf2.add_node(Term::Var(1));
    uf1.union(a1, b1);
    uf2.union(b2, a2);
    assert_eq!(uf1.equivalent(a1, b1), uf2.equivalent(a2, b2));
}

#[test]
fn union_find_idempotent_union() {
    let mut uf = UnionFind::new();
    let a = uf.add_node(Term::Var(0));
    let b = uf.add_node(Term::Var(1));
    assert!(uf.union(a, b));
    assert!(!uf.union(a, b));
}
