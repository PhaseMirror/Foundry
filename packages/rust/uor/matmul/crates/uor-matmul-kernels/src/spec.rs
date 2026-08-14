//! The kernel table (§7.1).
//!
//! One signature per element family, identical across ISAs. A [`KernelSpec`] is
//! a value; adding an ISA adds one and touches no driver code.
//!
//! # The two factorizations
//!
//! Both compute the same thing. Neither is a fallback, and neither is a
//! classical method: they are the one identity, factored two ways.
//!
//! [`Factorization::Exact`] accumulates in a lane wide enough that the partial
//! sum cannot leave it, and the lanes fold into `AccOf<E>` --- which cannot
//! overflow at all --- before the single encode step. The lane width is decided
//! from the declared alphabet bound.
//!
//! [`Factorization::Modular`] applies when the caller asks to encode by
//! wrapping into a `w`-bit output. Reduction modulo `2^w` is a ring
//! homomorphism, so reducing the exact sum once at the end equals reducing at
//! every step: accumulating in `Z/2^w` *is* the exact accumulation, seen in the
//! quotient the caller asked for. That is the same fact §3.4 rests on for the
//! integer oracles, and it is what lets a `w`-bit lane carry an unbounded depth
//! with no wide accumulator behind it.
//!
//! Which one runs is decided by the caller's *declarations* --- the alphabet
//! bound and the encode mode --- never by a heuristic and never by the data.

use uor_matmul_core::Backend;

/// Where element `p` of lane `l` sits inside a packed panel of `lanes` lanes
/// grouped by `group`.
///
/// The panel layout is part of the kernel contract, so it is written down once,
/// here, next to [`KernelSpec::k_group`]: `k`-major in groups of `group`,
/// lane-major within a group. At `group == 1` this is the plain `k`-major layout
/// the reference kernels read.
///
/// Every kernel's index arithmetic is this function specialized to its own
/// constants, the driver's packer is this function directly, and the parity
/// tests read panels through it --- so a kernel that disagrees with the layout
/// disagrees with the reference, which is what `CB-01` through `CB-05` catch.
#[inline(always)]
pub const fn packed_slot(p: usize, lane: usize, lanes: usize, group: usize) -> usize {
    (p / group) * (lanes * group) + lane * group + (p % group)
}

/// How a packed panel arranges one lane's depth.
///
/// Both are [`packed_slot`] --- the difference is only what `group` is --- so
/// there is one layout function and one packer, not two.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum LaneLayout {
    /// Lanes interleave every [`KernelSpec::k_group`] elements. This is what a
    /// kernel wants when its vector lanes are *columns of the output*: one load
    /// brings in the same `k`-group for every lane at once.
    Interleaved,
    /// Each lane's whole depth is contiguous. This is what a kernel wants when
    /// its vector lanes are *steps of the reduction*: one load brings in a run of
    /// `k` for a single lane.
    Contiguous,
}

/// Which factorization of the identity a kernel realizes.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub enum Factorization {
    /// The lane holds the partial sum exactly; lanes fold into `AccOf<E>`.
    Exact,
    /// The lane is `Z/2^w` for the `w`-bit output the caller asked to wrap
    /// into. Exact in the quotient, by ring homomorphism.
    Modular,
}

