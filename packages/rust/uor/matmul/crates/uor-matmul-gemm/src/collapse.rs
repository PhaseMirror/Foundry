//! The collapse traversal: charge per distinct meaning, not per expression.
//!
//! Every other traversal in this library issues `m * k * n` products, whatever
//! the operands hold. That is not a property of the identity --- it is a
//! property of how the identity has been walked. Two equal rows of `A` name the
//! same sum against every column of `B`, so a driver that computes both has
//! computed one thing twice.
//!
//! This traversal computes each *distinct* row once. It is the same identity
//! (`R13`): decode the code, accumulate exactly, encode once --- with the
//! accumulation performed once per distinct row rather than once per row.
//! `CD-12` asserts it byte-identical to the packed and streaming traversals at
//! every degeneracy, including none.
//!
//! # Why an exact library may do this and a classical one may not
//!
//! Sharing a result between two rows is sound exactly when the two rows name
//! the same value, and here they do: the sum is over a declared alphabet, taken
//! exactly, with no rounding step between the products and the single encode.
//! A classical `sgemm` sharing a row would also have to argue that its *order*
//! of additions was the same, because its answer depends on that order. This
//! one has nothing to argue: an exact sum is a function of the multiset of
//! products, so equal operands give equal sums by definition rather than by
//! accident.
//!
//! # Columns
//!
//! Sharing is not always on the `A` side. It does not need a second traversal:
//! `(A * B)^T = B^T * A^T`, transposition is a stride, and equal columns of `B`
//! are equal rows of `B^T` --- so collapsing them is this traversal applied to
//! [`Triple::transposed`], with the same pass, the same compaction, and the same
//! expansion. One walks the output's rows and the other its columns, which is
//! the only difference and is entirely a question of the output's strides.
//!
//! # An offer, never a requirement
//!
//! Like [`crate::Scratch`], collapse is memory the caller offers. Offering none
//! runs the packed traversal, and offering too little to hold what the pass
//! finds runs the packed traversal --- the same bytes either way, which is what
//! `CD-12` asserts. This is the one traversal whose selection reads the
//! operand's *content*, and the caller's offer is the invitation to read it: a
//! caller who knows their `A` has no repeated rows offers nothing and pays
//! nothing.
//!
//! # What it costs when it finds nothing
//!
//! One pass over `A`: `m * k` reads against the product's `m * k * n`, so a
//! `1/n` share, and it is charged honestly rather than hidden --- `CG-09`
//! reports the throughput at degeneracy one beside the throughput at the
//! degeneracies it exists for.

use core::hash::{Hash, Hasher};

use uor_matmul_core::{
    AccOf, Alphabet, Bound, Element, EncodeFrom, IntegerElement, MatView, Shape, Triple,
};

use crate::driver::GemmOptions;
use crate::epilogue::Epilogue;
use crate::kernel::{gemm_packed, Kernelized};
use crate::scratch::Scratch;

/// Working memory for the collapse traversal, offered by the caller.
///
/// Two buffers, for the two things the pass produces: an index that says which
/// distinct row each row of `A` is, and room to hold those distinct rows.
///
/// Neither is a requirement. A short offer of either is answered by the packed
/// traversal at the same bytes, and there is no error to report (`CD-12`).
#[derive(Debug)]
pub struct Collapse<'s, E: IntegerElement, Bd: Bound> {
    index: &'s mut [usize],
    rows: &'s mut [Alphabet<E, Bd>],
}

impl<'s, E: IntegerElement, Bd: Bound> Collapse<'s, E, Bd> {
    /// Offer an index buffer and room for the distinct rows.
    ///
    /// See [`suggested_collapse_index`] and [`suggested_collapse_rows`] for the
    /// amounts, both of which are queries rather than requirements.
    pub fn new(index: &'s mut [usize], rows: &'s mut [Alphabet<E, Bd>]) -> Self {
        Self { index, rows }
    }

    /// Offer nothing. The packed traversal runs, at the same bytes.
    pub fn none() -> Collapse<'static, E, Bd> {
        Collapse {
            index: &mut [],
            rows: &mut [],
        }
    }
}

/// How large an index buffer lets the pass run at `m` rows.
///
/// A *query*, not a requirement. The buffer holds one slot per row --- which
/// distinct row that row is --- and an open-addressed table over the distinct
/// rows found so far, sized so that it is never more than half full and a probe
/// therefore always terminates on an empty slot.
pub fn suggested_collapse_index(m: usize) -> usize {
    if m == 0 {
        return 0;
    }
    let table = m.saturating_mul(2).next_power_of_two();
    m.saturating_add(table.saturating_mul(2))
}

