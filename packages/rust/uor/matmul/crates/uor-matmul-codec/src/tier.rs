//! The one trait every tier instantiates (§6.1).

use uor_matmul_core::{Alphabet, Bound, IntegerElement};

/// A decode from a stored code to alphabet elements.
///
/// `Bd` being a parameter of the trait is what makes the alphabet bound a
/// type-level fact the kernels can rely on without rechecking: a codec's table
/// is `&[Alphabet<E, Bd>]`, so its image is in the alphabet by construction and
/// there is nothing for a constructor to validate or reject (§6.2).
pub trait Codec<E: IntegerElement, Bd: Bound>: Send + Sync {
    /// The stored code type.
    ///
    /// Any `Copy` type: `i8` for identity, `u8` for a nibble pair or an E8
    /// index, `u16` for a 65536-entry codebook. The library carries no
    /// hardcoded code width.
    type Code: Copy + Send + Sync + 'static;

    /// The most alphabet elements one code can produce.
    ///
    /// 1 for scalar, 2 for nibble-packed, 8 for E8, arbitrary in general. This
    /// is the const that makes a scalar codec the block codec of its
    /// singletons, so that one identity and one kernel cover both (`CL-MM02`).
    ///
    /// It is a *maximum*, not a fixed width: a variable-length codec ---
    /// a run codec, for one --- produces fewer than `MAX_BLOCK` elements for
    /// some codes, and [`Codec::decode_into`] returns how many it produced. A
    /// fixed width would have made run coding a second algorithm rather than a
    /// tier (S4, S5b).
    const MAX_BLOCK: usize;

    /// Which tier this is, for reports and for the kappa manifest.
    const TIER: TierId;

    /// Decode element `i` of the block `code` names. Total for every `i`.
    ///
    /// This is the trait's one required method rather than the block decode,
    /// so that a composing tier --- [`crate::Offset`], [`crate::Runs`],
    /// [`crate::Transcode`] --- can defer to its inner codec without owning a
    /// scratch buffer the size of a block. No allocation is possible anywhere
    /// in this crate, so a required block decode would have forced either a
    /// hardcoded maximum block size or an `alloc` dependency, and both are
    /// arbitrary limitations (R7, R8).
    ///
    /// There is no code value of `Self::Code` and no `i` for which this fails:
    /// a codec whose table did not cover its code space could not have been
    /// constructed, and `i >= BLOCK` is answered by the block's own padding.
    fn decode_element(&self, code: Self::Code, i: usize) -> Alphabet<E, Bd>;

    /// Is `decode_len` always `MAX_BLOCK`?
    ///
    /// True for every fixed-width tier, which is all of them except a run
    /// codec. It is what lets [`crate::CodedMatrix`] find the codes of row `r`
    /// by arithmetic rather than by walking, and the difference is not a
    /// constant factor: a walk makes random access O(row length), and a driver
    /// that reads one element at a time then runs in O(k^2 n) instead of
    /// O(m k n). A variable-length tier pays that cost only if the caller uses
    /// random access on it; the row and range decodes walk each row once.
    const IS_FIXED_WIDTH: bool = true;

    /// How many elements `code` actually produces.
    ///
    /// `MAX_BLOCK` for a fixed-width tier, and possibly fewer for a
    /// variable-length one. `CK-06` asserts that these counts sum to the
    /// declared row width on every row, which is the invariant that lets a run
    /// codec live inside this trait rather than beside it.
    fn decode_len(&self, _code: Self::Code) -> usize {
        Self::MAX_BLOCK
    }

    /// Decode one code, returning how many elements were written.
    ///
    /// `out.len() >= decode_len(code)`. Total, side-effect free, and
    /// allocation-free. The default loops [`Codec::decode_element`]; a tier
    /// overrides it only when it can produce the same bytes faster, never
    /// differently.
    fn decode_into(&self, code: Self::Code, out: &mut [Alphabet<E, Bd>]) -> usize {
        let n = self.decode_len(code).min(out.len());
        for (i, slot) in out.iter_mut().enumerate().take(n) {
            *slot = self.decode_element(code, i);
        }
        n
    }

    /// Bulk path, returning how many elements were written in total.
    fn decode_seq(&self, codes: &[Self::Code], out: &mut [Alphabet<E, Bd>]) -> usize {
        let mut at = 0usize;
        for &code in codes {
            at += self.decode_into(code, &mut out[at..]);
        }
        at
    }
}

/// Which tier a codec is.
///
/// A label, never a dispatch key: nothing in the library branches on it, and
/// two codecs with different `TierId`s and equal decodes produce byte-identical
/// output (`CK-05`).
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
#[non_exhaustive]
pub enum TierId {
    /// Decoding is a validated copy.
    Identity,
    /// A lookup table of any code width.
    Grid,
    /// Sub-codes unpacked from one stored byte.
    Packed,
    /// A codebook of any entry count and any block size.
    Book,
    /// `d(c) - z`: asymmetric quantization as a codec composition.
    Offset,
    /// Sparse storage as a codec.
    Runs,
    /// The composite of two codecs.
    Transcode,
}

impl TierId {
    /// The token used in the kappa manifest and in reports.
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Identity => "Identity",
            Self::Grid => "Grid",
            Self::Packed => "Packed",
            Self::Book => "Book",
            Self::Offset => "Offset",
            Self::Runs => "Runs",
            Self::Transcode => "Transcode",
        }
    }
}