/// One backend's microkernel for one element family, and its blocking shape.
///
/// `E` is the packed element type and `L` is the lane the kernel accumulates
/// in. The driver reads `mr`, `nr`, and `k_group` through this value rather
/// than through a `match` on [`Backend`], which is what keeps the driver free
/// of per-ISA code.
pub struct KernelSpec<E, L> {
    /// Which backend this is.
    pub backend: Backend,
    /// Which factorization it realizes.
    pub factorization: Factorization,
    /// Rows of `C` this kernel produces per call.
    pub mr: usize,
    /// Columns of `C` this kernel produces per call.
    pub nr: usize,
    /// How the packed panels arrange each lane's depth.
    ///
    /// [`LaneLayout::Interleaved`] for a kernel whose vector lanes are output
    /// columns, which is every tile kernel. [`LaneLayout::Contiguous`] for one
    /// whose vector lanes are steps of the reduction --- see
    /// [`available_reduce_i8`].
    pub lane_layout: LaneLayout,
    /// How many `k`-steps this kernel consumes at once, and therefore how the
    /// packed panels are laid out.
    ///
    /// A panel is `k`-major in groups of `k_group` and lane-major within a
    /// group, so element `p` of lane `l` sits at
    /// `(p / k_group) * (lanes * k_group) + l * k_group + (p % k_group)`. A
    /// kernel that consumes two `k`-steps per instruction therefore finds them
    /// adjacent, and needs neither a shuffle to pair them nor a scalar gather to
    /// build the pair by hand.
    ///
    /// Not a restriction on the caller's `k`: the driver pads the depth to a
    /// multiple of this with the alphabet's zero, which contributes nothing to
    /// the sum and nothing to the lane. An arbitrary `k` therefore takes this
    /// path and not a different one, and no kernel has a `k`-tail (S8).
    pub k_group: usize,
    /// How many products this sequence computes per issued instruction.
    ///
    /// The driver has two traversals and no way to compare them without this.
    /// The packed one pads the shape up to whole panels and copies them; the
    /// streaming one does exactly the products the shape names and copies
    /// nothing. Which is cheaper is a comparison of the padded product count
    /// divided by this against `m * k * n`, and that comparison is meaningless
    /// unless a sequence says how much a padded product actually costs it.
    ///
    /// `_mm256_madd_epi16` on `i8`-derived words is sixteen: eight `i32` lanes,
    /// each the sum of two products. The reference is one.
    ///
    /// It cannot change a value --- it is a claim about instructions, and
    /// `CD-01` asserts every traversal gives the same bytes whatever it says.
    pub products_per_step: usize,
    /// The largest magnitude one lane holds.
    ///
    /// Ignored for [`Factorization::Modular`], where the lane wraps by design
    /// and the depth is unbounded.
    pub lane_cap: u128,
    /// The widest alphabet bound at which this sequence is exact.
    ///
    /// A lane's *depth* is bounded by [`Self::lane_cap`], and the driver answers
    /// that by chunking. This is the other question, and chunking cannot answer
    /// it: some sequences have an intermediate narrower than the lane, and there
    /// is a magnitude past which that intermediate is wrong however shallow the
    /// chunk.
    ///
    /// `_mm256_madd_epi16` is the case. It sums two products into an `i32`, and
    /// two full-magnitude `i16` products are `2 * 2^30` --- one bit past it. For
    /// any bound at or below `32767` the pair fits and the sequence is exact; at
    /// the full `i16` alphabet it is not, and no depth makes it so.
    ///
    /// So the sequence declares the alphabet it is exact on, and [`choose`]
    /// respects the declaration. That is the same shape of rule as the modular
    /// factorization's: which instructions are admissible is a question about
    /// the caller's declarations, never about the data (R13).
    pub max_bound: u128,
    /// Accumulate an `mr x nr` tile of `C` over a `kc`-deep packed panel pair.
    ///
    /// # Safety
    ///
    /// The caller must ensure `pa` has `mr * kc` readable elements, `pb` has
    /// `nr * kc`, `acc` has `mr * nr` writable lanes, and that the target
    /// features this backend names are present on the host. [`Self::mac_tile`]
    /// establishes the first three; the `available_*` functions establish the
    /// fourth.
    pub mac_tile: unsafe fn(kc: usize, pa: *const E, pb: *const E, acc: *mut L),
}

impl<E, L> Clone for KernelSpec<E, L> {
    fn clone(&self) -> Self {
        *self
    }
}

impl<E, L> Copy for KernelSpec<E, L> {}

impl<E, L> core::fmt::Debug for KernelSpec<E, L> {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.debug_struct("KernelSpec")
            .field("backend", &self.backend)
            .field("factorization", &self.factorization)
            .field("mr", &self.mr)
            .field("nr", &self.nr)
            .field("k_group", &self.k_group)
            .field("max_bound", &self.max_bound)
            .finish_non_exhaustive()
    }
}

