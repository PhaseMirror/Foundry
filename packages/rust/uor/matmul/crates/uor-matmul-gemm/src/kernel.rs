//! The packed, kernel-driven traversal (§7, §8).
//!
//! Same identity, different instructions. This module packs `A` and `B` into
//! the panel format a [`KernelSpec`] reads, runs the microkernel over chunks
//! the lane can hold, and folds the chunks into the accumulator that cannot
//! overflow. Nothing about the value depends on any of it, which is what
//! `CD-01` asserts byte for byte.
//!
//! # Every instantiation, not one
//!
//! The dispatch is a trait, [`Kernelized`], implemented for every element type
//! that has instructions. An element type without one is not a hole: its
//! `Lane` is its own exact accumulator and the reference kernel runs, which is
//! the same identity at the same exactness. What would be a hole --- and was,
//! before this --- is an instantiation whose *fast* factorization exists in the
//! ISA and is not reached, because then a measurement of that instantiation is
//! a measurement of the wrong program.

use uor_matmul_core::{
    AccOf, Accumulator, Alphabet, Backend, Bound, Element, EncodeFrom, EncodeMode, IntegerElement,
    Triple,
};
use uor_matmul_kernels::{
    available_i16, available_i16_modular, available_i32_exact, available_i32_modular,
    available_i64_exact, available_i64_modular, available_i8, available_i8_narrow,
    available_reduce_i16, available_reduce_i16_modular, available_reduce_i32_exact,
    available_reduce_i32_modular, available_reduce_i64_exact, available_reduce_i64_modular,
    available_reduce_i8, choose_for_rows, Factorization, KernelSpec, LaneLayout, MAX_TILE_LANES,
};

use crate::driver::GemmOptions;
use crate::epilogue::Epilogue;
use crate::scratch::Scratch;

/// An element type with microkernels, and how to fold their lanes.
///
/// The two factorizations are chosen by *declaration*, never by inspecting the
/// data: the alphabet bound decides how deep an exact lane may go, and the
/// encode mode decides whether the modular lane is admissible at all.
pub trait Kernelized: IntegerElement {
    /// The lane the exact kernels accumulate in.
    type Exact: Copy + Default + 'static;
    /// The lane the modular kernels accumulate in, when one exists.
    type Modular: Copy + Default + 'static;