/// How much room holds the distinct rows of an `m x k` operand.
///
/// A *query*, not a requirement, and the worst case rather than the expectation:
/// `m * k` is what an `A` with no two equal rows would need. A caller who
/// expects `d` distinct rows offers `d * k` and gets the collapse traversal when
/// that is enough and the packed traversal when it is not --- the same bytes
/// either way, so the offer is a throughput choice and never a correctness one.
pub fn suggested_collapse_rows(shape: Shape) -> usize {
    shape.m.saturating_mul(shape.k)
}

/// `C := epilogue(A * B, C)`, computing one output row per distinct row of `A`.
///
/// Returns `()`, for the same reason [`crate::gemm`] does: nothing about the
/// data, the offer, or the host can make this fail. An offer too small for what
/// the pass finds is not a condition to report --- it selects the packed
/// traversal, which gives the same bytes.
///
/// # What decides
///
/// - An epilogue that reads `C` runs the packed traversal. Two rows with equal
///   rows of `A` still have different outputs when the `C` they read differs, so
///   there is nothing to share. That is a question about the epilogue's own
///   declaration ([`Epilogue::reads_c`]) and not about the data.
/// - An `A` whose rows are pairwise distinct runs the packed traversal, having
///   paid the pass.
///
/// # Examples
///
/// ```
/// # use uor_matmul_core::{as_alphabet_full, Alphabet, Full, MatView, MatViewMut, Shape, Triple};
/// # use uor_matmul_gemm::{
/// #     gemm_collapsed, suggested_collapse_index, suggested_collapse_rows, Collapse, GemmOptions,
/// #     Linear, Scratch,
/// # };
/// // Four rows, two meanings.
/// let a = [1i8, 2, 3, 4, 1, 2, 3, 4];
/// let b = [1i8, 0, 0, 1, 1, 0, 0, 1];
/// let mut c = [0i32; 8];
///
/// let shape = Shape { m: 4, k: 2, n: 2 };
/// let mut index = vec![0usize; suggested_collapse_index(shape.m)];
/// let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; suggested_collapse_rows(shape)];
///
/// let av = MatView::row_major(as_alphabet_full(&a), 4, 2).unwrap();
/// let bv = MatView::row_major(as_alphabet_full(&b), 2, 2).unwrap();
/// let cv = MatViewMut::row_major(&mut c, 4, 2).unwrap();
/// let mut t = Triple::new(av, bv, cv).unwrap();
///
/// gemm_collapsed(
///     &mut t,
///     &Linear::OVERWRITE,
///     GemmOptions::default(),
///     &mut Scratch::none(),
///     &mut Collapse::new(&mut index, &mut rows),
/// );
/// assert_eq!(c, [1, 2, 3, 4, 1, 2, 3, 4]);
/// ```
pub fn gemm_collapsed<E, Bd, O, Ep>(
    triple: &mut Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    epilogue: &Ep,
    options: GemmOptions,
    scratch: &mut Scratch<'_, E, Bd>,
    collapse: &mut Collapse<'_, E, Bd>,
) where
    E: Kernelized + Hash,
    Bd: Bound,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
{
    let shape = triple.shape();

    // An epilogue that reads `C` gives two rows different answers from the same
    // row of `A`, so there is no shared meaning to find. A declaration, read
    // once.
    if epilogue.reads_c() || shape.m == 0 || shape.n == 0 {
        gemm_packed(triple, epilogue, options, scratch);
        return;
    }

    // Two steps, in this order, because the first is what tells the second
    // whether it is worth doing. The pass copies nothing: it numbers the rows,
    // and only an operand that turns out to have shared meanings pays to have
    // them written out.
    let found = distinct_rows(triple.a(), collapse.index)
        .filter(|&d| d < shape.m)
        .filter(|&d| compact(triple.a(), collapse.index, collapse.rows, d));

    // `None` is a short offer or an `A` with no two equal rows. Both are the
    // packed traversal, and both give the bytes it gives.
    let Some(d) = found else {
        gemm_packed(triple, epilogue, options, scratch);
        return;
    };

    // The compacted product is a product in its own right: `d x k` against the
    // same `B`, written to the first `d` rows of the same `C`. It takes the same
    // traversal choice, the same kernel table, and the same offer as any other.
    let compacted = {
        let a = MatView::row_major(&collapse.rows[..d * shape.k], d, shape.k);
        let b = *triple.b();
        match (a, triple.c_mut().top_rows(d)) {
            (Some(a), Some(c)) => Triple::new(a, b, c).ok(),
            _ => None,
        }
    };
    let Some(mut compacted) = compacted else {
        // The compacted product does not exist, which the arithmetic above says
        // it always does. Naming it is still the only place a condition could
        // arise, so it is answered the way every other offer is.
        gemm_packed(triple, epilogue, options, scratch);
        return;
    };
    gemm_packed(&mut compacted, epilogue, options, scratch);

    // Expand, from the bottom. The distinct row a row resolves to was numbered
    // in order of first occurrence, so `index[i] <= i` for every `i` --- and a
    // descending walk therefore reads each compacted row before the step that
    // overwrites it. No copy of `C` is needed and none is made.
    // Which loop is inner is decided by the output's own strides, not by the
    // order the rows are written in. Every column is independent --- the
    // descending walk is what matters and it is preserved either way --- so the
    // inner loop is free to be whichever axis is the near one. It matters: the
    // *transposed* triple names the rows of `C^T`, which for a row-major `C` are
    // its columns, and walking them outermost reads a cache line per cell.
    let c = triple.c_mut();
    let strides = c.strides();
    let index = &collapse.index[..shape.m];
    if strides.cs == 1 {
        // A row is a run, so replicating one is a move of that run. Called for
        // its effect and not inside an assertion: `debug_assert!` does not
        // evaluate its argument in a release build, which is a way to write a
        // move that only happens in the tests.
        for i in (0..shape.m).rev() {
            let from = index[i];
            if from != i && !c.copy_row(from, i) {
                for j in 0..shape.n {
                    let value = *c.at(from, j);
                    *c.at_mut(i, j) = value;
                }
            }
        }
    } else if strides.rs.unsigned_abs() < strides.cs.unsigned_abs() {
        // The row axis is the near one: walk it innermost.
        for j in 0..shape.n {
            for i in (0..shape.m).rev() {
                let from = index[i];
                if from != i {
                    let value = *c.at(from, j);
                    *c.at_mut(i, j) = value;
                }
            }
        }
    } else {
        for i in (0..shape.m).rev() {
            let from = index[i];
            if from == i {
                continue;
            }
            for j in 0..shape.n {
                let value = *c.at(from, j);
                *c.at_mut(i, j) = value;
            }
        }
    }
}