impl<E, L> KernelSpec<E, L> {
    /// The safe entry point: accumulate an `mr x nr` tile.
    ///
    /// Panics only on a length disagreement, which is a programming error in
    /// the *driver* rather than a condition of the data --- no input a caller
    /// can supply reaches it, which is why `gemm` still returns `()`.
    pub fn mac_tile(&self, kc: usize, pa: &[E], pb: &[E], acc: &mut [L]) {
        assert_eq!(pa.len(), self.mr * kc, "packed A panel is mr * kc");
        assert_eq!(pb.len(), self.nr * kc, "packed B panel is nr * kc");
        assert_eq!(acc.len(), self.mr * self.nr, "accumulator tile is mr * nr");
        assert!(
            kc.is_multiple_of(self.k_group),
            "the packed depth is a whole number of k-groups"
        );
        // SAFETY: the three lengths are exactly what `mac_tile` requires, and
        // this `KernelSpec` came from one of the `available_*` functions, which
        // only ever return a spec whose target features the host has.
        unsafe { (self.mac_tile)(kc, pa.as_ptr(), pb.as_ptr(), acc.as_mut_ptr()) }
    }

    /// The deepest chunk this lane holds for an alphabet bounded by `bound`.
    ///
    /// A question about a register, not a limit on `k`: a deeper accumulation
    /// is split into more chunks, and the chunks combine exactly. For a modular
    /// lane there is nothing to bound --- the wrap *is* the encode.
    pub fn lane_depth(&self, bound: u128) -> usize {
        if matches!(self.factorization, Factorization::Modular) {
            return usize::MAX;
        }
        let per_step = bound.saturating_mul(bound); // R3-ok: a lane-width question, not an accumulation
        if per_step == 0 {
            return usize::MAX;
        }
        usize::try_from(self.lane_cap / per_step)
            .unwrap_or(usize::MAX)
            .max(1)
    }
}

/// The specs a build can run, portable first.
///
/// A chain of options rather than a fixed array, so the number of kernels a
/// family may have is not capped by a constant somebody chose. Adding one adds
/// a line here and nothing else (R8).
macro_rules! collect {
    ($($cond:expr => $spec:expr),* $(,)?) => {{
        core::iter::empty()
        $(
            .chain(core::iter::once_with(|| if $cond { Some($spec) } else { None }))
        )*
        .flatten()
    }};
}

/// The largest `mr * nr` any shipped kernel produces.
///
/// Derived rather than chosen: every kernel below carries a `const` assertion
/// that its own tile fits, so a kernel too large for this fails the *build*
/// rather than overflowing a buffer. That is what keeps it a derivation and not
/// a ceiling --- there is no input that can reach it, and no way to add a
/// kernel that quietly exceeds it.
pub const MAX_TILE_LANES: usize = 8 * 16;

/// Assert at compile time that a kernel's tile fits [`MAX_TILE_LANES`].
#[macro_export]
macro_rules! tile_fits {
    ($mr:expr, $nr:expr) => {
        const _: () = assert!(
            $mr * $nr <= $crate::MAX_TILE_LANES,
            "this kernel's tile exceeds MAX_TILE_LANES; raise it in the same commit"
        );
    };
}

/// Every `i8 x i8 -> i32` kernel this build can run, portable first.
#[inline]
pub fn available_i8() -> impl Iterator<Item = KernelSpec<i8, i32>> {
    collect![
        true => crate::isa::portable::I8_I32,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I8_I32_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I8_I32,
        crate::isa::x86::avx512vnni_available() => crate::isa::x86::AVX512_DPWSSD_I8_I32,
        crate::isa::x86::avx512vnni_available() => crate::isa::x86::AVX512_DPBUSD_I8_I32,
        crate::isa::arm::neon_available() => crate::isa::arm::NEON_I8_I32,
        crate::isa::arm::dotprod_available() => crate::isa::arm::NEON_DOTPROD_I8_I32,
        crate::isa::wasm::simd128_available() => crate::isa::wasm::SIMD128_I8_I32,
    ]
}