    /// The exact kernel for this backend, on an alphabet bounded by `bound`.
    ///
    /// Always present: the reference sequence is exact on every alphabet, so
    /// narrowing the choice can never empty it.
    fn exact_spec(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, Self::Exact>;

    /// The same sequence over a panel narrower than the tile, when the table
    /// offers one.
    ///
    /// Asked for only when the shape is narrower than the tile already chosen,
    /// so a product wider than its panel pays nothing for the question. `None`
    /// means the table has no narrower panel for this family, which is the
    /// ordinary case and not a degraded one.
    fn exact_narrow(
        _backend: Backend,
        _bound: u128,
        _rows: usize,
    ) -> Option<KernelSpec<Self, Self::Exact>> {
        None
    }

    /// [`Kernelized::exact_narrow`] read in the quotient the caller named.
    fn modular_narrow(
        _backend: Backend,
        _out_bits: u32,
        _bound: u128,
        _rows: usize,
    ) -> Option<KernelSpec<Self, Self::Modular>> {
        None
    }

    /// The exact *reduce* kernel: lanes on `k` rather than on the output.
    ///
    /// Also always present, and also exact. Which of the two runs is a question
    /// about the shape against the tile, and about nothing else --- see
    /// [`uor_matmul_kernels::available_reduce_i8`].
    fn exact_reduce(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, Self::Exact>;

    /// The modular reduce kernel, if the output width admits one.
    fn modular_reduce(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, Self::Modular>>;

    /// The modular kernel for this backend, if the output width admits it.
    ///
    /// `out_bits` is the width of the type the caller is encoding into. The
    /// modular lane is legitimate exactly when the caller asked to *wrap* into
    /// a type no wider than the lane: reduction modulo `2^w` is a ring
    /// homomorphism, so the lane's own wrap is the encode, and nothing is lost
    /// that the caller did not ask to lose (§3.4).
    fn modular_spec(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, Self::Modular>>;

    /// Fold an exact lane into the accumulator that cannot overflow.
    fn fold_exact(acc: &mut Self::Acc, lane: Self::Exact);

    /// Combine two modular lanes. The ring's own addition.
    fn add_modular(acc: Self::Modular, lane: Self::Modular) -> Self::Modular;

    /// The modular lane, as the value the encode step would have produced.
    fn modular_as_acc(lane: Self::Modular) -> Self::Acc;

    /// The inverse: an accumulator that came from a modular lane, back as one.
    ///
    /// Exact because both are the same ring. A partial sum kept across depth
    /// chunks passes through the accumulator, and this is what lets it come back
    /// out as the lane the next chunk adds to.
    fn acc_as_modular(acc: Self::Acc) -> Self::Modular;
}

impl Kernelized for i8 {
    type Exact = i32;
    type Modular = i32;

    fn exact_spec(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i32> {
        choose_for_rows(available_i8(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn exact_reduce(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i32> {
        choose_for_rows(available_reduce_i8(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn exact_narrow(backend: Backend, bound: u128, rows: usize) -> Option<KernelSpec<Self, i32>> {
        choose_for_rows(available_i8_narrow(), backend, bound, rows)
    }

    fn modular_narrow(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        // The same homomorphism the full-width tile cashes in.
        let spec = choose_for_rows(available_i8_narrow(), backend, bound, rows)?;
        Some(KernelSpec {
            factorization: Factorization::Modular,
            ..spec
        })
    }

    fn modular_reduce(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        // The same homomorphism the tile kernel cashes in: an `i8` reduce lane is
        // already 32 bits, and read as `Z/2^32` its wrap *is* the encode.
        let spec = choose_for_rows(available_reduce_i8(), backend, bound, rows)?;
        Some(KernelSpec {
            factorization: Factorization::Modular,
            ..spec
        })
    }

    fn modular_spec(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        // The `i8` kernels already accumulate in a 32-bit lane. Read as exact,
        // that lane fills at `k = 133144` and the driver chunks; read as
        // `Z/2^32` --- which is what the caller asked for --- its wrap *is* the
        // encode, so the same kernel carries any depth in one chunk. Same
        // instructions, same bytes, one fewer fold: that is the homomorphism
        // being cashed in rather than a second kernel being written.
        let spec = choose_for_rows(available_i8(), backend, bound, rows)?;
        Some(KernelSpec {
            factorization: Factorization::Modular,
            ..spec
        })
    }

    fn fold_exact(acc: &mut Self::Acc, lane: i32) {
        *acc += i128::from(lane);
    }

    fn add_modular(acc: i32, lane: i32) -> i32 {
        acc.wrapping_add(lane)
    }

    fn modular_as_acc(lane: i32) -> Self::Acc {
        i128::from(lane)
    }

    fn acc_as_modular(acc: Self::Acc) -> i32 {
        acc as i32
    }
}

impl Kernelized for i16 {
    type Exact = i64;
    type Modular = i32;

    fn exact_spec(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i64> {
        choose_for_rows(available_i16(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn exact_reduce(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i64> {
        choose_for_rows(available_reduce_i16(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn modular_reduce(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        choose_for_rows(available_reduce_i16_modular(), backend, bound, rows)
    }

    fn modular_spec(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        // Not a shortcut for the exact lane's benefit --- that lane already
        // reaches every addressable `k` for `i16`. It is twice the columns per
        // instruction, because in `Z/2^32` there is nothing to widen to.
        choose_for_rows(available_i16_modular(), backend, bound, rows)
    }

    fn fold_exact(acc: &mut Self::Acc, lane: i64) {
        *acc += i128::from(lane);
    }

    fn add_modular(acc: i32, lane: i32) -> i32 {
        acc.wrapping_add(lane)
    }

    fn modular_as_acc(lane: i32) -> Self::Acc {
        i128::from(lane)
    }

    fn acc_as_modular(acc: Self::Acc) -> i32 {
        acc as i32
    }
}

impl Kernelized for i32 {
    type Exact = i64;
    type Modular = i32;

    fn exact_spec(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i64> {
        choose_for_rows(available_i32_exact(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn exact_reduce(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i64> {
        choose_for_rows(available_reduce_i32_exact(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn modular_reduce(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        choose_for_rows(available_reduce_i32_modular(), backend, bound, rows)
    }

    fn modular_spec(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i32>> {
        if out_bits > 32 {
            return None;
        }
        choose_for_rows(available_i32_modular(), backend, bound, rows)
    }

    fn fold_exact(acc: &mut Self::Acc, lane: i64) {
        *acc += i128::from(lane);
    }

    fn add_modular(acc: i32, lane: i32) -> i32 {
        acc.wrapping_add(lane)
    }

    fn modular_as_acc(lane: i32) -> Self::Acc {
        i128::from(lane)
    }

    fn acc_as_modular(acc: Self::Acc) -> i32 {
        acc as i32
    }
}

impl Kernelized for i64 {
    type Exact = i128;
    type Modular = i64;

    fn exact_spec(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i128> {
        // An `i64 x i64` product needs 128 bits, so the lane is an `i128`. No
        // SIMD integer multiply reaches that width on any supported target, so
        // this is not a placeholder --- it is the whole of what the hardware
        // offers, and the packing still buys it the locality every other family
        // gets.
        choose_for_rows(available_i64_exact(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn exact_reduce(backend: Backend, bound: u128, rows: usize) -> KernelSpec<Self, i128> {
        choose_for_rows(available_reduce_i64_exact(), backend, bound, rows)
            .expect("the portable kernel is always present")
    }

    fn modular_reduce(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i64>> {
        if out_bits > 64 {
            return None;
        }
        choose_for_rows(available_reduce_i64_modular(), backend, bound, rows)
    }

    fn modular_spec(
        backend: Backend,
        out_bits: u32,
        bound: u128,
        rows: usize,
    ) -> Option<KernelSpec<Self, i64>> {
        if out_bits > 64 {
            return None;
        }
        choose_for_rows(available_i64_modular(), backend, bound, rows)
    }

    fn fold_exact(acc: &mut Self::Acc, lane: i128) {
        acc.add_i128_in_place(lane);
    }

    fn add_modular(acc: i64, lane: i64) -> i64 {
        acc.wrapping_add(lane)
    }

    fn modular_as_acc(lane: i64) -> Self::Acc {
        <Self::Acc as Accumulator>::ZERO.add_i128(i128::from(lane))
    }

    fn acc_as_modular(acc: Self::Acc) -> i64 {
        // The low limb *is* the value in `Z/2^64`.
        acc.limbs()[0] as i64
    }
}

/// The tile buffer, sized by the kernels rather than by a number chosen here.
///
/// Every kernel carries a `const` assertion that its own tile fits
/// [`MAX_TILE_LANES`], so a kernel too large for this buffer fails the *build*.
/// That is what keeps it a derivation rather than a ceiling: no input can reach
/// it, and no kernel can quietly exceed it (R8).
const MAX_TILE: usize = MAX_TILE_LANES;

/// `C := epilogue(A * B, C)` through a microkernel, for any element type that
/// has one.
///
/// Returns `()`, for the same reason [`crate::gemm`] does.
pub fn gemm_packed<E, Bd, O, Ep>(
    triple: &mut Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    epilogue: &Ep,
    options: GemmOptions,
    scratch: &mut Scratch<'_, E, Bd>,
) where
    E: Kernelized,
    Bd: Bound,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
{
    let shape = triple.shape();
    if shape.m == 0 || shape.n == 0 {
        return;
    }

    // The modular lane is admissible exactly when the caller asked to wrap into
    // a type no wider than it. That is a question about two declarations --- the
    // encode mode and the output type --- and about nothing else.
    let wrapping = matches!(options.encode, EncodeMode::Wrapping);
    let modular = wrapping
        .then(|| E::modular_spec(options.backend, O::BITS, Bd::VALUE, shape.m))
        .flatten();

    match modular {
        Some(tile) => {
            match pick(
                shape,
                triple,
                &tile,
                || E::modular_narrow(options.backend, O::BITS, Bd::VALUE, shape.m),
                || E::modular_reduce(options.backend, O::BITS, Bd::VALUE, shape.m),
                scratch.len(),
            ) {
                Some(spec) => {
                    // In the quotient the caller asked for, a running partial sum
                    // kept in the accumulator and a lane are the same value, so
                    // accumulating one into the other is the ring's own addition.
                    let accumulate = |acc: &mut AccOf<E>, lane: E::Modular| {
                        *acc = E::modular_as_acc(E::add_modular(E::acc_as_modular(*acc), lane));
                    };
                    run::<E, Bd, O, Ep, E::Modular>(
                        triple,
                        epilogue,
                        options,
                        scratch,
                        spec,
                        E::add_modular,
                        &accumulate,
                        usize::MAX,
                    )
                }
                None => crate::gemm(triple, epilogue, options, scratch),
            }
        }
        None => {
            let tile = E::exact_spec(options.backend, Bd::VALUE, shape.m);
            match pick(
                shape,
                triple,
                &tile,
                || E::exact_narrow(options.backend, Bd::VALUE, shape.m),
                || Some(E::exact_reduce(options.backend, Bd::VALUE, shape.m)),
                scratch.len(),
            ) {
                Some(spec) => {
                    let depth = spec.lane_depth(Bd::VALUE);
                    let accumulate = E::fold_exact;
                    run::<E, Bd, O, Ep, E::Exact>(
                        triple,
                        epilogue,
                        options,
                        scratch,
                        spec,
                        |_, lane| lane,
                        &accumulate,
                        depth,
                    )
                }
                None => crate::gemm(triple, epilogue, options, scratch),
            }
        }
    }
}

/// What a traversal costs at this shape, scaled by `products_per_step` so that
/// no division is needed to compare it.
///
/// Two things are counted, because two things are all that differ:
///
/// - **Element accesses.** The packed traversal reads each panel element from
///   the operand and writes it into the panel: two accesses per packed element,
///   and it packs the *padded* extents, because a shape narrower than a panel
///   still pays for the whole panel. When the operand already holds the panel
///   there is nothing to pack and the term is zero.
/// - **Instruction issues.** The packed traversal issues one instruction per
///   `products_per_step` padded products; the streaming traversal issues one per
///   product, and reads two operands for each.
///
/// So the packed traversal costs `2 * (rows + cols) * kpad + rows * cols * kpad
/// / pps`, and the streaming one `3 * m * k * n`. Neither is a prediction of
/// nanoseconds --- they are counts, and `CD-01` asserts that whichever traversal
/// runs gives the same bytes.
///
/// Saturating throughout: at an astronomical shape both sides overflow and the
/// comparison is decided by the smaller one, which is the right answer for a
/// shape whose padding is a rounding error.
fn packed_cost<E, L>(
    shape: uor_matmul_core::Shape,
    spec: &KernelSpec<E, L>,
    borrowed: bool,
    blocked: bool,
) -> (u64, u64) {
    let g = spec.k_group.max(1);
    let kpad = (shape.k.div_ceil(g) * g) as u64;
    let rows = (shape.m.div_ceil(spec.mr) * spec.mr) as u64;
    let cols = (shape.n.div_ceil(spec.nr) * spec.nr) as u64;
    let pps = spec.products_per_step.max(1) as u64;
    let issues = rows.saturating_mul(cols).saturating_mul(kpad);
    let accesses = if borrowed {
        0
    } else if blocked {
        // Each operand packed once per block, and at the suggested offer that is
        // once.
        (rows + cols)
            .saturating_mul(kpad)
            .saturating_mul(2)
            .saturating_mul(pps)
    } else {
        // An offer too small to hold a block does not buy the blocked traversal;
        // it buys the one that packs both panels afresh for every output tile.
        // Costing the blocked traversal anyway is how a narrower panel came to
        // look cheaper than the streaming reference at `4 x 4 x 4` while running
        // three and a half times slower than it --- the model was pricing a
        // traversal the offer could not run.
        let calls = (rows / spec.mr as u64).saturating_mul(cols / spec.nr as u64);
        calls
            .saturating_mul(spec.mr as u64 + spec.nr as u64)
            .saturating_mul(kpad)
            .saturating_mul(2)
            .saturating_mul(pps)
    };
    (issues.saturating_add(accesses), pps)
}

/// Choose the cheaper packed sequence, or `None` for the streaming traversal.
///
/// Every candidate computes the same integer --- `CB-01` .. `CB-07` for the
/// sequences, `CD-01` and `CD-04` for the traversals --- so this decides which
/// instructions run and nothing else. It reads the declared shape, the declared
/// strides, and the sequences' own declarations, and never the data (R13).
fn pick<E, Bd, O, L>(
    shape: uor_matmul_core::Shape,
    triple: &Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    tile: &KernelSpec<E, L>,
    narrow: impl FnOnce() -> Option<KernelSpec<E, L>>,
    reduce: impl FnOnce() -> Option<KernelSpec<E, L>>,
    offer: usize,
) -> Option<KernelSpec<E, L>>
where
    E: IntegerElement,
    Bd: Bound,
{
    // Which traversal the offer actually buys. `run` takes the blocked one only
    // when a block of both panels fits; below that it repacks per output tile,
    // and the two do not cost the same.
    let blocks = |spec: &KernelSpec<E, L>| -> bool {
        let g = spec.k_group.max(1);
        let kpad = shape.k.div_ceil(g) * g;
        kpad != 0 && offer / kpad >= spec.mr + spec.nr
    };
    // A panel the operands already hold costs nothing to make, which is most of
    // what a reduce sequence costs on a narrow shape.
    let borrows = |spec: &KernelSpec<E, L>| -> bool {
        let g = spec.k_group.max(1);
        let kpad = shape.k.div_ceil(g) * g;
        matches!(spec.lane_layout, LaneLayout::Contiguous)
            && kpad == shape.k
            && shape.m.is_multiple_of(spec.mr)
            && shape.n.is_multiple_of(spec.nr)
            && triple
                .a()
                .row_block(0, 0, shape.m.min(spec.mr), kpad)
                .is_some()
            && triple
                .b()
                .column_block(0, 0, shape.n.min(spec.nr), kpad)
                .is_some()
    };

    let mut best = *tile;
    let (mut cost, mut pps) = packed_cost(shape, tile, borrows(tile), blocks(tile));

    // Both remaining candidates exist for a shape narrower than the tile, so past
    // a tile's width there is nothing to weigh and nothing to ask. Asking anyway
    // would cost two table walks on every wide call --- measured, a hundred
    // nanoseconds on a shape whose whole cost is a hundred and twenty.
    if shape.n < tile.nr {
        // A narrower panel of the same sequence: the padding a tile does for
        // columns that are not there is arithmetic, and halving the panel halves
        // it. The reduce sequence puts the lanes on `k` instead. They are weighed
        // the same way and against the same reference, because all three compute
        // the same integer (`CB-06`).
        let mut weigh = |c: Option<KernelSpec<E, L>>| {
            if let Some(c) = c {
                let (cc, cp) = packed_cost(shape, &c, borrows(&c), blocks(&c));
                // `a/p < b/q` without dividing.
                if cc.saturating_mul(pps) < cost.saturating_mul(cp) {
                    best = c;
                    cost = cc;
                    pps = cp;
                }
            }
        };
        weigh(narrow());
        weigh(reduce());
    }

    // Two operand reads and one issue per product, and nothing packed.
    let stream = (shape.m as u64)
        .saturating_mul(shape.k as u64)
        .saturating_mul(shape.n as u64)
        .saturating_mul(3);
    if cost < stream.saturating_mul(pps) {
        Some(best)
    } else {
        None
    }
}

/// The one traversal, shared by both factorizations.
///
/// `combine_lane` folds two lanes of the same chunk --- the ring's addition for
/// a modular lane, and unreachable for an exact one, which never sees two
/// chunks in the same lane. `fold` moves a finished lane into the accumulator.
#[allow(clippy::too_many_arguments)]
fn run<E, Bd, O, Ep, L>(
    triple: &mut Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    epilogue: &Ep,
    options: GemmOptions,
    scratch: &mut Scratch<'_, E, Bd>,
    spec: KernelSpec<E, L>,
    combine_lane: impl Fn(L, L) -> L,
    fold: &impl Fn(&mut AccOf<E>, L),
    lane_depth: usize,
) where
    E: Kernelized,
    Bd: Bound,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
    L: Copy + Default + 'static,
{
    let shape = triple.shape();
    let (mr, nr) = (spec.mr, spec.nr);
    let per_step = mr + nr;
    debug_assert!(
        mr * nr <= MAX_TILE,
        "the tile buffer covers every shipped kernel"
    );

    // The kernel reads its `k` in groups of `k_group`, so a panel is packed in
    // groups and a depth that is not a multiple of one is padded to it. The
    // padding is the alphabet's zero, which contributes nothing to the sum and
    // nothing to the lane --- so it is exact, it cannot push a lane past its
    // cap, and there is no `k`-tail in any kernel to get wrong (S8).
    let pad_to = spec.k_group.max(1);

    // With less than one packed group of room there is no panel to pack, so the
    // streaming traversal runs instead --- the same identity, walked
    // differently (S13).
    if scratch.len() < per_step * pad_to {
        crate::gemm(triple, epilogue, options, scratch);
        return;
    }

    // A whole number of groups, so a chunk's padded depth never outgrows what
    // was reserved for it.
    let kc = (scratch.len() / per_step).min(lane_depth) / pad_to * pad_to;
    let reads_c = epilogue.reads_c();

    // The panels are the only copies this driver makes, and which loop they sit
    // in decides how many times each byte is copied. A microkernel panel is
    // `mr` rows or `nr` columns wide, and packing at that granularity means one
    // of the two operands is repacked once per panel of the other: `m*n*k/nr`
    // element copies against `m*n*k` of arithmetic. At the shipped `nr` that is
    // not a rounding error --- it is the same order of magnitude as the
    // arithmetic, and it was the whole difference between this driver and the
    // instruction ceiling of its own kernels.
    //
    // So the panels are packed in *blocks*: `mc` rows of `A` and `nc` columns
    // of `B`, each covering many microkernel panels. `A` is then repacked once
    // per column block rather than once per column panel, which divides the copy
    // count by `nc/nr`. The block extents come from the caller's offer and the
    // cache-shaped constants, and neither can change an output byte --- `CD-01`
    // asserts exactly that.
    //
    // Blocking needs the whole depth in one panel, because a chunked
    // accumulation revisits each output block per chunk. When the offer is too
    // small the chunked traversal below runs instead, and `CD-01` and `CD-10`
    // assert the bytes are the same either way.
    let mut tile = [L::default(); MAX_TILE];
    let (a, b, c) = triple.parts();
    // The depth-chunked traversal, when the caller offered somewhere to keep the
    // exact partial sums.
    //
    // A classical GEMM chunks the reduction so its panels fit cache and adds the
    // chunks into `C`. This library cannot: `C` is the *encoded* output and a
    // partial sum encoded is a partial sum rounded. So without an accumulator
    // block the panels must hold the whole of `k`, and at `k = 400000` a panel is
    // megabytes and nothing is resident --- measured, that shape ran at a sixth
    // of the microkernel's own rate.
    //
    // With one, the reduction is chunked to `KC` and every partial sum stays
    // exact and full width. That is the property the exact accumulator buys and a
    // classical library cannot have: the sum is order-independent, so it may be
    // split any way the machine prefers and recombined with no consequence ---
    // which is exactly what `CD-01` and `CD-04` assert, at every chunk depth.
    let kpad = shape.k.div_ceil(pad_to) * pad_to;
    // A [`LaneLayout::Contiguous`] kernel reads one lane's whole depth as a run,
    // which is the same layout function at `group = kpad`: `packed_slot` then
    // reduces to `lane * kpad + p`. So there is one packer, and the difference
    // between a kernel whose lanes are columns and one whose lanes are steps of
    // the reduction is a single `usize`.
    let group = match spec.lane_layout {
        LaneLayout::Interleaved => pad_to,
        LaneLayout::Contiguous => kpad,
    };
    // A packed panel is a copy, and a copy of something already in the panel's
    // shape is pure cost. For a [`LaneLayout::Contiguous`] kernel the panel *is*
    // a run of rows or a run of columns, so a row-major `A` and a column-major
    // `B` already hold it --- and that is not an exotic case, it is a
    // matrix-vector product with the ordinary layout, where the panel would
    // otherwise be one element written per multiply-accumulate and double the
    // whole product's memory traffic.
    //
    // When *both* are borrowable the traversal needs no working memory at all,
    // so it does not have to ask whether the offer covers a panel: a single deep
    // dot product runs blocked on an empty `Scratch`. Nothing else changes ---
    // the kernel reads the same bytes at the same offsets, which is why `CD-01`
    // still holds and the borrowed and copied traversals are asserted equal on
    // every narrow shape.
    let borrowable = matches!(spec.lane_layout, LaneLayout::Contiguous) && kpad == shape.k;
    let borrow_all = borrowable
        && a.row_block(0, 0, shape.m.min(mr), kpad).is_some()
        && b.column_block(0, 0, shape.n.min(nr), kpad).is_some()
        && shape.m.is_multiple_of(mr)
        && shape.n.is_multiple_of(nr);

    let budget = if borrow_all {
        shape.m.max(mr) + shape.n.max(nr)
    } else {
        scratch.len().checked_div(kpad).unwrap_or(0)
    };

    let full_depth = shape.k <= lane_depth && (borrow_all || (shape.k <= kc && budget >= per_step));

    // When the full-depth traversal cannot run --- the offer does not cover a
    // panel that deep, or the lane does not reach that far --- the depth is
    // chunked instead, provided the caller offered somewhere to keep the exact
    // partial sums. That is the case a classical library handles by adding
    // partial sums into `C`, which it can do because its accumulator is its
    // output width; this library cannot, because `C` is the encoded output and a
    // partial sum encoded is a partial sum rounded. An accumulator block is the
    // somewhere, and with one the offer stops growing with `k` (`CD-10`).
    if !full_depth
        && scratch.accumulators() >= mr * nr
        && scratch.len() >= per_step * pad_to
        && shape.k > pad_to
    {
        run_chunked_depth(
            triple, epilogue, options, scratch, spec, fold, lane_depth, pad_to,
        );
        return;
    }

    if full_depth {
        use uor_matmul_core::generated::blocking;

        // The declared blocking is a working *set*, not a column count: `KC * NC`
        // elements of `B` are what has to stay resident while the row blocks
        // stream past, and `MC * KC` of `A`. Read that way it still says the right
        // thing when the panel's depth is the whole of `k` --- the block narrows
        // as the depth grows, so what stays resident stays the same size. Read as
        // a column count it would put a `k`-times-oversized panel in the cache
        // for a deep problem, and at `k = 1024` that is the difference between a
        // panel in L2 and a panel in memory.
        //
        // `mc` and `nc` are whole numbers of microkernel panels, so a block holds
        // no partial panel and the tile loops below need no second case. Each is
        // capped by the working set, by the matrix itself, and by what the offer
        // pays for --- in that order, with `A` yielding to `B` when the offer is
        // tight, because it is `A` that gets repacked.
        // A shape inside one block has one block, and asking how to divide it
        // costs a dozen integer divisions that the answer does not depend on ---
        // which, at a shape this small, is a measurable share of the whole call.
        let (mc, nc) = if shape.m <= mr && shape.n <= nr {
            (mr, nr)
        } else {
            // The working set constrains a block only while it *can* be
            // satisfied. Once one microkernel panel at this depth already
            // exceeds the set, shrinking the block gains nothing --- the panel
            // is out of that cache either way --- and it costs the other operand
            // a repack per block. At `k = 262144` the old form drove `nc` to a
            // single column and made `A` be read once per column of `B`.
            let fits = |lanes: usize, set: usize| -> usize {
                if lanes.saturating_mul(kpad) >= set {
                    usize::MAX
                } else {
                    (set / kpad).max(lanes)
                }
            };
            let mc_want = shape
                .m
                .min(blocking::MC)
                .min(fits(mr, blocking::MC * blocking::KC))
                .div_ceil(mr)
                * mr;
            let nc_want = shape
                .n
                .min(blocking::NC)
                .min(fits(nr, blocking::KC * blocking::NC))
                .div_ceil(nr)
                * nr;
            let mc = mc_want.min((budget - nr) / mr * mr).max(mr);
            let nc = ((budget - mc) / nr * nr).min(nc_want).max(nr);

            // Spread the extents evenly over the number of blocks they already
            // imply. The count is what decides how often `A` is repacked, and it
            // does not change here --- what changes is that the last block is a
            // full one instead of a sliver, so every panel is the same size and
            // the tail costs a repack of the same block rather than of a
            // sixteen-column stub.
            (
                shape.m.div_ceil(shape.m.div_ceil(mc)).div_ceil(mr) * mr,
                shape.n.div_ceil(shape.n.div_ceil(nc)).div_ceil(nr) * nr,
            )
        };

        // Nothing to reserve when nothing is copied.
        let (pa_buf, pb_buf) = if borrow_all {
            (&mut [][..], &mut [][..])
        } else {
            scratch.take(kpad * (mc + nc)).split_at_mut(mc * kpad)
        };

        let mut j0 = 0;
        while j0 < shape.n {
            let cols = nc.min(shape.n - j0);
            let borrowed_b = borrowable
                .then(|| b.column_block(0, j0, cols, kpad))
                .flatten()
                .filter(|_| cols.is_multiple_of(nr));
            if borrowed_b.is_none() {
                pack_columns(pb_buf, nr, group, shape.k, kpad, b, 0, j0, cols, shape.n);
            }

            let mut i0 = 0;
            while i0 < shape.m {
                let rows = mc.min(shape.m - i0);
                // A partial panel would read past the block's last row, so a block
                // that does not divide into whole panels is packed as before.
                let borrowed_a = borrowable
                    .then(|| a.row_block(i0, 0, rows, kpad))
                    .flatten()
                    .filter(|_| rows.is_multiple_of(mr));
                if borrowed_a.is_none() {
                    pack_rows(pa_buf, mr, group, shape.k, kpad, a, i0, 0, rows, shape.m);
                }

                let pa: &[E] = match borrowed_a {
                    Some(block) => bytemuck::TransparentWrapper::peel_slice(block),
                    None => bytemuck::TransparentWrapper::peel_slice(&*pa_buf),
                };
                let pb: &[E] = match borrowed_b {
                    Some(block) => bytemuck::TransparentWrapper::peel_slice(block),
                    None => bytemuck::TransparentWrapper::peel_slice(&*pb_buf),
                };

                // The row panel is the inner loop's invariant, so it stays in the
                // nearest cache while the column panels stream past it. It is the
                // smaller of the two --- `mr * kpad` against `nr * kpad` --- and
                // at a panel whose depth is the whole of `k` that is the
                // difference between holding it in L1 and not.
                let mut ii = 0;
                while ii < rows {
                    let ap = &pa[(ii / mr) * mr * kpad..][..mr * kpad];
                    let mut jj = 0;
                    while jj < cols {
                        let bp = &pb[(jj / nr) * nr * kpad..][..nr * kpad];
                        spec.mac_tile(kpad, ap, bp, &mut tile[..mr * nr]);

                        for i in 0..mr.min(rows - ii) {
                            for j in 0..nr.min(cols - jj) {
                                let mut acc = <AccOf<E> as Accumulator>::ZERO;
                                fold(&mut acc, tile[i * nr + j]);
                                let (ci, cj) = (i0 + ii + i, j0 + jj + j);
                                let prior = if reads_c { Some(*c.at(ci, cj)) } else { None };
                                *c.at_mut(ci, cj) = epilogue.finish(acc, prior, options.encode);
                            }
                        }
                        jj += nr;
                    }
                    ii += mr;
                }
                i0 += mc;
            }
            j0 += nc;
        }
        return;
    }

    let mut i0 = 0;
    while i0 < shape.m {
        let mut j0 = 0;
        while j0 < shape.n {
            let mut wide = [<AccOf<E> as Accumulator>::ZERO; MAX_TILE];
            let mut carried = [L::default(); MAX_TILE];

            let mut p0 = 0;
            while p0 < shape.k {
                let depth = kc.min(shape.k - p0);
                let pad = depth.div_ceil(pad_to) * pad_to;
                let group = match spec.lane_layout {
                    LaneLayout::Interleaved => pad_to,
                    LaneLayout::Contiguous => pad,
                };
                {
                    let buf = scratch.take(per_step * pad);
                    let (pa_buf, pb_buf) = buf.split_at_mut(mr * pad);
                    pack_rows(pa_buf, mr, group, depth, pad, a, i0, p0, mr, shape.m);
                    pack_columns(pb_buf, nr, group, depth, pad, b, p0, j0, nr, shape.n);
                }

                let buf = scratch.take(per_step * pad);
                let raw: &[E] = bytemuck::TransparentWrapper::peel_slice(&*buf);
                let (pa, pb) = raw.split_at(mr * pad);
                spec.mac_tile(pad, pa, pb, &mut tile[..mr * nr]);

                if matches!(spec.factorization, Factorization::Modular) {
                    // The ring's own addition: chunks combine in the quotient.
                    for (acc, lane) in carried[..mr * nr].iter_mut().zip(&tile[..mr * nr]) {
                        *acc = combine_lane(*acc, *lane);
                    }
                } else {
                    // Each chunk's lane is exact; the accumulator absorbs them.
                    for (w, lane) in wide[..mr * nr].iter_mut().zip(&tile[..mr * nr]) {
                        fold(w, *lane);
                    }
                }
                p0 += depth;
            }

            if matches!(spec.factorization, Factorization::Modular) {
                for (w, lane) in wide[..mr * nr].iter_mut().zip(&carried[..mr * nr]) {
                    fold(w, *lane);
                }
            }

            for i in 0..mr.min(shape.m - i0) {
                for j in 0..nr.min(shape.n - j0) {
                    let prior = if reads_c {
                        Some(*c.at(i0 + i, j0 + j))
                    } else {
                        None
                    };
                    *c.at_mut(i0 + i, j0 + j) =
                        epilogue.finish(wide[i * nr + j], prior, options.encode);
                }
            }
            j0 += nr;
        }
        i0 += mr;
    }
}

/// A lane's cursor through a packed panel.
///
/// The slot of element `p` in lane `l` is
/// [`uor_matmul_kernels::packed_slot`], but computing it per element costs a
/// division and a remainder by a value that is not a compile-time constant here
/// --- which, measured, cost more than the packing itself. Walking it costs an
/// increment and one predictable branch, and lands on the same slots: `CD-01`
/// asserts the bytes, and `the_cursor_agrees_with_the_declared_layout` asserts
/// the slots directly.
struct Cursor {
    at: usize,
    within: usize,
    group: usize,
    /// The step from the last element of one group to the first of the next.
    carry: usize,
}

impl Cursor {
    #[inline(always)]
    fn new(lane: usize, lanes: usize, group: usize) -> Self {
        Self {
            at: lane * group,
            within: 0,
            group,
            carry: lanes * group - (group - 1),
        }
    }

    #[inline(always)]
    fn advance(&mut self) {
        self.within += 1;
        if self.within == self.group {
            self.within = 0;
            self.at += self.carry;
        } else {
            self.at += 1;
        }
    }
}

/// `C := epilogue(A * B, C)` with the reduction chunked to what the cache holds.
///
/// The loop order is the classical one --- column block, depth chunk, row block,
/// then the microkernel tiles --- and the difference is where the partial sums
/// live. A classical library puts them in `C`, at the output's width, and pays
/// for it with an answer that depends on the chunking. This one puts them in the
/// caller's accumulator block, at a width that cannot overflow, and the chunking
/// is invisible in the result.
///
/// Every panel is `kc` deep rather than `k` deep, so the offer does not grow with
/// the depth and an astronomical `k` is blocked exactly as a modest one is.
#[allow(clippy::too_many_arguments)]
fn run_chunked_depth<E, Bd, O, Ep, L>(
    triple: &mut Triple<'_, '_, '_, Alphabet<E, Bd>, O>,
    epilogue: &Ep,
    options: GemmOptions,
    scratch: &mut Scratch<'_, E, Bd>,
    spec: KernelSpec<E, L>,
    accumulate: &impl Fn(&mut AccOf<E>, L),
    lane_depth: usize,
    pad_to: usize,
) where
    E: Kernelized,
    Bd: Bound,
    O: Element + EncodeFrom<AccOf<E>>,
    Ep: Epilogue<E, O>,
    L: Copy + Default + 'static,
{
    use uor_matmul_core::generated::blocking;

    let shape = triple.shape();
    let (mr, nr) = (spec.mr, spec.nr);
    let per_step = mr + nr;
    let reads_c = epilogue.reads_c();

    // The chunk depth: as deep as the declared blocking, the lane admits, and the
    // panel offer pays for --- and a whole number of `k`-groups, so a chunk's
    // padded depth never outgrows what was reserved for it.
    let kc = blocking::KC
        .min(lane_depth)
        .min(scratch.len() / per_step)
        .max(1)
        / pad_to
        * pad_to;
    if kc == 0 {
        // Not even one group of panel room. The full-depth traversals handle it.
        // Not even one group of panel room; the streaming traversal runs.
        crate::gemm(triple, epilogue, options, scratch);
        return;
    }

    // The output block, in whole microkernel tiles, fitted to *both* offers: the
    // accumulators must cover its tiles and the panel room must cover one chunk
    // of it.
    let tiles = scratch.accumulators() / (mr * nr);
    let room = scratch.len() / kc;
    let mut mc = shape.m.min(blocking::MC).div_ceil(mr) * mr;
    let mut nc = shape.n.min(blocking::NC).div_ceil(nr) * nr;
    while (mc / mr) * (nc / nr) > tiles || mc + nc > room {
        if nc / nr > 1 && nc >= mc {
            nc -= nr;
        } else if mc / mr > 1 {
            mc -= mr;
        } else {
            break;
        }
    }
    if mc + nc > room || (mc / mr) * (nc / nr) > tiles {
        // One tile of accumulators and one panel step is the least this needs,
        // and the guard at the call site established both; if the arithmetic
        // above still cannot fit, the streaming traversal runs.
        crate::gemm(triple, epilogue, options, scratch);
        return;
    }
    // Spread the extents evenly over the blocks they imply, so no block is a
    // sliver.
    let mc = shape.m.div_ceil(shape.m.div_ceil(mc)).div_ceil(mr) * mr;
    let nc = shape.n.div_ceil(shape.n.div_ceil(nc)).div_ceil(nr) * nr;

    let mut tile = [L::default(); MAX_TILE];
    let mut j0 = 0;
    while j0 < shape.n {
        let cols = nc.min(shape.n - j0);
        let mut i0 = 0;
        while i0 < shape.m {
            let rows = mc.min(shape.m - i0);
            let block_tiles = rows.div_ceil(mr) * cols.div_ceil(nr);
            // Zeroed here, so a block starts from nothing however the previous one
            // ended.
            let mut p0 = 0;
            while p0 < shape.k {
                let depth = kc.min(shape.k - p0);
                let pad = depth.div_ceil(pad_to) * pad_to;
                let group = match spec.lane_layout {
                    LaneLayout::Interleaved => pad_to,
                    LaneLayout::Contiguous => pad,
                };
                {
                    let (a, b, _) = triple.parts();
                    let buf = scratch.take(pad * (mc + nc));
                    let (pa_buf, pb_buf) = buf.split_at_mut(mc * pad);
                    pack_rows(pa_buf, mr, group, depth, pad, a, i0, p0, rows, shape.m);
                    pack_columns(pb_buf, nr, group, depth, pad, b, p0, j0, cols, shape.n);
                }
                if p0 == 0 {
                    // A block starts from nothing, however the previous one ended.
                    scratch.take_accumulators(block_tiles * mr * nr);
                }

                let (buf, accs) = scratch.split(pad * (mc + nc), block_tiles * mr * nr);
                let raw: &[E] = bytemuck::TransparentWrapper::peel_slice(&*buf);
                let (pa, pb) = raw.split_at(mc * pad);

                let mut ii = 0;
                while ii < rows {
                    let ap = &pa[(ii / mr) * mr * pad..][..mr * pad];
                    let mut jj = 0;
                    while jj < cols {
                        let bp = &pb[(jj / nr) * nr * pad..][..nr * pad];
                        spec.mac_tile(pad, ap, bp, &mut tile[..mr * nr]);
                        let at = ((ii / mr) * cols.div_ceil(nr) + jj / nr) * mr * nr;
                        let slot = &mut accs[at..at + mr * nr];
                        for (acc, lane) in slot.iter_mut().zip(&tile[..mr * nr]) {
                            accumulate(acc, *lane);
                        }
                        jj += nr;
                    }
                    ii += mr;
                }
                p0 += depth;
            }

            // One encode per output element, after the whole reduction --- which
            // is the point: the chunking is invisible because nothing was encoded
            // until every chunk had been added.
            let per_row = cols.div_ceil(nr);
            let accs = scratch.keep_accumulators(block_tiles * mr * nr);
            let (_, _, c) = triple.parts();
            for ii in (0..rows).step_by(mr) {
                for jj in (0..cols).step_by(nr) {
                    let at = ((ii / mr) * per_row + jj / nr) * mr * nr;
                    for i in 0..mr.min(rows - ii) {
                        for j in 0..nr.min(cols - jj) {
                            let acc = accs[at + i * nr + j];
                            let (ci, cj) = (i0 + ii + i, j0 + jj + j);
                            let prior = if reads_c { Some(*c.at(ci, cj)) } else { None };
                            *c.at_mut(ci, cj) = epilogue.finish(acc, prior, options.encode);
                        }
                    }
                }
            }
            i0 += mc;
        }
        j0 += nc;
    }
}

/// How many lines of a transpose tile to hold open at once.
///
/// A panel whose lanes are steps of the reduction is a *transpose* of the
/// operand, and a transpose done one column at a time reads the whole operand
/// once per column: at `8 x 262144 x 8` that was eight passes over two megabytes,
/// and it cost thirteen times what the microkernel cost. Done in square tiles of
/// a cache line each way, the operand is read once.
///
/// Derived from the declared line width and the element size, so it is a
/// property of the machine and the type rather than a number chosen here.
fn transpose_tile<T>() -> usize {
    (uor_matmul_core::generated::blocking::CACHE_LINE_BYTES / core::mem::size_of::<T>()).max(1)
}

/// Pack `count` single-lane panels by transposing in tiles.
///
/// `line(p, c0, len)` walks `len` elements of the operand at depth `p` starting
/// at lane `c0`; for a one-lane panel that run is contiguous exactly when the
/// lanes are the operand's cheap direction, which is when this is worth doing.
/// Panel `c` receives element `p` at `c * kpad + p`, which is
/// [`uor_matmul_kernels::packed_slot`] at `lanes = 1`.
fn transpose_panels<'v, E: IntegerElement, Bd: Bound>(
    out: &mut [Alphabet<E, Bd>],
    kpad: usize,
    depth: usize,
    count: usize,
    line: impl Fn(usize, usize, usize) -> uor_matmul_core::Walk<'v, Alphabet<E, Bd>>,
) {
    let tile = transpose_tile::<Alphabet<E, Bd>>();
    let mut p0 = 0;
    while p0 < depth {
        let pn = tile.min(depth - p0);
        let mut c0 = 0;
        while c0 < count {
            let cn = tile.min(count - c0);
            for p in p0..p0 + pn {
                for (c, v) in line(p, c0, cn).enumerate() {
                    out[(c0 + c) * kpad + p] = *v;
                }
            }
            c0 += tile;
        }
        p0 += pn;
    }
}

/// Pack `count` rows of `A` into `ceil(count / lanes)` microkernel panels.
///
/// Walks each row once rather than indexing per element. Rows past the block,
/// and depth past `depth` up to the padded `kpad`, take the alphabet's zero:
/// zero padding contributes nothing to the sum, so an arbitrary shape and an
/// arbitrary `k` take this path and not a different one (S8).
#[allow(clippy::too_many_arguments)]
fn pack_rows<E: IntegerElement, Bd: Bound>(
    out: &mut [Alphabet<E, Bd>],
    lanes: usize,
    group: usize,
    depth: usize,
    kpad: usize,
    a: &uor_matmul_core::MatView<'_, Alphabet<E, Bd>>,
    row0: usize,
    col0: usize,
    count: usize,
    rows: usize,
) {
    let count = count.min(rows.saturating_sub(row0));
    // Which loop is inner decides which stride the *reads* walk, and the panel
    // is written either way. A lane is a row here, so the lanes move by `rs` and
    // the depth by `cs`: putting the lanes inside walks `rs`, putting the depth
    // inside walks `cs`, and the right answer is whichever is smaller. Reading
    // the wrong way round touches a new cache line per element, which for a
    // shape whose packing is the same order as its arithmetic is the whole cost.
    // Only worth it when there is more than one lane to put inside: a reduce
    // panel has one, and an inner loop of one element is all overhead.
    let cols_are_cheap = a.strides().rs.unsigned_abs() < a.strides().cs.unsigned_abs();
    if lanes == 1 && cols_are_cheap && count > 1 {
        // The symmetric case: a column-major `A`, whose rows are the expensive
        // direction, transposed into one-row panels.
        transpose_panels(out, kpad, depth, count, |p, c0, cn| {
            a.column_walk(row0 + c0, col0 + p, cn)
        });
        for c in 0..count {
            for p in depth..kpad {
                out[c * kpad + p] = Alphabet::ZERO;
            }
        }
        return;
    }
    let lanes_inner = lanes > 1 && cols_are_cheap;
    let mut base = 0;
    let mut done = 0;
    while done < count {
        let full = lanes.min(count - done);
        let panel = &mut out[base..base + lanes * kpad];
        if lanes_inner {
            let mut cursor = Cursor::new(0, lanes, group);
            for p in 0..depth {
                for (lane, v) in a.column_walk(row0 + done, col0 + p, full).enumerate() {
                    panel[cursor.at + lane * group] = *v;
                }
                cursor.advance();
            }
        } else {
            for lane in 0..full {
                let mut cursor = Cursor::new(lane, lanes, group);
                for v in a.row_walk(row0 + done + lane, col0, depth) {
                    panel[cursor.at] = *v;
                    cursor.advance();
                }
            }
        }
        pad_panel(panel, lanes, group, depth, kpad, full);
        base += lanes * kpad;
        done += lanes;
    }
}

/// Pack `count` columns of `B` into `ceil(count / lanes)` panels. See
/// [`pack_rows`].
#[allow(clippy::too_many_arguments)]
fn pack_columns<E: IntegerElement, Bd: Bound>(
    out: &mut [Alphabet<E, Bd>],
    lanes: usize,
    group: usize,
    depth: usize,
    kpad: usize,
    b: &uor_matmul_core::MatView<'_, Alphabet<E, Bd>>,
    row0: usize,
    col0: usize,
    count: usize,
    cols: usize,
) {
    let count = count.min(cols.saturating_sub(col0));
    // A lane is a column here, so the lanes move by `cs` and the depth by `rs`.
    // See [`pack_rows`]: a row-major `B` wants the lanes inside, and walking it
    // the other way round is a cache line per element.
    let rows_are_cheap = b.strides().cs.unsigned_abs() < b.strides().rs.unsigned_abs();
    if lanes == 1 && rows_are_cheap && count > 1 {
        transpose_panels(out, kpad, depth, count, |p, c0, cn| {
            b.row_walk(row0 + p, col0 + c0, cn)
        });
        for c in 0..count {
            for p in depth..kpad {
                out[c * kpad + p] = Alphabet::ZERO;
            }
        }
        return;
    }
    let lanes_inner = lanes > 1 && rows_are_cheap;
    let mut base = 0;
    let mut done = 0;
    while done < count {
        let full = lanes.min(count - done);
        let panel = &mut out[base..base + lanes * kpad];
        if lanes_inner {
            let mut cursor = Cursor::new(0, lanes, group);
            for p in 0..depth {
                for (lane, v) in b.row_walk(row0 + p, col0 + done, full).enumerate() {
                    panel[cursor.at + lane * group] = *v;
                }
                cursor.advance();
            }
        } else {
            for lane in 0..full {
                let mut cursor = Cursor::new(lane, lanes, group);
                for v in b.column_walk(row0, col0 + done + lane, depth) {
                    panel[cursor.at] = *v;
                    cursor.advance();
                }
            }
        }
        pad_panel(panel, lanes, group, depth, kpad, full);
        base += lanes * kpad;
        done += lanes;
    }
}

/// Zero everything a walk did not write: the lanes past the block's edge, and
/// the depth past `depth` in every lane.
fn pad_panel<E: IntegerElement, Bd: Bound>(
    panel: &mut [Alphabet<E, Bd>],
    lanes: usize,
    group: usize,
    depth: usize,
    kpad: usize,
    full: usize,
) {
    if full == lanes && depth == kpad {
        // Nothing was left unwritten. Saying so costs one comparison and skips
        // a walk over the whole panel, which is the ordinary case.
        return;
    }
    for lane in 0..lanes {
        let from = if lane < full { depth } else { 0 };
        let mut cursor = Cursor::new(lane, lanes, group);
        for _ in 0..from {
            cursor.advance();
        }
        for _ in from..kpad {
            panel[cursor.at] = Alphabet::ZERO;
            cursor.advance();
        }
    }
}

#[cfg(test)]
// R7 governs the library, not its tests: these build operands on the heap so
// that awkward shapes can be generated. `CA-01` witnesses the library's own
// zero-allocation claim with a counting allocator.
#[allow(clippy::disallowed_types)]
mod tests {
    use super::*;
    use crate::epilogue::Linear;
    use std::vec;
    use std::vec::Vec;
    use uor_matmul_core::{as_alphabet_full, Full, MatView, MatViewMut};

    /// `CD-01`, `CD-10`: chunking the depth cannot change a byte.
    ///
    /// The depth-chunked traversal keeps exact partial sums in the caller's
    /// accumulator block and adds the chunks in whatever order the blocking
    /// implies. That is legitimate precisely because the sum is exact and
    /// therefore order-independent --- so this asserts it, against the full-depth
    /// traversal and against the streaming reference, over depths that straddle
    /// the chunk boundary and shapes that straddle every block.
    #[test]
    fn chunking_the_depth_cannot_change_a_byte_cd_10() {
        use uor_matmul_core::generated::blocking;
        let kc = blocking::KC;
        for (m, n) in [(1usize, 1usize), (3, 5), (8, 8), (13, 17), (7, 40)] {
            for k in [1usize, 2, kc - 1, kc, kc + 1, 2 * kc + 3, 5 * kc] {
                let a: Vec<i8> = (0..m * k).map(|i| ((i * 37) % 251) as i8).collect();
                let b: Vec<i8> = (0..k * n).map(|i| ((i * 53) % 241) as i8).collect();

                let mut want = vec![0i32; m * n];
                let mut chunked = vec![0i32; m * n];
                let mut full = vec![0i32; m * n];
                let mut panels = vec![Alphabet::<i8, Full<i8>>::ZERO; 64 * (k + 1) + 4096];
                let mut accs =
                    vec![
                        <AccOf<i8> as Accumulator>::ZERO;
                        crate::suggested_accumulators(uor_matmul_core::Shape { m, k, n })
                            .max(m * n + 128)
                    ];

                for mode in [EncodeMode::Wrapping, EncodeMode::Nearest] {
                    for (out, which) in [(&mut want, 0u8), (&mut full, 1), (&mut chunked, 2)] {
                        let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                        let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
                        let cv = MatViewMut::row_major(out.as_mut_slice(), m, n).unwrap();
                        let mut t = Triple::new(av, bv, cv).unwrap();
                        let options = GemmOptions {
                            encode: mode,
                            ..Default::default()
                        };
                        match which {
                            0 => crate::gemm(
                                &mut t,
                                &Linear::OVERWRITE,
                                options,
                                &mut Scratch::none(),
                            ),
                            1 => gemm_packed(
                                &mut t,
                                &Linear::OVERWRITE,
                                options,
                                &mut Scratch::new(&mut panels),
                            ),
                            _ => gemm_packed(
                                &mut t,
                                &Linear::OVERWRITE,
                                options,
                                &mut Scratch::with_accumulators(&mut panels, &mut accs),
                            ),
                        }
                    }
                    assert_eq!(full, want, "full-depth, {m}x{k}x{n} {mode:?}");
                    assert_eq!(chunked, want, "depth-chunked, {m}x{k}x{n} {mode:?}");
                }
            }
        }
    }

    /// `CD-01`, `CB-06`: a shape narrower than the tile takes the reduce
    /// factorization and produces the same bytes.
    ///
    /// Which factorization runs is decided by the shape against `nr`, so this
    /// sweeps `n` across that boundary and compares every result against the
    /// streaming reference. If the reduce panel layout, its horizontal sum, or
    /// its `k`-padding were wrong, this is where it would show --- and a
    /// matrix-vector product is the shape it matters most for.
    #[test]
    fn narrow_shapes_take_the_reduce_factorization_cb_06() {
        let nr = uor_matmul_kernels::choose_for_rows(
            uor_matmul_kernels::available_i8(),
            Backend::Auto,
            <Full<i8> as uor_matmul_core::Bound>::VALUE,
            usize::MAX,
        )
        .unwrap()
        .nr;
        assert!(nr > 1, "the tile kernel produces more than one column");

        for n in [1usize, 2, 3, nr - 1, nr, nr + 1] {
            for m in [1usize, 2, 5, 8, 13] {
                for k in [1usize, 2, 7, 32, 33, 100, 512] {
                    let a: Vec<i8> = (0..m * k).map(|i| ((i * 37) % 251) as i8).collect();
                    let b: Vec<i8> = (0..k * n).map(|i| ((i * 53) % 241) as i8).collect();

                    let mut want = vec![0i32; m * n];
                    let mut got = vec![0i32; m * n];
                    let mut buf = vec![Alphabet::<i8, Full<i8>>::ZERO; 64 * (k + 1)];

                    for (out, packed) in [(&mut want, false), (&mut got, true)] {
                        let av = MatView::row_major(as_alphabet_full(&a), m, k).unwrap();
                        let bv = MatView::row_major(as_alphabet_full(&b), k, n).unwrap();
                        let cv = MatViewMut::row_major(out.as_mut_slice(), m, n).unwrap();
                        let mut t = Triple::new(av, bv, cv).unwrap();
                        if packed {
                            gemm_packed(
                                &mut t,
                                &Linear::OVERWRITE,
                                GemmOptions::default(),
                                &mut Scratch::new(&mut buf),
                            );
                        } else {
                            // The streaming reference: no panel, no kernel.
                            crate::gemm(
                                &mut t,
                                &Linear::OVERWRITE,
                                GemmOptions::default(),
                                &mut Scratch::none(),
                            );
                        }
                    }
                    assert_eq!(got, want, "m={m} k={k} n={n}");
                }
            }
        }
    }

    /// The cursor lands on exactly the slots the declared layout names.
    ///
    /// The packer walks the panel instead of computing
    /// [`uor_matmul_kernels::packed_slot`] per element, so the two must agree by
    /// construction rather than by inspection --- and the kernels read the
    /// declared layout, so a cursor that drifted would corrupt every panel.
    #[test]
    fn the_cursor_agrees_with_the_declared_layout() {
        for lanes in 1..=16usize {
            for group in 1..=8usize {
                for lane in 0..lanes {
                    let mut cursor = super::Cursor::new(lane, lanes, group);
                    for p in 0..64usize {
                        assert_eq!(
                            cursor.at,
                            uor_matmul_kernels::packed_slot(p, lane, lanes, group),
                            "lanes={lanes} group={group} lane={lane} p={p}"
                        );
                        cursor.advance();
                    }
                }
            }
        }
    }

    /// Run one instantiation through the packed driver.
    #[allow(clippy::too_many_arguments)]
    fn packed<E, O>(
        m: usize,
        k: usize,
        n: usize,
        a: &[E],
        b: &[E],
        backend: Backend,
        mode: EncodeMode,
        scratch_len: usize,
    ) -> Vec<O>
    where
        E: Kernelized,
        O: Element + EncodeFrom<AccOf<E>> + Default + Clone,
        Linear: Epilogue<E, O>,
    {
        let mut c = vec![O::default(); m * n];
        let mut buf = vec![Alphabet::<E, Full<E>>::ZERO; scratch_len];
        {
            let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
            let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
            let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            gemm_packed(
                &mut t,
                &Linear::OVERWRITE,
                GemmOptions {
                    backend,
                    encode: mode,
                    ..Default::default()
                },
                &mut Scratch::new(&mut buf),
            );
        }
        c
    }

    /// The generic driver's answer, which consults no kernel at all.
    fn generic<E, O>(m: usize, k: usize, n: usize, a: &[E], b: &[E], mode: EncodeMode) -> Vec<O>
    where
        E: IntegerElement,
        O: Element + EncodeFrom<AccOf<E>> + Default + Clone,
        Linear: Epilogue<E, O>,
    {
        let mut c = vec![O::default(); m * n];
        {
            let av = MatView::row_major(as_alphabet_full(a), m, k).unwrap();
            let bv = MatView::row_major(as_alphabet_full(b), k, n).unwrap();
            let cv = MatViewMut::row_major(&mut c, m, n).unwrap();
            let mut t = Triple::new(av, bv, cv).unwrap();
            crate::gemm(
                &mut t,
                &Linear::OVERWRITE,
                GemmOptions {
                    encode: mode,
                    ..Default::default()
                },
                &mut Scratch::none(),
            );
        }
        c
    }

    fn fill<T, F: Fn(i64) -> T>(len: usize, salt: u64, map: F) -> Vec<T> {
        let mut s = 0x9E37_79B9_7F4A_7C15u64 ^ salt;
        (0..len)
            .map(|_| {
                s ^= s << 13;
                s ^= s >> 7;
                s ^= s << 17;
                map((s >> 33) as i64)
            })
            .collect()
    }

    const SHAPES: &[(usize, usize, usize)] = &[
        (1, 1, 1),
        (3, 7, 11),
        (13, 17, 19),
        (8, 256, 32),
        (5, 97, 7),
        (33, 5, 41),
    ];

    /// `CD-01`: every backend, every scratch amount, and every factorization
    /// give the generic driver's bytes --- at every instantiation that has a
    /// kernel, not just at the one the instructions were written for.
    #[test]
    fn every_instantiation_matches_the_generic_driver_cd_01() {
        for &(m, k, n) in SHAPES {
            let a8 = fill(m * k, 1, |v| v as i8);
            let b8 = fill(k * n, 2, |v| v as i8);
            let a16 = fill(m * k, 3, |v| v as i16);
            let b16 = fill(k * n, 4, |v| v as i16);
            let a32 = fill(m * k, 5, |v| v as i32);
            let b32 = fill(k * n, 6, |v| v as i32);
            let a64 = fill(m * k, 7, |v| v.wrapping_mul(0x1000_0000_01B3));
            let b64 = fill(k * n, 8, |v| v.wrapping_mul(0x9E37_79B9));

            let want8: Vec<i32> = generic(m, k, n, &a8, &b8, EncodeMode::Wrapping);
            let want16: Vec<i32> = generic(m, k, n, &a16, &b16, EncodeMode::Wrapping);
            let want32: Vec<i32> = generic(m, k, n, &a32, &b32, EncodeMode::Wrapping);
            let want64: Vec<i64> = generic(m, k, n, &a64, &b64, EncodeMode::Wrapping);

            for backend in Backend::ALL {
                for scratch_len in [0usize, 1, 64, 4096, 1 << 18] {
                    assert_eq!(
                        packed::<i8, i32>(
                            m,
                            k,
                            n,
                            &a8,
                            &b8,
                            backend,
                            EncodeMode::Wrapping,
                            scratch_len
                        ),
                        want8,
                        "i8 {m}x{k}x{n} on {} with {scratch_len}",
                        backend.as_str()
                    );
                    assert_eq!(
                        packed::<i16, i32>(
                            m,
                            k,
                            n,
                            &a16,
                            &b16,
                            backend,
                            EncodeMode::Wrapping,
                            scratch_len
                        ),
                        want16,
                        "i16 {m}x{k}x{n} on {}",
                        backend.as_str()
                    );
                    assert_eq!(
                        packed::<i32, i32>(
                            m,
                            k,
                            n,
                            &a32,
                            &b32,
                            backend,
                            EncodeMode::Wrapping,
                            scratch_len
                        ),
                        want32,
                        "i32 {m}x{k}x{n} on {}",
                        backend.as_str()
                    );
                    assert_eq!(
                        packed::<i64, i64>(
                            m,
                            k,
                            n,
                            &a64,
                            &b64,
                            backend,
                            EncodeMode::Wrapping,
                            scratch_len
                        ),
                        want64,
                        "i64 {m}x{k}x{n} on {}",
                        backend.as_str()
                    );
                }
            }
        }
    }

    /// `CD-05`: the encode mode selects the factorization, and both give the
    /// value that mode asks for.
    ///
    /// Under `Saturating` the exact lane runs and the answer is the clamped
    /// mathematical value; under `Wrapping` the modular lane runs and the
    /// answer is the same bytes the exact accumulation would have wrapped to.
    /// One identity, two quotients, and the caller names which.
    #[test]
    fn the_encode_mode_selects_the_factorization_cd_05() {
        let (m, k, n) = (4usize, 500usize, 4usize);
        let a = vec![i8::MAX; m * k];
        let b = vec![i8::MAX; k * n];

        let wrapping: Vec<i32> = packed(
            m,
            k,
            n,
            &a,
            &b,
            Backend::Auto,
            EncodeMode::Wrapping,
            1 << 16,
        );
        assert_eq!(
            wrapping,
            generic::<i8, i32>(m, k, n, &a, &b, EncodeMode::Wrapping)
        );

        let saturating: Vec<i32> = packed(
            m,
            k,
            n,
            &a,
            &b,
            Backend::Auto,
            EncodeMode::Saturating,
            1 << 16,
        );
        assert_eq!(
            saturating,
            generic::<i8, i32>(m, k, n, &a, &b, EncodeMode::Saturating)
        );

        // The exact value is 500 * 127 * 127, which fits i32, so the two agree
        // here. Deeper, they must not --- and that is the next assertion.
        assert_eq!(wrapping[0], 500 * 127 * 127);

        let deep = 200_000usize;
        let a = vec![i8::MAX; deep];
        let b = vec![i8::MAX; deep];
        let w: Vec<i32> = packed(
            1,
            deep,
            1,
            &a,
            &b,
            Backend::Auto,
            EncodeMode::Wrapping,
            1 << 16,
        );
        let s: Vec<i32> = packed(
            1,
            deep,
            1,
            &a,
            &b,
            Backend::Auto,
            EncodeMode::Saturating,
            1 << 16,
        );
        assert_eq!(
            w[0],
            ((deep as i64) * 127 * 127) as i32,
            "wrapping truncates"
        );
        assert_eq!(s[0], i32::MAX, "saturating clamps");
        assert_ne!(w, s, "past i32 the two encode modes must disagree");
    }

    /// `CT-01`: a depth past every lane's reach is still exact, because the
    /// chunking is a register question and the chunks combine exactly.
    #[test]
    fn depth_past_every_lane_is_exact_ct_01() {
        let k = 300_000;
        let a = vec![i8::MIN; k];
        let b = vec![i8::MIN; k];
        let expected = ((k as i128) * 128 * 128) as i32;
        for backend in Backend::ALL {
            let got: Vec<i32> = packed(1, k, 1, &a, &b, backend, EncodeMode::Wrapping, 1 << 16);
            assert_eq!(got, vec![expected], "{}", backend.as_str());
        }
    }
}
