//! The tiers (§6.2).
//!
//! Instantiations, not special cases. Each is roughly twenty lines, and none of
//! them contains any arithmetic that the others do not: a tier names a decode,
//! and the accumulation downstream of it is the same accumulation for every
//! tier in this file.

use core::marker::PhantomData;

use bytemuck::TransparentWrapper as _;
use uor_matmul_core::{Alphabet, Bound, IntegerElement};

use crate::tier::{Codec, TierId};

/// The three parameters `Offset` carries without storing: the input bound, the
/// output bound, and the element type. Invariant in none of them, so the marker
/// is a function pointer rather than a `PhantomData<T>`.
type OffsetMarker<BdIn, BdOut, E> = PhantomData<fn() -> (BdIn, BdOut, E)>;

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

/// Decoding is a validated copy.
///
/// Zero-sized. The validation is the alphabet wrap itself, performed once at
/// the boundary by `as_alphabet_full` (which cannot fail) or `as_alphabet`
/// (which reports the observed bound rather than failing), so the code type is
/// [`Alphabet`] and there is nothing left for the decode to check (§5.2, §6.2).
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Identity;

impl<E: IntegerElement, Bd: Bound> Codec<E, Bd> for Identity {
    type Code = Alphabet<E, Bd>;
    const MAX_BLOCK: usize = 1;
    const TIER: TierId = TierId::Identity;

    fn decode_element(&self, code: Self::Code, _i: usize) -> Alphabet<E, Bd> {
        code
    }

    fn decode_seq(&self, codes: &[Self::Code], out: &mut [Alphabet<E, Bd>]) -> usize {
        out[..codes.len()].copy_from_slice(codes);
        codes.len()
    }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

/// Any lookup codec, of any code width.
///
/// The 16-entry i4 grid is `Grid<16>`; a 65536-entry one is `Grid<65536>`. The
/// library carries no hardcoded table size, and no size is privileged.
///
/// The code space of an `N`-entry grid is `Z/N`, so an arbitrary `u16` indexes
/// it modulo `N`. That is not a clamp and not an error path: it is what
/// "index into a table of `N` entries" means, and it is why this decode is
/// total on all `2^16` codes (C6).
#[derive(Clone, Copy, Debug)]
pub struct Grid<'a, E: IntegerElement, Bd: Bound, const N: usize> {
    table: &'a [Alphabet<E, Bd>; N],
}

impl<'a, E: IntegerElement, Bd: Bound, const N: usize> Grid<'a, E, Bd, N> {
    /// Borrow a decode table. The table is `Alphabet<E, Bd>`, so its image is
    /// in the alphabet by construction and there is nothing to validate.
    pub const fn new(table: &'a [Alphabet<E, Bd>; N]) -> Self {
        Self { table }
    }

    /// The table.
    pub const fn table(&self) -> &'a [Alphabet<E, Bd>; N] {
        self.table
    }
}

impl<E: IntegerElement, Bd: Bound, const N: usize> Codec<E, Bd> for Grid<'_, E, Bd, N> {
    type Code = u16;
    const MAX_BLOCK: usize = 1;
    const TIER: TierId = TierId::Grid;

    fn decode_element(&self, code: Self::Code, _i: usize) -> Alphabet<E, Bd> {
        self.table[(code as usize) % N]
    }
}

// ---------------------------------------------------------------------------
// Packed
// ---------------------------------------------------------------------------

/// Unpacks `P` sub-codes from one stored byte, then defers to `C`.
///
/// The i4 tier is `Packed<Grid<16>, 2>`. **Low sub-code first** --- normative,
/// pinned by case `nibble-order` and asserted by `CK-03`.
///
/// `P` is arbitrary: two nibbles, four two-bit codes, eight one-bit codes. The
/// sub-code width is `8 / P`, so `P` must divide 8, which [`Packed::new`]
/// checks once at construction.
#[derive(Clone, Copy, Debug)]
pub struct Packed<C, const P: usize> {
    inner: C,
}