/// Every `i16 x i16 -> i64` kernel this build can run.
///
/// Two AVX2 sequences, and which is admissible is a question about the declared
/// alphabet. `_mm256_madd_epi16` is this family's arithmetic in one instruction
/// but sums its pair into an `i32`, so it is exact only up to a bound of
/// `32767`; the widening sequence is exact at every `i16` and issues more
/// instructions. The paired one is listed last so that a declaration admitting
/// it gets it.
#[inline]
pub fn available_i16() -> impl Iterator<Item = KernelSpec<i16, i64>> {
    collect![
        true => crate::isa::portable::I16_I64,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_I64_FULL_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_I64_FULL,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_I64_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_I64,
    ]
}

/// Every exact `i32 x i32 -> i64` kernel this build can run.
///
/// The product of two `i32` needs 62 bits, so the lane must be 64.
/// `_mm256_mul_epi32` is a signed `32x32 -> 64` multiply, which is this
/// family's whole arithmetic in one instruction.
#[inline]
pub fn available_i32_exact() -> impl Iterator<Item = KernelSpec<i32, i64>> {
    collect![
        true => crate::isa::portable::I32_I64,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I32_I64_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I32_I64,
    ]
}

/// Every modular `i32 x i32 -> i32` kernel this build can run.
///
/// The lane is `Z/2^32`. Legitimate exactly when the caller asked to encode by
/// wrapping into a 32-bit output, because then the lane's own wrap *is* the
/// encode and nothing is lost that the caller did not ask to lose.
#[inline]
pub fn available_i32_modular() -> impl Iterator<Item = KernelSpec<i32, i32>> {
    collect![
        true => crate::isa::portable::I32_MOD,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I32_MOD_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I32_MOD,
    ]
}

/// Every exact `i64 x i64 -> i128` kernel this build can run.
///
/// The product of two `i64` needs 128 bits, so the lane is an `i128`. No SIMD
/// integer multiply reaches that width on any target this crate supports, so
/// the portable kernel is not a placeholder here --- it is the whole of what
/// the hardware offers, and packing still buys it the locality every other
/// family gets.
#[inline]
pub fn available_i64_exact() -> impl Iterator<Item = KernelSpec<i64, i128>> {
    collect![
        true => crate::isa::portable::I64_I128,
    ]
}

/// Every modular `i16 x i16 -> i32` kernel this build can run.
///
/// Twice the lanes of the exact `i16` kernel, because in `Z/2^32` there is
/// nothing to widen to: `madd` already lands in `i32` and the accumulation
/// stays there.
#[inline]
pub fn available_i16_modular() -> impl Iterator<Item = KernelSpec<i16, i32>> {
    collect![
        true => crate::isa::portable::I16_MOD,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_MOD_M1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I16_MOD,
    ]
}

/// Every modular `i64 x i64 -> i64` kernel this build can run.
///
/// A single `i64 x i64` product needs 128 bits, so there is no exact 64-bit
/// lane and no SIMD integer multiply that reaches it. In the quotient there is:
/// `Z/2^64` needs only the low half of each product, which is what a plain
/// `wrapping_mul` gives.
#[inline]
pub fn available_i64_modular() -> impl Iterator<Item = KernelSpec<i64, i64>> {
    collect![
        true => crate::isa::portable::I64_MOD,
    ]
}

/// Every `i8` *reduce* sequence this build can run.
///
/// The reduce factorization puts the vector lanes on `k` rather than on the
/// columns of `C`. It is the one to use when the output is narrower than a tile:
/// a tile kernel produces `nr` columns per call whether they exist or not, so a
/// single dot product fills one lane in ninety-six, while there is always more
/// `k` to fill a lane with.
///
/// Not a special case and not a fallback --- the same identity, with the
/// reduction factored across lanes instead of the output. `CB-06` asserts it
/// agrees with the reference byte for byte, and the driver chooses between the
/// two by comparing the shape against the tile, which is a declaration.
#[inline]
/// The `i8` tile sequences over a *narrow* panel: half the columns.
///
/// A tile panel wider than the output is zero-padded and the kernel does that
/// padding's arithmetic, so at `n = 8` a sixteen-column panel is twice the work
/// the product needs --- measured, that made `i8` at `n = 8` slower than the same
/// kernel at `n = 16`.
///
/// Its own list rather than more entries in [`available_i8`], because the driver
/// only asks when the shape is narrower than the tile it already has. Adding
/// them to the ordinary list lengthened every selection, including the calls
/// that could never use one: measured, a hundred nanoseconds on a shape whose
/// whole cost is a hundred and twenty.
pub fn available_i8_narrow() -> impl Iterator<Item = KernelSpec<i8, i32>> {
    collect![
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I8_I32_M1_N8,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_I8_I32_N8,
    ]
}

