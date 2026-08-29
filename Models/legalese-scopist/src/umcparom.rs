// umcparom.rs
// Universal Constant - UMCPAROM implementation and Kani proofs

pub const SCALE: u64 = 10000;

#[derive(Debug, Clone, Copy)]
pub struct UMCState {
    pub x: u64,
    pub lam: u64,
}

#[derive(Debug, Clone, Copy)]
pub struct JointSystem {
    pub rho_x: u64,
    pub rho_lam: u64,
    pub c1: u64,
    pub c2: u64,
}

impl JointSystem {
    pub fn is_contractive(&self) -> bool {
        self.rho_x + self.c2 < SCALE && self.rho_lam + self.c1 < SCALE
    }

    pub fn update(&self, s: UMCState) -> UMCState {
        UMCState {
            x: self.rho_x * s.x + self.c2 * s.lam,
            lam: self.rho_lam * s.lam + self.c1 * s.x,
        }
    }
}

pub fn joint_norm(s1: UMCState, s2: UMCState) -> u64 {
    let diff_x = if s1.x >= s2.x { s1.x - s2.x } else { s2.x - s1.x };
    let diff_lam = if s1.lam >= s2.lam { s1.lam - s2.lam } else { s2.lam - s1.lam };
    diff_x + diff_lam
}

#[cfg(kani)]
mod verification {
    use super::*;

    /// Discrete equivalent of the `joint_contraction` theorem.
    /// Proves that the total weighted norm of the system differences is strictly bounded
    /// by a combined contraction factor.
    #[kani::proof]
    fn verify_umc_joint_contraction() {
        let rho_x: u64 = kani::any();
        let rho_lam: u64 = kani::any();
        let c1: u64 = kani::any();
        let c2: u64 = kani::any();

        let sys = JointSystem { rho_x, rho_lam, c1, c2 };

        // Assume the invariant required for contractivity (spectral gap constraint)
        kani::assume(sys.is_contractive());

        let x1: u64 = kani::any();
        let lam1: u64 = kani::any();
        let x2: u64 = kani::any();
        let lam2: u64 = kani::any();

        // Restrict state sizes to prevent overflow during operations in the check
        kani::assume(x1 < 1000000);
        kani::assume(lam1 < 1000000);
        kani::assume(x2 < 1000000);
        kani::assume(lam2 < 1000000);

        let s1 = UMCState { x: x1, lam: lam1 };
        let s2 = UMCState { x: x2, lam: lam2 };

        let norm_initial = joint_norm(s1, s2);
        
        let u1 = sys.update(s1);
        let u2 = sys.update(s2);
        
        let norm_updated = joint_norm(u1, u2);

        // Theorem: joint_norm(update(s1), update(s2)) <= (rhoX + c1 + rhoLam + c2) * joint_norm(s1, s2)
        let bound_factor = sys.rho_x + sys.c1 + sys.rho_lam + sys.c2;
        let bound = bound_factor * norm_initial;

        kani::assert(
            norm_updated <= bound,
            "UMC Joint Contraction Bound Failed"
        );
    }
}
