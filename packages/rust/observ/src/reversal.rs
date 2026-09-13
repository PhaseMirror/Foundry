//! Reversal-space coding (ADR-0024, ADR-0027 §3): Walsh–Hadamard characters as
//! exact rationals over integer cubes.
//!
//! The factorial contrast expansion
//!
//! Î_A = 2^{-N} ∑_{s ∈ {±1}^N} (∏_{i∈A} s_i) y(s)
//!
//! represents a reversal channel as a sequence of integer characters over the
//! (ℤ₂)^N reversal group. Because the cube `y` is integer and the sign weights
//! are ±1, each coefficient is an exact n/2^N rational — no float, no
//! tolerance. The path-consistency gate enforces that the declared reversal
//! maps r_i are involutions (`r_i² = I`) and mutually commute
//! (`rᵢ rⱼ = rⱼ rᵢ`), the (ℤ₂)^N group-law premise for the expansion.

use crate::la::{self, Row};
use crate::rat::Q;
use crate::system::ReversalCube;

pub struct WalshReport {
    pub n: usize,
    /// Exact coefficient Î_A keyed by mask.
    pub coefficients: Vec<(u64, Q)>,
    /// Whether the reversal maps form an involution-and-commuting set.
    pub group_characters_valid: bool,
    /// Masks declared forbidden that carry a non-zero character (leakage).
    pub forbidden_leaks: Vec<u64>,
}

fn sign_pattern(mask: u64, sector: u64) -> i128 {
    // bit i of `mask` set => s_i = −1, else +1; sector A contributes (−1)^{|A∩mask|}.
    let inter = (mask & sector).count_ones() as i128;
    if inter % 2 == 0 {
        1
    } else {
        -1
    }
}

/// Exact Walsh–Hadamard expansion of an integer cube.
pub fn walsh(rv: &ReversalCube) -> WalshReport {
    let n = rv.n;
    let size = 1usize << n;
    let den = Q::from_i128(size as i128);
    let mut coefficients: Vec<(u64, Q)> = Vec::with_capacity(size);
    for sector in 0..size as u64 {
        let mut num = 0i128;
        for mask in 0..size as u64 {
            num += sign_pattern(mask, sector) * rv.cube[mask as usize] as i128;
        }
        let c = Q::new(num, den.n);
        coefficients.push((sector, c));
    }
    let forbidden_leaks = rv
        .forbidden_masks
        .iter()
        .filter(|&&m| {
            coefficients
                .iter()
                .any(|&(s, ref c)| s == m && !c.is_zero())
        })
        .copied()
        .collect();
    WalshReport {
        n,
        coefficients,
        group_characters_valid: group_is_valid(rv),
        forbidden_leaks,
    }
}

/// r_i² = I and rᵢ rⱼ = rⱼ rᵢ over Q (exact).
pub fn group_is_valid(rv: &ReversalCube) -> bool {
    let maps: Vec<Vec<Row>> = rv
        .reversal_maps
        .iter()
        .map(|m| crate::system::q_rows(m))
        .collect();
    for (i, ri) in maps.iter().enumerate() {
        let sq = la::matmul(ri, ri);
        if sq != la::identity(rv.state_dim) {
            return false;
        }
        for rj in maps.iter().skip(i + 1) {
            let ij = la::matmul(ri, rj);
            let ji = la::matmul(rj, ri);
            if ij != ji {
                return false;
            }
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::system::ReversalCube;

    fn cube(
        n: usize,
        values: Vec<i64>,
        maps: Vec<Vec<Vec<i64>>>,
        forbidden: Vec<u64>,
    ) -> ReversalCube {
        ReversalCube {
            n,
            cube: values,
            forbidden_masks: forbidden,
            state_dim: maps.first().map(|m| m.len()).unwrap_or(1),
            reversal_maps: maps,
        }
    }

    #[test]
    fn zero_cube_gives_zero_characters() {
        let rv = cube(
            2,
            vec![0, 0, 0, 0],
            vec![vec![vec![1, 0], vec![0, 1]]],
            vec![],
        );
        let rep = walsh(&rv);
        assert!(rep.coefficients.iter().all(|(_, c)| c.is_zero()));
    }

    #[test]
    fn single_bit_is_a_character() {
        // y(s) = s_0: characters: Î_empty = 0, Î_{0} = 1, Î_{1} = 0, Î_{01} = 0.
        let rv = cube(
            2,
            vec![1, -1, 1, -1],
            vec![vec![vec![1, 0], vec![0, 1]]],
            vec![],
        );
        let rep = walsh(&rv);
        let get = |m: u64| rep.coefficients.iter().find(|(s, _)| *s == m).unwrap().1;
        assert_eq!(get(0), Q::ZERO);
        assert_eq!(get(1), Q::ONE);
        assert_eq!(get(2), Q::ZERO);
        assert_eq!(get(3), Q::ZERO);
    }

    #[test]
    fn xor_product_carries_sector_two() {
        // y(s) = s_0 s_1: sector A = {0,1} has coefficient 1, all others 0.
        let rv = cube(
            2,
            vec![1, -1, -1, 1],
            vec![vec![vec![1, 0], vec![0, 1]]],
            vec![],
        );
        let rep = walsh(&rv);
        let get = |m: u64| rep.coefficients.iter().find(|(s, _)| *s == m).unwrap().1;
        assert_eq!(get(3), Q::ONE);
        assert_eq!(get(0), Q::ZERO);
        assert_eq!(get(1), Q::ZERO);
        assert_eq!(get(2), Q::ZERO);
    }

    #[test]
    fn forbidden_leakage_is_detected() {
        let rv = cube(
            2,
            vec![1, -1, -1, 1],
            vec![vec![vec![1, 0], vec![0, 1]]],
            vec![3],
        );
        let rep = walsh(&rv);
        assert_eq!(rep.forbidden_leaks, vec![3]);
    }

    #[test]
    fn non_commuting_maps_break_the_path_gate() {
        // σx and σz do NOT commute => group invalid.
        let sx = vec![vec![0, 1], vec![1, 0]];
        let sz = vec![vec![1, 0], vec![0, -1]];
        let rv = cube(2, vec![0, 0, 0, 0], vec![sx, sz], vec![]);
        assert!(!group_is_valid(&rv));
        let rep = walsh(&rv);
        assert!(!rep.group_characters_valid);
    }

    #[test]
    fn involutions_commute() {
        // Disjoint supports commute and are self-inverse: a swap on (0,1) and
        // a sign flip on axis 2.
        let r1 = vec![vec![0, 1, 0], vec![1, 0, 0], vec![0, 0, 1]];
        let r2 = vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, -1]];
        assert!(group_is_valid(&cube(
            2,
            vec![0, 0, 0, 0],
            vec![r1, r2],
            vec![]
        )));
    }
}