impl<C, const P: usize> Packed<C, P> {
    /// Bits per sub-code.
    pub const SUB_BITS: u32 = (8 / P) as u32;

    /// Wrap `inner`, unpacking `P` sub-codes per byte.
    ///
    /// `None` when `P` does not divide 8, which means no such packing exists.
    pub fn new(inner: C) -> Option<Self> {
        if P == 0 || 8 % P != 0 {
            return None;
        }
        Some(Self { inner })
    }
}

impl<E, Bd, C, const P: usize> Codec<E, Bd> for Packed<C, P>
where
    E: IntegerElement,
    Bd: Bound,
    C: Codec<E, Bd>,
    C::Code: From<u8>,
{
    type Code = u8;
    const MAX_BLOCK: usize = P * C::MAX_BLOCK;
    const TIER: TierId = TierId::Packed;
    const IS_FIXED_WIDTH: bool = C::IS_FIXED_WIDTH;

    fn decode_element(&self, code: Self::Code, i: usize) -> Alphabet<E, Bd> {
        let bits = Self::SUB_BITS;
        let mask: u8 = if bits >= 8 {
            u8::MAX
        } else {
            (1u8 << bits) - 1
        };
        // Low sub-code first. This is normative: a reader that took the high
        // sub-code first would decode a different matrix from the same bytes,
        // so the order is pinned rather than left to convention (CK-03).
        let p = i / C::MAX_BLOCK;
        let sub = (code >> (bits * p as u32)) & mask;
        self.inner
            .decode_element(C::Code::from(sub), i % C::MAX_BLOCK)
    }
}

// ---------------------------------------------------------------------------
// Book
// ---------------------------------------------------------------------------

/// Any codebook: `N` entries of `BLK` alphabet elements each.
///
/// E8 is `Book<256, 8>`. Nothing privileges that shape; `BLK` and `N` are
/// parameters, and no quality claim attaches to any table (N3).
#[derive(Clone, Copy, Debug)]
pub struct Book<'a, E: IntegerElement, Bd: Bound, const N: usize, const BLK: usize> {
    table: &'a [[Alphabet<E, Bd>; BLK]; N],
}

impl<'a, E: IntegerElement, Bd: Bound, const N: usize, const BLK: usize> Book<'a, E, Bd, N, BLK> {
    /// Borrow a codebook. On an embedded target this is a pointer into flash.
    pub const fn new(table: &'a [[Alphabet<E, Bd>; BLK]; N]) -> Self {
        Self { table }
    }

    /// The codebook.
    pub const fn table(&self) -> &'a [[Alphabet<E, Bd>; BLK]; N] {
        self.table
    }
}

impl<E: IntegerElement, Bd: Bound, const N: usize, const BLK: usize> Codec<E, Bd>
    for Book<'_, E, Bd, N, BLK>
{
    type Code = u16;
    const MAX_BLOCK: usize = BLK;
    const TIER: TierId = TierId::Book;

    fn decode_element(&self, code: Self::Code, i: usize) -> Alphabet<E, Bd> {
        self.table[(code as usize) % N][i % BLK]
    }

    fn decode_into(&self, code: Self::Code, out: &mut [Alphabet<E, Bd>]) -> usize {
        out[..BLK].copy_from_slice(&self.table[(code as usize) % N]);
        BLK
    }
}

// ---------------------------------------------------------------------------
// Offset
// ---------------------------------------------------------------------------

/// `d(c) - z`: asymmetric quantization as a codec composition, not a feature.
///
/// A zero point is a codec, which is why the library needs no separate
/// "asymmetric" mode and no branch for one (§1.3).
///
/// Decoding widens the alphabet: an inner value bounded by `BdIn` and a zero
/// point of magnitude `|z|` produce a value bounded by `BdIn + |z|`. That is
/// why the output bound is a separate parameter, and why [`Offset::new`]
/// checks, once and in O(1), that the declared output bound covers the image
/// and that no value overflows the element type. A `None` means no such codec
/// exists --- the same category as a non-conformant shape, decided before any
/// arithmetic (C6).
#[derive(Clone, Copy, Debug)]
pub struct Offset<E: IntegerElement, BdIn: Bound, BdOut: Bound, C: Codec<E, BdIn>> {
    inner: C,
    zero: E,
    _marker: OffsetMarker<BdIn, BdOut, E>,
}

