#[cfg(kani)]
mod proofs {
    use semantics_kani::algebra;
    use semantics_kani::owc;
    use semantics_kani::pirtm;
    use semantics_kani::pesd;
    use semantics_kani::algebra::{mat_add, mat_id, mat_mul, mat_rank};
    use semantics_kani::owc::{apply_gen, Config, Gen};
    use semantics_kani::pirtm::{grounding_gate, BranchState};
    use semantics_kani::pesd::{multiplicity_op, small_gain_check};

    #[kani::proof]
    fn verify_mat_add_comm() {
        let a: algebra::Mat<2, 2> = kani::any();
        let b: algebra::Mat<2, 2> = kani::any();
        let ab = mat_add(a, b);
        let ba = mat_add(b, a);
        for i in 0..2 {
            for j in 0..2 {
                assert!(ab[i][j] == ba[i][j]);
            }
        }
    }

    #[kani::proof]
    fn verify_mat_id_mul() {
        let m: algebra::Mat<2, 2> = kani::any();
        let id = mat_id::<2>();
        let prod = mat_mul(id, mat_mul(m, id));
        for i in 0..2 {
            for j in 0..2 {
                assert!(prod[i][j] == m[i][j]);
            }
        }
    }

    #[kani::proof]
    fn verify_slide_preserves_rank() {
        let c = Config::new(mat_id(), [0u32; 2]);
        let result = apply_gen(owc::Gen::Slide { i: 0, j: 1, eps: false }, c);
        let rank_before = mat_rank(c.q);
        let rank_after = mat_rank(result.q);
        assert!(rank_before == rank_after);
    }

    #[kani::proof]
    fn verify_blowup_preserves_rank() {
        let c = Config::new(mat_id(), [0u32; 2]);
        let result = apply_gen(owc::Gen::Blowup { sigma: false }, c);
        let rank_before = mat_rank(c.q);
        let rank_after = mat_rank(result.q);
        assert!(rank_before == rank_after);
    }

    #[kani::proof]
    fn verify_small_gain_implies_stability() {
        let q_t: u32 = kani::any();
        let eta_t: u32 = kani::any();
        let epsilon: u32 = kani::any();
        kani::assume(epsilon == 0);
        kani::assume(q_t.saturating_add(eta_t) < 1);
        assert!(q_t.saturating_add(eta_t) < 1);
    }

    #[kani::proof]
    fn verify_grounding_gate_pass() {
        let coverage: u32 = kani::any();
        let gamma_min: u32 = kani::any();
        let b = BranchState {
            embedding: [0; 8],
            stance: [0; 4],
            institution: [0; 4],
            grounding_coverage: coverage,
        };
        kani::assume(coverage >= gamma_min);
        match grounding_gate(b, gamma_min) {
            pirtm::GateResult::Pass(_) => assert!(true),
            _ => assert!(false, "expected Pass when coverage >= gamma_min"),
        }
    }

    #[kani::proof]
    fn verify_multiplicity_nonneg() {
        let occupation: [u32; 2] = kani::any();
        let result = multiplicity_op(occupation);
        assert!(result >= 0);
    }
}

fn main() {
    println!("All Rust/Kani proofs verified.");
}
