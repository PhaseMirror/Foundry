//! The label / state-space index — the bijection `classIndex` and the belt.
//!
//! Realizes the `objects-labels` and `label-space-belt` dictionary rows.

use crate::params::UseCaseParams;
use alloc::vec::Vec;

/// Verify `classIndex` is a bijection of `{(h2,d,l)}` onto `[0, class_count)`.
///
/// This is the runtime analogue of F1's `classIndex_range`.
#[must_use]
pub fn class_index_is_bijection(p: &UseCaseParams) -> bool {
    let count = p.class_count();
    let Ok(count_usize) = usize::try_from(count) else {
        return false;
    };
    let mut hit = alloc::vec![false; count_usize];
    for h2 in 0..p.scope {
        for d in 0..p.modality {
            for l in 0..p.context {
                let Some(idx) = p.class_index(h2, d, l) else {
                    return false;
                };
                if idx >= count {
                    return false;
                }
                let slot = &mut hit[idx as usize];
                if *slot {
                    return false; // collision => not injective
                }
                *slot = true;
            }
        }
    }
    hit.into_iter().all(|seen| seen) // surjective onto [0, count)
}

/// The ordered list of belt addresses for one canonical factorization `(pages, page_size)`.
///
/// `beltAddr(λ, b) = page_size·λ + b`. The Atlas factorization `(48, 256)` yields
/// `0..12288`.
#[must_use]
pub fn belt_addresses(pages: u64, page_size: u64) -> Vec<u64> {
    let mut out = Vec::new();
    for lambda in 0..pages {
        for b in 0..page_size {
            out.push(page_size * lambda + b);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn atlas_classindex_is_a_bijection() {
        assert!(class_index_is_bijection(&UseCaseParams::new(4, 3, 8)));
    }

    #[test]
    fn arbitrary_instance_classindex_is_a_bijection() {
        assert!(class_index_is_bijection(&UseCaseParams::new(2, 2, 4)));
        assert!(class_index_is_bijection(&UseCaseParams::new(5, 1, 3)));
    }

    #[test]
    fn belt_addresses_are_contiguous() {
        let addrs = belt_addresses(48, 256);
        assert_eq!(addrs.len(), 12288);
        assert_eq!(addrs.first(), Some(&0));
        assert_eq!(addrs.last(), Some(&12287));
    }
}