/// Every `i8` *reduce* sequence this build can run.
///
/// The reduce factorization puts the vector lanes on `k` rather than on the
/// columns of `C`. It is the one to use when the output is narrower than a tile:
/// a tile kernel produces `nr` columns per call whether they exist or not, so a
/// single dot product fills one lane in ninety-six, while there is always more
/// `k` to fill a lane with.
///
/// Not a special case and not a fallback --- the same identity, with the
/// reduction factored across lanes instead of the output. `CB-06` asserts it
/// agrees with the reference byte for byte, and the driver chooses between the
/// two by comparing the shape against the tile, which is a declaration.
pub fn available_reduce_i8() -> impl Iterator<Item = KernelSpec<i8, i32>> {
    collect![
        true => crate::isa::portable::R1_I8_I32,
        true => crate::isa::portable::R_I8_I32,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I8_I32_1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I8_I32,
        crate::isa::arm::neon_available() => crate::isa::arm::NEON_R_I8_I32_1,
        crate::isa::arm::neon_available() => crate::isa::arm::NEON_R_I8_I32,
        crate::isa::arm::dotprod_available() => crate::isa::arm::NEON_DOTPROD_R_I8_I32_1,
        crate::isa::arm::dotprod_available() => crate::isa::arm::NEON_DOTPROD_R_I8_I32,
        crate::isa::wasm::simd128_available() => crate::isa::wasm::SIMD128_R_I8_I32_1,
        crate::isa::wasm::simd128_available() => crate::isa::wasm::SIMD128_R_I8_I32,
    ]
}

/// Every exact `i16` reduce sequence. See [`available_reduce_i8`].
#[inline]
pub fn available_reduce_i16() -> impl Iterator<Item = KernelSpec<i16, i64>> {
    collect![
        true => crate::isa::portable::R1_I16_I64,
        true => crate::isa::portable::R_I16_I64,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I16_I64_1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I16_I64,
    ]
}

/// Every modular `i16` reduce sequence. See [`available_reduce_i8`].
#[inline]
pub fn available_reduce_i16_modular() -> impl Iterator<Item = KernelSpec<i16, i32>> {
    collect![
        true => crate::isa::portable::R1_I16_MOD,
        true => crate::isa::portable::R_I16_MOD,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I16_MOD_1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I16_MOD,
    ]
}

/// Every exact `i32` reduce sequence. See [`available_reduce_i8`].
#[inline]
pub fn available_reduce_i32_exact() -> impl Iterator<Item = KernelSpec<i32, i64>> {
    collect![
        true => crate::isa::portable::R1_I32_I64,
        true => crate::isa::portable::R_I32_I64,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I32_I64_1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I32_I64,
    ]
}

/// Every modular `i32` reduce sequence. See [`available_reduce_i8`].
#[inline]
pub fn available_reduce_i32_modular() -> impl Iterator<Item = KernelSpec<i32, i32>> {
    collect![
        true => crate::isa::portable::R1_I32_MOD,
        true => crate::isa::portable::R_I32_MOD,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I32_MOD_1,
        crate::isa::x86::avx2_available() => crate::isa::x86::AVX2_R_I32_MOD,
    ]
}

