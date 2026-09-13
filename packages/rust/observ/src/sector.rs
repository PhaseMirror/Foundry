//! Reference-sector algebra (ADR-0023: δJ7 symmetry-complement source
//! sectors; ADR-0022 polarization-even/odd channels).
//!
//! Implements the group-averaged projector
//!
//! P = (1/|G|) ∑_g ρ(g)
//!
//! on an operator space, its invariant and complement subspaces, the `A_null`
//! certificate entry (target channel vanishes on the invariant sector), the
//! parity covariance check `F_O(ρ_g λ) = χ_O(g) F_O(λ)` for an odd direction
//! λ ∈ ker P, and the accumulated admissibility certificate
//! `A = A_ind ∧ A_state ∧ A_null ∧ A_no_retune`.

use crate::la::{self, Row};
use crate::rat::Q;
use crate::system::{AdmissibilityDecl, Reference};

pub struct SectorReport {
    pub operator_dim: usize,
    pub group_size: usize,
    /// Basis of the invariant sector `im P`.
    pub invariant_dim: usize,
    /// Basis of the complement sector `ker P`.
    pub complement_dim: usize,
    /// True when the target channel O vanishes on the invariant sector.
    pub a_null: bool,
    /// True when the declared odd direction lives in ker P.
    pub odd_in_complement: bool,
    /// True when some element maps it to its negation.
    pub odd_flipped: bool,
    /// True when the parity covariance holds on the declared character.
    pub parity_holds: bool,
    /// Full certificate A = A_ind ∧ A_state ∧ A_null ∧ A_no_retune.
    pub admissible: bool,
}

pub struct ProjectorResult {
    pub projector: Vec<Row>,
    pub invariant: Vec<Row>,
    pub complement: Vec<Row>,
}

/// Group-averaged projector and its eigenspaces.
pub fn reference_projector(r: &Reference) -> Result<ProjectorResult, String> {
    let n = r.operator_dim;
    let g_mats: Vec<Vec<Row>> = r.group.iter().map(|m| crate::system::q_rows(m)).collect();
    if g_mats.is_empty() {
        return Err("reference group is empty".into());
    }
    // P = (1/|G|) Σ_g ρ(g): average matrices coefficient-wise.
    let mut p: Vec<Row> = vec![vec![Q::ZERO; n]; n];
    for g in &g_mats {
        for (grow, prow) in g.iter().zip(p.iter_mut()) {
            for (a, b) in grow.iter().zip(prow.iter_mut()) {
                *b = *b + *a;
            }
        }
    }
    let inv = Q::new(1, g_mats.len() as i128);
    for row in p.iter_mut() {
        for v in row.iter_mut() {
            *v = *v * inv;
        }
    }

    // Invariant sector = column space of P; complement = kernel of P.
    let invariant = la::image_basis(&p);
    let complement = la::kernel_basis(&p);
    Ok(ProjectorResult {
        projector: p,
        invariant,
        complement,
    })
}

/// Full reference analysis and certificate evaluation.
pub fn analyze_reference(
    r: &Reference,
    label: &str,
) -> Result<(SectorReport, ProjectorResult), String> {
    let pr = reference_projector(r)?;
    let n = r.operator_dim;
    let o: Vec<Row> = crate::system::q_rows(&r.target);
    let lam: Row = r
        .odd_direction
        .iter()
        .map(|&v| crate::system::q_of(v))
        .collect();
    let g_mats: Vec<Vec<Row>> = r.group.iter().map(|m| crate::system::q_rows(m)).collect();

    // A_null: O · P == 0 (target operator has no invariant weight).
    let op: Vec<Row> = la::matmul(&o, &pr.projector);
    let a_null = op.iter().all(|row| row.iter().all(Q::is_zero));

    // Odd direction lives in the complement (λ ∈ ker P).
    let odd_in_complement = la::vector_in_span(&pr.complement, &lam);

    // Some element flips it: ρ_g λ = −λ.
    let odd_flipped = g_mats.iter().any(|g| la::apply(g, &lam) == neg_vec(&lam));

    // Parity covariance: F_O(ρ_g λ) == χ_O(g) F_O(λ) for every g.
    // F_O(v) := O·v (target covector applied to direction).
    let apply_o = |v: &Row| -> Row { la::apply(&o, v) };
    let f_base = apply_o(&lam);
    let parity_holds = g_mats.iter().zip(r.characters.iter()).all(|(g, &chi)| {
        let flipped = la::apply(g, &lam);
        let rhs = {
            let mut v = f_base.clone();
            for x in v.iter_mut() {
                *x = *x * Q::from_i128(chi as i128);
            }
            v
        };
        apply_o(&flipped) == rhs
    });

    let adm = AdmissibilityDecl {
        independent: r.declared.independent,
        state: r.declared.state,
        no_retune: r.declared.no_retune,
    };
    let admissible = adm.independent && adm.state && a_null && adm.no_retune;

    let report = SectorReport {
        operator_dim: n,
        group_size: r.group.len(),
        invariant_dim: pr.invariant.len(),
        complement_dim: pr.complement.len(),
        a_null,
        odd_in_complement,
        odd_flipped,
        parity_holds,
        admissible,
    };
    let _ = label;
    Ok((report, pr))
}

fn neg_vec(v: &[Q]) -> Vec<Q> {
    v.iter().map(|q| -*q).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::system::{AdmissibilityDecl, Reference};

    /// δJ7 geometry: operator space spanned by (J7a, J7b). Group Z2 = {+I, σx}
    /// (sublattice swap) averages onto the symmetric row (1,1); the complement
    /// direction (1,−1) is the odd δJ7 channel killed by the reference.
    fn mnf2_reference() -> Reference {
        Reference {
            operator_dim: 2,
            group: vec![vec![vec![1, 0], vec![0, 1]], vec![vec![0, 1], vec![1, 0]]],
            target: vec![vec![1, -1]],
            declared: AdmissibilityDecl {
                independent: true,
                state: true,
                no_retune: true,
            },
            odd_direction: vec![1, -1],
            characters: vec![1, -1],
        }
    }

    #[test]
    fn projector_splits_even_and_odd() {
        let r = mnf2_reference();
        let (report, _) = analyze_reference(&r, "mnf2").unwrap();
        // Invariant direction (1,1) survives averaging; complement is odd.
        assert_eq!(report.invariant_dim, 1);
        assert_eq!(report.complement_dim, 1);
        // Target [1,-1] vanishes on the invariant axis => A_null holds.
        assert!(report.a_null);
        assert!(report.odd_in_complement);
        assert!(report.odd_flipped);
        assert!(report.parity_holds);
        assert!(report.admissible);
    }

    #[test]
    fn no_retune_loss_breaks_the_certificate() {
        let mut r = mnf2_reference();
        r.declared.no_retune = false;
        let (report, _) = analyze_reference(&r, "mnf2").unwrap();
        assert!(!report.admissible);
    }

    #[test]
    fn character_mismatch_catches_parity_breach() {
        let mut r = mnf2_reference();
        // Wrong character on the odd element: covariance fails.
        r.characters = vec![1, 1];
        let (report, _) = analyze_reference(&r, "mnf2").unwrap();
        assert!(!report.parity_holds);
    }
}
