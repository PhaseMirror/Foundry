#[cfg(test)]
mod tests {
    use prime_rust::completion::{complete, PartialSystem, UnionFind, Term, MAX_TERMS};
    use prime_rust::union_find::UnionFind as ModularUnionFind;
    use prime_rust::term::Term as ModularTerm;

    #[test]
    fn test_completion_preserves_variables() {
        let mut sys = PartialSystem::default();
        sys.vars = 3;

        let uf = complete(&sys);

        assert!(uf.size >= 3);
        for i in 0..3 {
            assert!(uf.terms[i].unwrap().is_var());
        }
    }

    #[test]
    fn test_composition_equivalence() {
        let mut sys = PartialSystem::default();
        sys.vars = 3;
        sys.comp_def[0] = (0, 1, Some(2));

        let mut uf = complete(&sys);

        let idx_xy = uf.get_index(Term::Comp(0, 1));
        let idx_z = uf.get_index(Term::Var(2));
        assert_eq!(uf.find(idx_xy), uf.find(idx_z));
    }

    #[test]
    fn test_closure_equivalence() {
        let mut sys = PartialSystem::default();
        sys.vars = 3;
        sys.close_def[0] = (0, Some(1));

        let mut uf = complete(&sys);

        let idx_close = uf.get_index(Term::Close(0));
        let idx_y = uf.get_index(Term::Var(1));
        assert_eq!(uf.find(idx_close), uf.find(idx_y));
    }

    #[test]
    fn test_congruence_closure() {
        let mut sys = PartialSystem::default();
        sys.vars = 3;
        sys.comp_def[0] = (0, 1, Some(2));
        sys.close_def[0] = (0, Some(1));

        let mut uf = complete(&sys);

        for i in 0..uf.size {
            for j in 0..uf.size {
                if uf.find(i) == uf.find(j) {
                    let ci = uf.get_index(Term::Close(i as u8));
                    let cj = uf.get_index(Term::Close(j as u8));
                    if ci < MAX_TERMS && cj < MAX_TERMS {
                        assert_eq!(uf.find(ci), uf.find(cj));
                    }
                }
            }
        }
    }

    #[test]
    fn test_empty_system() {
        let sys = PartialSystem::default();
        let uf = complete(&sys);
        assert_eq!(uf.size, 0);
    }

    #[test]
    fn test_no_composition_defined() {
        let mut sys = PartialSystem::default();
        sys.vars = 2;
        sys.comp_def[0] = (0, 1, None);

        let uf = complete(&sys);
        assert!(uf.size >= 2);
    }

    #[test]
    fn test_multiple_compositions() {
        let mut sys = PartialSystem::default();
        sys.vars = 4;
        sys.comp_def[0] = (0, 1, Some(2));
        sys.comp_def[1] = (2, 3, Some(0));

        let mut uf = complete(&sys);

        let idx_01 = uf.get_index(Term::Comp(0, 1));
        let idx_2 = uf.get_index(Term::Var(2));
        assert_eq!(uf.find(idx_01), uf.find(idx_2));
    }

    #[test]
    fn test_union_find_basic() {
        let mut uf = ModularUnionFind::new();
        let a = uf.add_node(ModularTerm::Var(0));
        let b = uf.add_node(ModularTerm::Var(1));
        let c = uf.add_node(ModularTerm::Var(2));

        assert!(!uf.equivalent(a, b));
        uf.union(a, b);
        assert!(uf.equivalent(a, b));
        assert!(!uf.equivalent(a, c));
    }

    #[test]
    fn test_union_find_path_compression() {
        let mut uf = ModularUnionFind::new();
        let a = uf.add_node(ModularTerm::Var(0));
        let b = uf.add_node(ModularTerm::Var(1));
        let c = uf.add_node(ModularTerm::Var(2));

        uf.union(a, b);
        uf.union(b, c);

        assert!(uf.equivalent(a, c));
        assert_eq!(uf.num_classes(), 1);
    }

    #[test]
    fn test_union_find_rank() {
        let mut uf = ModularUnionFind::new();
        let mut nodes = Vec::new();
        for i in 0..8 {
            nodes.push(uf.add_node(ModularTerm::Var(i)));
        }

        for i in 0..7 {
            uf.union(nodes[i], nodes[i + 1]);
        }

        assert_eq!(uf.num_classes(), 1);
    }
}
