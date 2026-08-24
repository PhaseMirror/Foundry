//! Mirror of `Multiplicity/FPES/{Core,Proofs}.lean` (ADR-0029).
//!
//! Bounded fixed-array model of the FPES combinatorial core:
//!
//!   | Lean (`Core.lean`)           | Rust (this file)                |
//!   |------------------------------|----------------------------------|
//!   | `countInClass`               | `count_in_class`                |
//!   | `firstPath`                  | `first_path`                    |
//!   | `repsGo` / `representatives` | `representatives`               |
//!   | `multiplicity_nonzero`       | `kani_fpes_001_multiplicity_nonzero` |
//!   | `representatives_..._preserving` | `kani_fpes_002_contraction_preserves_multiplicity` |
//!
//! Per `contracts/fpes.yaml`: `bounds.max_paths = 8`, `max_classes = 8`,
//! `unwind = 9`.  The ℝ-norm part of the ADR (`operator_norm < 1`) is
//! deliberately **not** mirrored here (`strategy:
//! stub_float_on_transcendentals`); this harness is the in-crate placeholder
//! for the production `multiplicity-core` FPES kernel.

use core::fmt;

const MAX_PATHS: usize = 8;
const MAX_CLASSES: usize = 8;

/// A path: an experiment-selection trajectory.  `cls` is the id of the
/// equivalence class it probes.  Mirror of `FPES.Path`.
#[derive(Clone, Copy, PartialEq, Eq, kani::Arbitrary)]
struct Path {
    id: u8,
    cls: u8,
}

impl fmt::Debug for Path {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Path{{id: {}, cls: {}}}", self.id, self.cls)
    }
}

/// An equivalence class of mechanisms.  Mirror of `FPES.EquivalenceClass`.
#[derive(Clone, Copy, PartialEq, Eq, kani::Arbitrary)]
struct Class {
    id: u8,
}

impl fmt::Debug for Class {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Class{{id: {}}}", self.id)
    }
}

/// `count_in_class`: number of paths in `paths[..len]` probing `cls`.
/// Mirror of `FPES.countInClass` (inductive recurrence over the finite list).
fn count_in_class(paths: &[Path; MAX_PATHS], len: usize, cls: u8) -> u32 {
    let mut n: u32 = 0;
    for i in 0..len {
        if paths[i].cls == cls {
            n += 1;
        }
    }
    n
}

/// `first_path`: the first path of `paths[..len]` probing `cls`, if any.
/// Mirror of `FPES.firstPath`.
fn first_path(paths: &[Path; MAX_PATHS], len: usize, cls: u8) -> Option<Path> {
    for i in 0..len {
        if paths[i].cls == cls {
            return Some(paths[i]);
        }
    }
    None
}

/// `representatives`: one path per class, in class order — the canonical
/// falsification-preserving contraction.  Mirror of `FPES.repsGo` +
/// `FPES.representatives`.  Returns the packed representative list and its
/// logical length.
fn representatives(
    classes: &[Class; MAX_CLASSES],
    ncls: usize,
    paths: &[Path; MAX_PATHS],
    npaths: usize,
) -> ([Path; MAX_PATHS], usize) {
    let mut reps: [Path; MAX_PATHS] = [Path { id: 0, cls: 0 }; MAX_PATHS];
    let mut n: usize = 0;
    for i in 0..ncls {
        if let Some(p) = first_path(paths, npaths, classes[i].id) {
            reps[n] = p;
            n += 1;
        }
    }
    (reps, n)
}

/// **KANI-FPES-001 — `FPES-MULTIPLICITY-001` (bounded).**
///
/// Mirror of `Multiplicity.FPES.Proofs.firstPath_eq_none_iff` /
/// `firstPath_some_of_count_pos`: `first_path` is non-`None` exactly when
/// `count_in_class ≥ 1`.  This is the implementation-level witness of
/// "every registered class with positive multiplicity has a representative",
/// and it is the correspondence the Lean layer proves unboundedly.
#[kani::proof]
#[kani::unwind(9)]
fn kani_fpes_001_multiplicity_nonzero() {
    let npaths: usize = kani::any();
    kani::assume(npaths <= MAX_PATHS);
    let paths: [Path; MAX_PATHS] = kani::any();
    let cls: u8 = kani::any();

    let cnt = count_in_class(&paths, npaths, cls);
    let fp = first_path(&paths, npaths, cls);

    // firstPath is some  iff  count >= 1
    assert!(fp.is_some() == (cnt >= 1));
    // (trivial consequences the Lean theorem states directly)
    if cnt >= 1 {
        assert!(fp.is_some());
        assert!(fp.unwrap().cls == cls);
    } else {
        assert!(fp.is_none());
    }
}

/// **KANI-FPES-002 — `FPES-SURVIVAL-002` (bounded).**
///
/// Mirror of `Multiplicity.FPES.Proofs.representatives_falsification_preserving`:
/// after contracting to one representative per class, every class that had
/// ≥ 1 path in the original space still has ≥ 1 path among the
/// representatives.  Bounded: `|Paths| ≤ 8`, `|Classes| ≤ 8`.
#[kani::proof]
#[kani::unwind(9)]
fn kani_fpes_002_contraction_preserves_multiplicity() {
    let ncls: usize = kani::any();
    let npaths: usize = kani::any();
    kani::assume(ncls <= MAX_CLASSES);
    kani::assume(npaths <= MAX_PATHS);
    let classes: [Class; MAX_CLASSES] = kani::any();
    let paths: [Path; MAX_PATHS] = kani::any();

    let (reps, nreps) = representatives(&classes, ncls, &paths, npaths);

    for i in 0..ncls {
        let c = classes[i].id;
        let before = count_in_class(&paths, npaths, c);
        if before >= 1 {
            assert!(count_in_class(&reps, nreps, c) >= 1);
        }
    }
}
