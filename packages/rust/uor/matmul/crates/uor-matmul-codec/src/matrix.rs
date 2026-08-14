//! Coded matrices (§6.3).

use core::ops::Range;

use uor_matmul_core::{Alphabet, Bound, IntegerElement};

use crate::tier::Codec;

/// A borrowed matrix of codes, together with the codec that decodes them.
///
/// The codes are borrowed and the codec's table is borrowed, so a
/// `CodedMatrix` is a handful of pointers and three integers. Nothing here is
/// owned, nothing is copied, and nothing is allocated (R7, C1).
#[derive(Clone, Copy, Debug)]
pub struct CodedMatrix<'a, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>> {
    codec: C,
    rows: usize,
    cols: usize,
    codes: &'a [C::Code],
    _marker: core::marker::PhantomData<fn() -> (E, Bd)>,
}

impl<'a, E: IntegerElement, Bd: Bound, C: Codec<E, Bd>> CodedMatrix<'a, E, Bd, C> {
    /// Borrow `codes` as an `rows x cols` coded matrix.
    ///
    /// `None` only when the codes do not describe the declared shape, which
    /// means no such matrix exists. There is nothing else to validate: the
    /// codec's table is already `Alphabet<E, Bd>`, so its image is in the
    /// alphabet by construction (§6.3).
    ///
    /// `CK-06`: the codec's own decoded lengths must sum to the declared row
    /// width, on every row. It is the *codec* that says how long a code is, so
    /// a variable-length tier needs no special case here and no separate matrix
    /// type --- which is what makes run coding a tier rather than a second
    /// algorithm (S5b).
    pub fn new(codec: C, rows: usize, cols: usize, codes: &'a [C::Code]) -> Option<Self> {
        if C::MAX_BLOCK == 0 {
            return None;
        }
        // A fixed-width tier's shape is arithmetic, so checking it is too.
        if C::IS_FIXED_WIDTH {
            if !cols.is_multiple_of(C::MAX_BLOCK) {
                return None;
            }
            let per_row = cols / C::MAX_BLOCK;
            if rows.checked_mul(per_row)? != codes.len() {
                return None;
            }
            return Some(Self {
                codec,
                rows,
                cols,
                codes,
                _marker: core::marker::PhantomData,
            });
        }
        let mut at = 0usize;
        for _ in 0..rows {
            let mut width = 0usize;
            while width < cols {
                let code = *codes.get(at)?;
                let n = codec.decode_len(code);
                if n == 0 {
                    // A code that produces nothing would make the walk
                    // non-terminating; no such matrix exists.
                    return None;
                }
                width = width.checked_add(n)?;
                at = at.checked_add(1)?;
            }
            if width != cols {
                // The last code of the row overshot it: the codes describe a
                // different shape from the declared one.
                return None;
            }
        }
        if at != codes.len() {
            return None;
        }
        Some(Self {
            codec,
            rows,
            cols,
            codes,
            _marker: core::marker::PhantomData,
        })
    }

    /// Rows.
    pub const fn rows(&self) -> usize {
        self.rows
    }

    /// Decoded elements per row.
    pub const fn cols(&self) -> usize {
        self.cols
    }

    /// The codec.
    pub const fn codec(&self) -> &C {
        &self.codec
    }

    /// Codes per row, for a fixed-width tier.
    ///
    /// A variable-length tier has no such constant; use
    /// [`CodedMatrix::row_code_range`], which walks the codec's own lengths.
    pub const fn codes_per_row(&self) -> usize {
        self.cols / C::MAX_BLOCK
    }

    /// The half-open range of codes belonging to row `r`.
    ///
    /// Arithmetic for a fixed-width tier, which is every tier but a run codec.
    /// That matters more than it looks: a walk would make random access
    /// O(row length), and a driver reading one element at a time would then run
    /// in O(k^2 n) instead of O(m k n).
    pub fn row_code_range(&self, r: usize) -> Range<usize> {
        if C::IS_FIXED_WIDTH {
            let per_row = self.codes_per_row();
            return r * per_row..(r + 1) * per_row;
        }
        // Walk the rows before `r` to find where it starts, then walk `r`
        // itself to find where it ends. `new` already established that the
        // lengths sum to `cols` on every row, so neither walk can run off.
        let mut start = 0usize;
        for _ in 0..r {
            let mut width = 0usize;
            while width < self.cols {
                width += self.codec.decode_len(self.codes[start]);
                start += 1;
            }
        }
        let mut end = start;
        let mut width = 0usize;
        while width < self.cols {
            width += self.codec.decode_len(self.codes[end]);
            end += 1;
        }
        start..end
    }

    /// The raw code slice.
    pub const fn codes(&self) -> &'a [C::Code] {
        self.codes
    }

    /// Decode row `r`. `out.len() >= cols`. The caller owns the buffer.
    ///
    /// Returns how many elements were written, which `CodedMatrix::new`
    /// established is exactly `cols` (`CK-06`).
    pub fn decode_row_into(&self, r: usize, out: &mut [Alphabet<E, Bd>]) -> usize {
        let range = self.row_code_range(r);
        self.codec.decode_seq(&self.codes[range], out)
    }

    /// Streaming decode, for a caller whose buffer is smaller than one row.
    ///
    /// This is what makes the library usable on a microcontroller whose RAM
    /// cannot hold a decoded row, and it is what makes the zero-scratch
    /// traversal possible (S13).
    pub fn decode_range_into(&self, r: usize, cols: Range<usize>, out: &mut [Alphabet<E, Bd>]) {
        for (slot, col) in out.iter_mut().zip(cols) {
            *slot = self.at(r, col);
        }
    }

    /// The element at `(r, c)` of the decoded matrix.
    ///
    /// O(1) for a fixed-width tier. For a variable-length one it walks the row,
    /// because the run boundaries are the data; a caller reading a whole row
    /// from such a tier should use [`CodedMatrix::decode_row_into`], which walks
    /// it once instead of once per element.
    pub fn at(&self, r: usize, c: usize) -> Alphabet<E, Bd> {
        if C::IS_FIXED_WIDTH {
            let block = C::MAX_BLOCK;
            let code = self.codes[r * self.codes_per_row() + c / block];
            return self.codec.decode_element(code, c % block);
        }
        let range = self.row_code_range(r);
        let mut width = 0usize;
        for &code in &self.codes[range] {
            let n = self.codec.decode_len(code);
            if c < width + n {
                return self.codec.decode_element(code, c - width);
            }
            width += n;
        }
        Alphabet::ZERO
    }
}
