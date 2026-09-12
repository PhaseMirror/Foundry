//! The reference kernels (§7.2, row `Scalar`).
//!
//! The model transcribed: widen, multiply, add. No `unsafe` beyond the raw
//! reads the shared signature requires, runs under Miri, and never optimized
//! (R6).
//!
//! These are not fallbacks. Every other kernel in this crate is a factorization
//! of *these* accumulations into wider instructions, and `CB-01` pins the `i8`
//! one to [`uor_matmul_core::dot_ref`] so the whole chain is anchored to the
//! reference the plan names.

use uor_matmul_core::Backend;

use crate::spec::{Factorization, KernelSpec, LaneLayout};

/// Build one reference kernel: `mr x nr` of `E`, accumulating in `L`.
///
/// The body is the same three lines at every instantiation, which is the point:
/// the families differ in their widths and in nothing else.
macro_rules! reference_kernel {
    (
        $(#[$meta:meta])*
        $name:ident, $fnname:ident, $e:ty, $l:ty, $mr:expr, $nr:expr,
        $factorization:expr, $cap:expr, $mul:expr
    ) => {
        $crate::tile_fits!($mr, $nr);

        $(#[$meta])*
        pub const $name: KernelSpec<$e, $l> = KernelSpec {
            backend: Backend::Portable,
            factorization: $factorization,
            mr: $mr,
            nr: $nr,
            lane_layout: LaneLayout::Interleaved,
            // The reference needs no grouping at all, which is why it is the
            // one kernel that never has a tail.
            k_group: 1,
            // The reference is one product per step, which is what makes it the
            // baseline the traversal comparison is calibrated against.
            products_per_step: 1,
            lane_cap: $cap,
            // The reference multiplies in the lane's own width, so there is
            // no intermediate to outgrow and no alphabet it is inexact on.
            max_bound: u128::MAX,
            mac_tile: $fnname,
        };

        /// # Safety
        ///
        /// `pa` must have `mr * kc` readable elements, `pb` must have
        /// `nr * kc`, and `acc` must have `mr * nr` writable lanes.
        unsafe fn $fnname(kc: usize, pa: *const $e, pb: *const $e, acc: *mut $l) {
            // SAFETY: the caller guaranteed the three extents. Turning them
            // into slices once, here, is what lets the loop below be safe
            // indexing rather than three raw reads per product.
            let (pa, pb, acc) = unsafe {
                (
                    core::slice::from_raw_parts(pa, $mr * kc),
                    core::slice::from_raw_parts(pb, $nr * kc),
                    core::slice::from_raw_parts_mut(acc, $mr * $nr),
                )
            };
            let mut tile = [<$l>::default(); $mr * $nr];
            for p in 0..kc {
                for i in 0..$mr {
                    let a = pa[p * $mr + i];
                    for j in 0..$nr {
                        let m: $l = $mul(a, pb[p * $nr + j]);
                        // The driver only offers a chunk whose depth this
                        // lane admits, so the running sum stays inside it.
                        // Spelled `wrapping_add` because R5 asks the overflow
                        // behaviour to be written rather than inherited from
                        // the build profile --- and because for a modular lane
                        // the wrap is the answer.
                        tile[i * $nr + j] = tile[i * $nr + j].wrapping_add(m);
                    }
                }
            }
            acc.copy_from_slice(&tile);
        }
    };
}

reference_kernel!(
    /// `i8 x i8 -> i32`, exact. The reference `CB-01` pins to `dot_ref`.
    I8_I32, mac_i8_i32, i8, i32, 4, 4, Factorization::Exact, i32::MAX as u128,
    |a: i8, b: i8| i32::from(a) * i32::from(b)
);

reference_kernel!(
    /// `i16 x i16 -> i64`, exact.
    I16_I64, mac_i16_i64, i16, i64, 4, 4, Factorization::Exact, i64::MAX as u128,
    |a: i16, b: i16| i64::from(a) * i64::from(b)
);

reference_kernel!(
    /// `i32 x i32 -> i64`, exact. Two full-range products fill the lane, which
    /// is why a declared narrower bound buys so much here.
    I32_I64, mac_i32_i64, i32, i64, 4, 4, Factorization::Exact, i64::MAX as u128,
    |a: i32, b: i32| i64::from(a) * i64::from(b)
);

reference_kernel!(
    /// `i32 x i32 -> i32` in `Z/2^32`. Exact in the quotient the caller asked
    /// to encode into, and therefore unbounded in depth.
    I32_MOD, mac_i32_mod, i32, i32, 4, 4, Factorization::Modular, 0,
    |a: i32, b: i32| a.wrapping_mul(b)
);

reference_kernel!(
    /// `i64 x i64 -> i64` in `Z/2^64`. The only factorization there is for
    /// `i64`: an exact product needs 128 bits, and the quotient needs the low
    /// 64, which is what `wrapping_mul` gives.
    I64_MOD, mac_i64_mod, i64, i64, 4, 4, Factorization::Modular, 0,
    |a: i64, b: i64| a.wrapping_mul(b)
);

reference_kernel!(
    /// `i64 x i64 -> i128`, exact. The lane is the only width that holds the
    /// product, which is why no SIMD reaches it on any supported target.
    I64_I128, mac_i64_i128, i64, i128, 4, 4, Factorization::Exact, i128::MAX as u128,
    |a: i64, b: i64| i128::from(a) * i128::from(b)
);

reference_kernel!(
    /// `i16 x i16 -> i32` in `Z/2^32`.
    I16_MOD, mac_i16_mod, i16, i32, 4, 4, Factorization::Modular, 0,
    |a: i16, b: i16| i32::from(a).wrapping_mul(i32::from(b))
);

/// Build one reference *reduce* kernel: `mr` rows of `E` against one column,
/// accumulating in `L`.
///
/// The reduce factorization is the one to use when the output is narrower than a
/// tile: its lanes are steps of the reduction rather than columns of `C`, and
/// there is always more `k` to fill them with. The reference has no lanes at all,
/// so it is the same three lines again --- what it establishes is the *answer*
/// the vector reduce kernels are compared against (`CB-06`).
macro_rules! reduce_reference {
    (
        $(#[$meta:meta])*
        $name:ident, $fnname:ident, $e:ty, $l:ty, $mr:expr,
        $factorization:expr, $cap:expr, $mul:expr
    ) => {
        $crate::tile_fits!($mr, 1);

        $(#[$meta])*
        pub const $name: KernelSpec<$e, $l> = KernelSpec {
            backend: Backend::Portable,
            factorization: $factorization,
            mr: $mr,
            nr: 1,
            lane_layout: LaneLayout::Contiguous,
            k_group: 1,
            // The reference is one product per step, which is what makes it the
            // baseline the traversal comparison is calibrated against.
            products_per_step: 1,
            lane_cap: $cap,
            max_bound: u128::MAX,
            mac_tile: $fnname,
        };

        /// # Safety
        ///
        /// `pa` must have `mr * kc` readable elements with row `i` at
        /// `pa[i * kc ..][..kc]`, `pb` must have `kc`, and `acc` must have `mr`
        /// writable lanes.
        unsafe fn $fnname(kc: usize, pa: *const $e, pb: *const $e, acc: *mut $l) {
            // SAFETY: the caller guaranteed the three extents.
            let (pa, pb, acc) = unsafe {
                (
                    core::slice::from_raw_parts(pa, $mr * kc),
                    core::slice::from_raw_parts(pb, kc),
                    core::slice::from_raw_parts_mut(acc, $mr),
                )
            };
            for i in 0..$mr {
                let row = &pa[i * kc..][..kc];
                let mut sum = <$l>::default();
                for p in 0..kc {
                    // R5: the overflow behaviour is written rather than
                    // inherited from the build profile, and for a modular lane
                    // the wrap is the answer.
                    sum = sum.wrapping_add($mul(row[p], pb[p]));
                }
                acc[i] = sum;
            }
        }
    };
}

reduce_reference!(
    /// `i8 x i8 -> i32`, exact, reducing four rows at a time.
    R_I8_I32, red_i8_i32, i8, i32, 4, Factorization::Exact, i32::MAX as u128,
    |a: i8, b: i8| i32::from(a) * i32::from(b)
);

reduce_reference!(
    /// `i16 x i16 -> i64`, exact.
    R_I16_I64, red_i16_i64, i16, i64, 4, Factorization::Exact, i64::MAX as u128,
    |a: i16, b: i16| i64::from(a) * i64::from(b)
);

reduce_reference!(
    /// `i16 x i16 -> i32` in `Z/2^32`.
    R_I16_MOD, red_i16_mod, i16, i32, 4, Factorization::Modular, 0,
    |a: i16, b: i16| i32::from(a).wrapping_mul(i32::from(b))
);

reduce_reference!(
    /// `i32 x i32 -> i64`, exact.
    R_I32_I64, red_i32_i64, i32, i64, 4, Factorization::Exact, i64::MAX as u128,
    |a: i32, b: i32| i64::from(a) * i64::from(b)
);

reduce_reference!(
    /// `i32 x i32 -> i32` in `Z/2^32`.
    R_I32_MOD, red_i32_mod, i32, i32, 4, Factorization::Modular, 0,
    |a: i32, b: i32| a.wrapping_mul(b)
);

reduce_reference!(
    /// `i64 x i64 -> i128`, exact.
    R_I64_I128, red_i64_i128, i64, i128, 4, Factorization::Exact, i128::MAX as u128,
    |a: i64, b: i64| i128::from(a) * i128::from(b)
);

reduce_reference!(
    /// `i64 x i64 -> i64` in `Z/2^64`.
    R_I64_MOD, red_i64_mod, i64, i64, 4, Factorization::Modular, 0,
    |a: i64, b: i64| a.wrapping_mul(b)
);

// One-row panels. See `AVX2_R_I8_I32_1`: a panel wider than the output is
// zero-padded, and for a reduce kernel that padding is copied at `k` elements a
// row. The table offers the widths the shapes need.

reduce_reference!(
    /// `i8 x i8 -> i32`, exact, one row.
    R1_I8_I32, red1_i8_i32, i8, i32, 1, Factorization::Exact, i32::MAX as u128,
    |a: i8, b: i8| i32::from(a) * i32::from(b)
);

reduce_reference!(
    /// `i16 x i16 -> i64`, exact, one row.
    R1_I16_I64, red1_i16_i64, i16, i64, 1, Factorization::Exact, i64::MAX as u128,
    |a: i16, b: i16| i64::from(a) * i64::from(b)
);

reduce_reference!(
    /// `i16 x i16 -> i32` in `Z/2^32`, one row.
    R1_I16_MOD, red1_i16_mod, i16, i32, 1, Factorization::Modular, 0,
    |a: i16, b: i16| i32::from(a).wrapping_mul(i32::from(b))
);

reduce_reference!(
    /// `i32 x i32 -> i64`, exact, one row.
    R1_I32_I64, red1_i32_i64, i32, i64, 1, Factorization::Exact, i64::MAX as u128,
    |a: i32, b: i32| i64::from(a) * i64::from(b)
);

reduce_reference!(
    /// `i32 x i32 -> i32` in `Z/2^32`, one row.
    R1_I32_MOD, red1_i32_mod, i32, i32, 1, Factorization::Modular, 0,
    |a: i32, b: i32| a.wrapping_mul(b)
);

reduce_reference!(
    /// `i64 x i64 -> i128`, exact, one row.
    R1_I64_I128, red1_i64_i128, i64, i128, 1, Factorization::Exact, i128::MAX as u128,
    |a: i64, b: i64| i128::from(a) * i128::from(b)
);

reduce_reference!(
    /// `i64 x i64 -> i64` in `Z/2^64`, one row.
    R1_I64_MOD, red1_i64_mod, i64, i64, 1, Factorization::Modular, 0,
    |a: i64, b: i64| a.wrapping_mul(b)
);