/// Number each row of `A` by the *first* row equal to it, and count how many
/// distinct rows there are.
///
/// Returns `None` when the index offer does not cover the table. Copies nothing:
/// an operand whose rows are pairwise distinct pays one pass over `A` and no
/// writes at all, which is what makes the price of looking a share of the
/// product rather than a multiple of the operand.
///
/// The hash decides who is *compared*; it never decides who is equal. Every
/// match is confirmed element by element against the operand itself, so a
/// collision costs a comparison and can change nothing about the answer --- the
/// same discipline the upstream content addressing uses, where `kappa`'s
/// injectivity is verified on the materialized set rather than assumed.
fn distinct_rows<E, Bd>(a: &MatView<'_, Alphabet<E, Bd>>, index: &mut [usize]) -> Option<usize>
where
    E: IntegerElement + Hash,
    Bd: Bound,
{
    let (m, k) = (a.rows(), a.cols());
    if m == 0 || k == 0 {
        return None;
    }
    // Half full at worst, so an empty slot always exists and a probe always
    // terminates.
    let table = m.checked_mul(2)?.next_power_of_two();
    if index.len() < m.checked_add(table.checked_mul(2)?)? {
        return None;
    }
    let (position, rest) = index.split_at_mut(m);
    let (slot, key) = rest.split_at_mut(table);
    // Zero is "empty"; a slot holds one more than the row it names.
    slot[..table].fill(0);
    let mask = table - 1;

    let mut distinct = 0usize;
    for (i, position) in position.iter_mut().enumerate() {
        let hash = row_hash(a, i, k);
        let mut probe = hash & mask;
        loop {
            match slot[probe] {
                0 => {
                    slot[probe] = i + 1;
                    key[probe] = hash;
                    *position = i;
                    distinct += 1;
                    break;
                }
                held => {
                    let candidate = held - 1;
                    if key[probe] == hash && rows_equal(a, candidate, i, k) {
                        *position = candidate;
                        break;
                    }
                    probe = (probe + 1) & mask;
                }
            }
        }
    }
    Some(distinct)
}

/// Are rows `x` and `y` of `A` the same row?
///
/// The verdict, never the hash. When the operand's strides hand both rows back
/// as runs this is one slice comparison, which for a primitive element type is
/// the machine's own `memcmp` --- and measured that is the difference between
/// the comparison costing as much as the hash and costing a tenth of it.
fn rows_equal<E, Bd>(a: &MatView<'_, Alphabet<E, Bd>>, x: usize, y: usize, k: usize) -> bool
where
    E: IntegerElement,
    Bd: Bound,
{
    match (row_run(a, x, k), row_run(a, y, k)) {
        (Some(x), Some(y)) => x == y,
        _ => a
            .row_walk(x, 0, k)
            .zip(a.row_walk(y, 0, k))
            .all(|(x, y)| x.get() == y.get()),
    }
}

/// Row `i` as one run of *elements*, when the operand's strides already lay it
/// out that way.
///
/// [`MatView::row_block`] at one row, peeled to the element type. Two things
/// come off with the wrapper: a walk's signed add and bounds check per element,
/// and the derived `PartialEq` that asks for one on the bound rather than on the
/// value.
fn row_run<'v, E, Bd>(a: &MatView<'v, Alphabet<E, Bd>>, i: usize, k: usize) -> Option<&'v [E]>
where
    E: IntegerElement,
    Bd: Bound,
{
    a.row_block(i, 0, 1, k)
        .map(bytemuck::TransparentWrapper::peel_slice)
}

/// Write the `d` distinct rows out and renumber the index to name them.
///
/// On entry `index[i]` is the first row equal to row `i`; on return it is that
/// row's position among the distinct ones. The renumbering keeps
/// `index[i] <= i`, which is what lets the output be expanded in place by a
/// descending walk.
///
/// `false` when the offer does not hold them, and then nothing has been written
/// and nothing renumbered: the caller runs the packed traversal at the same
/// bytes.
fn compact<E, Bd>(
    a: &MatView<'_, Alphabet<E, Bd>>,
    index: &mut [usize],
    rows: &mut [Alphabet<E, Bd>],
    distinct: usize,
) -> bool
where
    E: IntegerElement,
    Bd: Bound,
{
    let (m, k) = (a.rows(), a.cols());
    let Some(want) = distinct.checked_mul(k) else {
        return false;
    };
    if want > rows.len() {
        return false;
    }
    let mut next = 0usize;
    for i in 0..m {
        if index[i] == i {
            // A meaning seen for the first time: write it out and give it its
            // number.
            for (dst, src) in rows[next * k..][..k].iter_mut().zip(a.row_walk(i, 0, k)) {
                *dst = *src;
            }
            index[i] = next;
            next += 1;
        } else {
            // Its representative came earlier, so it has already been renumbered.
            index[i] = index[index[i]];
        }
    }
    debug_assert_eq!(next, distinct, "the pass and the compaction agree");
    true
}

/// A row's content address: FNV-1a over the elements, in four independent lanes.
///
/// The whole row, not a sample of it. A hash over a prefix would be cheaper and
/// would still never call two unequal rows equal --- the comparison is the
/// verdict --- but it would give an operand whose rows share a prefix a
/// quadratic number of comparisons, and a cost that depends on the shape of the
/// data that way is exactly the kind of ceiling this library does not have.
///
/// Four lanes rather than one because one is a serial multiply chain: the mix
/// has a five-cycle latency and a one-cycle throughput, so four independent
/// chains cost the same instructions and retire four at a time. Measured on a
/// `4096 x 512` operand, that and reading the row as a slice took the pass from
/// 2.4 ns per element to a fifth of it.
///
/// Seedless and deterministic, because a traversal chosen by a randomly seeded
/// hash would run differently on two runs of the same program, and the whole of
/// this library's verification rests on the opposite. It decides only who is
/// compared; [`rows_equal`] decides who is equal.
fn row_hash<E, Bd>(a: &MatView<'_, Alphabet<E, Bd>>, i: usize, k: usize) -> usize
where
    E: IntegerElement + Hash,
    Bd: Bound,
{
    const SEED: u64 = 0xcbf2_9ce4_8422_2325;
    // Eight scalars rather than an array indexed by a running lane: an array with
    // a dynamic index lives in memory and is bounds-checked per element, which
    // measured cost more than the mix it was there to parallelize. Eight because
    // the mix is a five-cycle multiply and the multiplier retires one a cycle, so
    // eight chains is where the latency stops being what bounds it.
    let mut h = [
        SEED,
        SEED ^ 1,
        SEED ^ 2,
        SEED ^ 3,
        SEED ^ 4,
        SEED ^ 5,
        SEED ^ 6,
        SEED ^ 7,
    ];

    let mix = |lane: u64, x: E| {
        let mut f = Fnv(lane);
        x.hash(&mut f);
        f.0
    };

    match row_run(a, i, k) {
        Some(run) => {
            let mut octs = run.chunks_exact(8);
            // Destructured rather than indexed: `chunks_exact` guarantees the
            // length but indexing still emits the check, and at eight elements a
            // turn the checks are most of the loop.
            for q in &mut octs {
                if let [a, b, c, d, e, f, g, i] = *q {
                    h[0] = mix(h[0], a);
                    h[1] = mix(h[1], b);
                    h[2] = mix(h[2], c);
                    h[3] = mix(h[3], d);
                    h[4] = mix(h[4], e);
                    h[5] = mix(h[5], f);
                    h[6] = mix(h[6], g);
                    h[7] = mix(h[7], i);
                }
            }
            for (lane, x) in octs.remainder().iter().enumerate() {
                h[lane] = mix(h[lane], *x);
            }
        }
        None => {
            // The element rather than the wrapper: `Alphabet`'s derived `Hash`
            // asks for one on the *bound*, which is a marker with nothing to
            // hash.
            for (p, x) in a.row_walk(i, 0, k).enumerate() {
                let lane = p & 7;
                h[lane] = mix(h[lane], x.get());
            }
        }
    }

    // Fold, so that a row's address depends on every lane and on `k`. Rotated
    // before combining, so that two lanes cannot cancel, and finished with one
    // multiply-shift rather than by running the byte mix over all sixty-four
    // bytes of the lanes --- which, being serial, was a third of the whole pass
    // at `k = 512` for a twelfth of the elements.
    let mut folded = SEED ^ (k as u64);
    for (i, lane) in h.iter().enumerate() {
        folded ^= lane.rotate_left(i as u32 * 8);
    }
    folded = folded.wrapping_mul(0xff51_afd7_ed55_8ccd);
    folded ^= folded >> 33;
    folded = folded.wrapping_mul(0xc4ce_b9fe_1a85_ec53);
    (folded ^ (folded >> 29)) as usize
}

/// FNV-1a, written out rather than borrowed from `std`, whose default hasher is
/// randomly seeded.
struct Fnv(u64);

impl Hasher for Fnv {
    fn finish(&self) -> u64 {
        self.0
    }

    fn write(&mut self, bytes: &[u8]) {
        for &b in bytes {
            self.0 ^= b as u64;
            self.0 = self.0.wrapping_mul(0x0000_0100_0000_01b3);
        }
    }
}

#[cfg(test)]
// R7 governs the library, not its tests.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use crate::epilogue::Linear;
    use std::vec;
    use std::vec::Vec;
    use uor_matmul_core::{as_alphabet_full, Full, MatViewMut};

    /// `A` with `m` rows drawn from `meanings` distinct ones.
    fn operands(m: usize, k: usize, n: usize, meanings: usize) -> (Vec<i8>, Vec<i8>) {
        let a = (0..m * k)
            .map(|x| {
                let (row, col) = (x / k, x % k);
                (((row % meanings) * 31 + col * 17) % 251) as i8
            })
            .collect();
        let b = (0..k * n).map(|x| ((x * 53) % 241) as i8).collect();
        (a, b)
    }

    fn collapsed(m: usize, k: usize, n: usize, meanings: usize, offer: usize) -> Vec<i32> {
        let (a, b) = operands(m, k, n, meanings);
        let mut c = vec![0i32; m * n];
        let shape = Shape { m, k, n };
        let mut index = vec![0usize; suggested_collapse_index(m)];
        let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; offer];
        let mut buffer = vec![Alphabet::<i8, Full<i8>>::ZERO; crate::suggested_scratch(shape)];

        let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
        let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();

        gemm_collapsed(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::new(&mut buffer),
            &mut Collapse::new(&mut index, &mut rows),
        );
        c
    }

    fn packed(m: usize, k: usize, n: usize, meanings: usize) -> Vec<i32> {
        let (a, b) = operands(m, k, n, meanings);
        let mut c = vec![0i32; m * n];
        let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
        let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();
        gemm_packed(
            &mut t,
            &Linear::OVERWRITE,
            GemmOptions::default(),
            &mut Scratch::none(),
        );
        c
    }

    #[test]
    fn collapsing_equal_rows_cannot_change_a_byte_cd_12() {
        // Shapes that are not multiples of any panel, degeneracies from none to
        // total, and offers from nothing to the worst case.
        for &(m, k, n) in &[
            (1, 1, 1),
            (7, 5, 3),
            (64, 17, 33),
            (100, 64, 40),
            (37, 3, 129),
            (256, 8, 8),
        ] {
            for &meanings in &[1, 2, 3, m / 2 + 1, m] {
                let want = packed(m, k, n, meanings);
                for &offer in &[0, k, k * 2, m * k / 2, m * k] {
                    assert_eq!(
                        collapsed(m, k, n, meanings, offer),
                        want,
                        "{m}x{k}x{n}, {meanings} meanings, offer {offer}"
                    );
                }
            }
        }
    }

    #[test]
    fn the_pass_finds_exactly_the_distinct_rows() {
        let (m, k) = (128, 9);
        for meanings in [1usize, 5, 64, 128] {
            let (a, _) = operands(m, k, 1, meanings);
            let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
            let mut index = vec![0usize; suggested_collapse_index(m)];
            let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; m * k];
            let d = distinct_rows(&av, &mut index).unwrap();
            assert_eq!(d, meanings.min(m), "{meanings} meanings");
            assert!(compact(&av, &mut index, &mut rows, d));
            // Numbered by first occurrence, which is what makes the expansion
            // safe to walk backwards.
            for (i, &at) in index[..m].iter().enumerate() {
                assert!(at <= i, "row {i} resolves forwards");
            }
        }
    }

    /// Equal *columns* of `B`, collapsed by the same traversal on the
    /// transposed triple. No second pass, no second compaction, no second
    /// expansion --- a stride (R13, S7).
    #[test]
    fn collapsing_equal_columns_is_the_same_traversal_transposed_cd_12() {
        for &(m, k, n) in &[(7, 5, 3), (33, 17, 64), (4, 3, 100), (64, 8, 8)] {
            for &meanings in &[1usize, 2, n / 2 + 1, n] {
                // `B` with `meanings` distinct columns.
                let a: Vec<i8> = (0..m * k).map(|x| ((x * 41) % 251) as i8).collect();
                let b: Vec<i8> = (0..k * n)
                    .map(|x| {
                        let (row, col) = (x / n, x % n);
                        (((col % meanings) * 29 + row * 13) % 251) as i8
                    })
                    .collect();

                let want = {
                    let mut c = vec![0i32; m * n];
                    let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                    let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
                    let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                    let mut t = Triple::new(av, bv, cv).unwrap();
                    gemm_packed(
                        &mut t,
                        &Linear::OVERWRITE,
                        GemmOptions::default(),
                        &mut Scratch::none(),
                    );
                    c
                };

                let mut c = vec![0i32; m * n];
                let mut index = vec![0usize; suggested_collapse_index(n)];
                let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; n * k];
                let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
                let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
                let mut t = Triple::new(av, bv, cv).unwrap();
                gemm_collapsed(
                    &mut t.transposed(),
                    &Linear::OVERWRITE,
                    GemmOptions::default(),
                    &mut Scratch::none(),
                    &mut Collapse::new(&mut index, &mut rows),
                );
                assert_eq!(c, want, "{m}x{k}x{n}, {meanings} distinct columns");
            }
        }
    }

    #[test]
    fn an_epilogue_that_reads_c_shares_nothing() {
        // Two equal rows of `A` against a `C` that differs by row: the answers
        // differ, so the traversal must not share them.
        let a = [1i8, 1, 1, 1];
        let b = [1i8, 1];
        let mut c = [10i32, 20];
        let mut index = vec![0usize; suggested_collapse_index(2)];
        let mut rows = vec![Alphabet::<i8, Full<i8>>::ZERO; 4];

        let av = MatView::row_major(as_alphabet_full(&a), 2, 2).unwrap();
        let bv = MatView::row_major(as_alphabet_full(&b), 2, 1).unwrap();
        let cv = MatViewMut::row_major(&mut c, 2, 1).unwrap();
        let mut t = Triple::new(av, bv, cv).unwrap();

        gemm_collapsed(
            &mut t,
            &Linear::ACCUMULATE,
            GemmOptions::default(),
            &mut Scratch::none(),
            &mut Collapse::new(&mut index, &mut rows),
        );
        assert_eq!(c, [12, 22]);
    }
}