/// Every exact `i64` reduce sequence.
///
/// An `i64 x i64` product needs 128 bits and no SIMD multiply reaches that width
/// on any supported target, so the reference is the whole of what the hardware
/// offers --- but the reduce *traversal* still buys this family what it buys
/// every other: a narrow output stops paying for columns that are not there.
#[inline]
pub fn available_reduce_i64_exact() -> impl Iterator<Item = KernelSpec<i64, i128>> {
    collect![
        true => crate::isa::portable::R1_I64_I128,
        true => crate::isa::portable::R_I64_I128,
    ]
}

/// Every modular `i64` reduce sequence. See [`available_reduce_i64_exact`].
#[inline]
pub fn available_reduce_i64_modular() -> impl Iterator<Item = KernelSpec<i64, i64>> {
    collect![
        true => crate::isa::portable::R1_I64_MOD,
        true => crate::isa::portable::R_I64_MOD,
    ]
}

/// Choose a sequence whose panel `rows` actually fills: the tallest such, and
/// the shortest when none does.
///
/// A panel taller than the block is zero-padded, and the padding is not free:
/// a tile kernel does its arithmetic, and a reduce kernel *copies* it, at `k`
/// elements a row. So a four-row panel serving one row does four times the work
/// the product needs --- and a one-row panel serving four rows gives up the
/// reuse a taller one would have had, so taller is right whenever the rows are
/// there.
///
/// The rows are a shape --- a declaration the caller made when they constructed
/// the view --- so this is selection by declaration, like every other choice in
/// this crate. Every candidate computes the same integer (`CB-06`).
#[inline]
pub fn choose_for_rows<E, L>(
    specs: impl Iterator<Item = KernelSpec<E, L>>,
    requested: Backend,
    bound: u128,
    rows: usize,
) -> Option<KernelSpec<E, L>> {
    // One pass. The list is ordered reference-first, and within a backend
    // narrowest-panel-first, so "a later entry of a different backend is wider"
    // and "a later entry of the same backend is a wider panel" are both just the
    // order --- which is what makes this a single comparison per entry rather
    // than a walk to find the backend and a second walk to find the panel.
    let mut best: Option<KernelSpec<E, L>> = None;
    for spec in specs.filter(|s| s.max_bound >= bound) {
        let Some(b) = best else {
            best = Some(spec);
            continue;
        };
        let take = if spec.backend == b.backend {
            // The widest panel the rows fill; the narrowest when none does.
            if b.mr > rows {
                spec.mr <= rows || spec.mr < b.mr
            } else {
                // `>=` and not `>`: at equal heights the later entry wins, and
                // the list is ordered reference-first, so later is the more
                // specialized sequence.
                spec.mr <= rows && spec.mr >= b.mr
            }
        } else {
            // A later entry is a wider backend --- take it, unless the caller
            // named one and this is already it.
            !(requested != Backend::Auto && b.backend == requested)
        };
        if take {
            best = Some(spec);
        }
    }
    best
}

/// The reference `i8` kernel. Always present, always correct, never a
/// fallback (R6).
pub const fn portable_i8() -> KernelSpec<i8, i32> {
    crate::isa::portable::I8_I32
}

/// Choose from a family: the backend the caller named, or the widest available,
/// among the sequences exact on an alphabet bounded by `bound`.
///
/// Selection cannot fail. [`Backend::Auto`] takes the last admissible entry,
/// which is the widest one the host can run; a named backend the host cannot run
/// yields the first, which computes the same value. That is not a fallback ---
/// there is no answer being given up (R13).
///
/// A sequence whose [`KernelSpec::max_bound`] is below `bound` is not considered
/// at all. It is not slower or riskier: at that alphabet it computes a different
/// number, so it is not a factorization of this identity.
#[inline]
pub fn choose<E, L>(
    specs: impl Iterator<Item = KernelSpec<E, L>>,
    requested: Backend,
    bound: u128,
) -> Option<KernelSpec<E, L>> {
    let mut first = None;
    let mut widest = None;
    let mut named = None;
    for spec in specs.filter(|s| s.max_bound >= bound) {
        if first.is_none() {
            first = Some(spec);
        }
        if spec.backend == requested {
            named = Some(spec);
        }
        widest = Some(spec);
    }
    match requested {
        Backend::Auto => widest.or(first),
        _ => named.or(first),
    }
}