impl<E: IntegerElement, BdIn: Bound, BdOut: Bound, C: Codec<E, BdIn>> Offset<E, BdIn, BdOut, C> {
    /// Compose `inner` with the zero point `zero`.
    ///
    /// `None` when `BdIn + |zero|` exceeds the declared output bound or the
    /// element type's own range, in which case the decode this describes does
    /// not land in the alphabet it claims to.
    pub fn new(inner: C, zero: E) -> Option<Self> {
        let image = BdIn::VALUE.checked_add(zero.magnitude())?;
        if image > BdOut::VALUE || image > E::FULL {
            return None;
        }
        Some(Self {
            inner,
            zero,
            _marker: PhantomData,
        })
    }

    /// The zero point.
    pub const fn zero(&self) -> E {
        self.zero
    }
}

impl<E, BdIn, BdOut, C> Codec<E, BdOut> for Offset<E, BdIn, BdOut, C>
where
    E: IntegerElement,
    BdIn: Bound,
    BdOut: Bound,
    C: Codec<E, BdIn>,
{
    type Code = C::Code;
    const MAX_BLOCK: usize = C::MAX_BLOCK;
    const TIER: TierId = TierId::Offset;
    const IS_FIXED_WIDTH: bool = C::IS_FIXED_WIDTH;

    fn decode_element(&self, code: Self::Code, i: usize) -> Alphabet<E, BdOut> {
        let inner = self.inner.decode_element(code, i).get();
        // Exact: `new` established that `BdIn + |zero| <= min(BdOut, E::FULL)`,
        // so this subtraction neither overflows the element type nor leaves the
        // declared output alphabet. The wrap is therefore not an unchecked
        // assertion; it is the O(1) check in `new` being cashed in.
        Alphabet::<E, BdOut>::wrap(inner.sub(self.zero))
    }
}

// ---------------------------------------------------------------------------
// Runs
// ---------------------------------------------------------------------------

/// Sparse storage as a codec, not as a separate algorithm and not as a separate
/// crate (D-16).
///
/// A run is `(length, code)`: `length` consecutive decoded elements, all of
/// them `d(code)`. A gap is a run whose code decodes to the alphabet's zero, so
/// the zeros are *explicit* and the arithmetic downstream stays dense. No
/// sparse-specific speedup is claimed; the benefit is residency, and `CG-03`
/// measures it like any other codec's.
///
/// A code is a *run index*, and the run's length is what [`Codec::decode_len`]
/// reports. `MAX_RUN` is the longest run the caller declares, so this tier is
/// variable-length within a compile-time bound --- which is exactly what the
/// `MAX_BLOCK` spelling is for (S4, S5b).
#[derive(Clone, Copy, Debug)]
pub struct Runs<'a, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>, const MAX_RUN: usize> {
    runs: &'a [(u32, C::Code)],
    inner: C,
    _marker: PhantomData<fn() -> (E, Bd)>,
}

impl<'a, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>, const MAX_RUN: usize>
    Runs<'a, E, Bd, C, MAX_RUN>
{
    /// Borrow a run list.
    ///
    /// `None` when a run is empty or longer than `MAX_RUN`, both of which mean
    /// the list describes no stream. Decided at construction, before any
    /// arithmetic, like every other non-existence in this library (C6).
    pub fn new(inner: C, runs: &'a [(u32, C::Code)]) -> Option<Self> {
        if runs
            .iter()
            .any(|&(len, _)| len == 0 || len as usize > MAX_RUN)
        {
            return None;
        }
        Some(Self {
            runs,
            inner,
            _marker: PhantomData,
        })
    }

    /// The number of stored runs, which is the residency this tier buys.
    pub const fn run_count(&self) -> usize {
        self.runs.len()
    }

    /// The decoded length of the whole run list.
    ///
    /// `CK-06` asserts this equals the declared row width, which is the
    /// invariant that lets a variable-length tier live inside `Codec`.
    pub fn decoded_len(&self) -> usize {
        self.runs.iter().map(|&(len, _)| len as usize).sum()
    }
}

impl<E: IntegerElement, Bd: Bound, C: Codec<E, Bd>, const MAX_RUN: usize> Codec<E, Bd>
    for Runs<'_, E, Bd, C, MAX_RUN>
{
    type Code = u32;
    const MAX_BLOCK: usize = MAX_RUN;
    const TIER: TierId = TierId::Runs;
    // The one variable-length tier: a run is as long as it is.
    const IS_FIXED_WIDTH: bool = false;

    fn decode_len(&self, run: Self::Code) -> usize {
        self.runs
            .get(run as usize)
            .map_or(0, |&(len, _)| len as usize)
    }

    fn decode_element(&self, run: Self::Code, i: usize) -> Alphabet<E, Bd> {
        match self.runs.get(run as usize) {
            // Every element of a run decodes the run's code. For an inner tier
            // that is itself a block codec, the position within the block is
            // `i % C::MAX_BLOCK`, so a run of an E8 codeword repeats the whole
            // codeword rather than its first element.
            Some(&(_, code)) => self.inner.decode_element(code, i % C::MAX_BLOCK),
            // Past the end of the run list: the alphabet's zero, explicitly.
            None => Alphabet::ZERO,
        }
    }
}

// ---------------------------------------------------------------------------
// Transcode
// ---------------------------------------------------------------------------

/// A total map from one code space to another.
///
/// This is the first half of the upstream `transcode_decode` composite: the
/// part that is a relabelling rather than a decode.
pub trait CodeMap<In: Copy, Out: Copy>: Send + Sync {
    /// Relabel. Total on the whole input code space.
    fn map(&self, code: In) -> Out;
}

impl<In: Copy, Out: Copy, F> CodeMap<In, Out> for F
where
    F: Fn(In) -> Out + Send + Sync,
{
    fn map(&self, code: In) -> Out {
        self(code)
    }
}

/// The upstream `transcode_decode` composite: relabel, then decode.
///
/// Closed under composition, which is what makes a tier change a *change of
/// artifact* rather than a change of arithmetic (`CK-04`, `CL-MM03`).
///
/// The plan spells this `Transcode<C1, C2>`; the first parameter is a
/// [`CodeMap`] rather than a second [`Codec`], because a decode into the
/// alphabet cannot be the input of another decode --- only a relabelling can.
#[derive(Clone, Copy, Debug)]
pub struct Transcode<M, C, In> {
    map: M,
    inner: C,
    _marker: PhantomData<fn() -> In>,
}

impl<M, C, In> Transcode<M, C, In> {
    /// Compose a relabelling with a decode.
    pub const fn new(map: M, inner: C) -> Self {
        Self {
            map,
            inner,
            _marker: PhantomData,
        }
    }
}

impl<E, Bd, M, C, In> Codec<E, Bd> for Transcode<M, C, In>
where
    E: IntegerElement,
    Bd: Bound,
    C: Codec<E, Bd>,
    M: CodeMap<In, C::Code>,
    In: Copy + Send + Sync + 'static,
{
    type Code = In;
    const MAX_BLOCK: usize = C::MAX_BLOCK;
    const TIER: TierId = TierId::Transcode;
    const IS_FIXED_WIDTH: bool = C::IS_FIXED_WIDTH;

    fn decode_element(&self, code: Self::Code, i: usize) -> Alphabet<E, Bd> {
        self.inner.decode_element(self.map.map(code), i)
    }
}
