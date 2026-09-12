//! x86-64: AVX2 for every integer family, and AVX-512 VNNI for `i8` (§7.2).

use core::arch::x86_64::*;

use uor_matmul_core::Backend;

use crate::spec::{Factorization, KernelSpec, LaneLayout};

crate::tile_fits!(6, 16);
crate::tile_fits!(1, 16);
crate::tile_fits!(1, 8);
crate::tile_fits!(1, 16);
crate::tile_fits!(1, 8);
crate::tile_fits!(4, 8);
crate::tile_fits!(8, 16);

/// Is AVX2 available?
pub fn avx2_available() -> bool {
    #[cfg(any(feature = "std", test))]
    {
        std::arch::is_x86_feature_detected!("avx2")
    }
    #[cfg(not(any(feature = "std", test)))]
    {
        // Without `std` there is nothing to detect, so the answer is whatever
        // the target features said at compile time (C1).
        cfg!(target_feature = "avx2")
    }
}

/// Is AVX-512 with VNNI available?
pub fn avx512vnni_available() -> bool {
    #[cfg(any(feature = "std", test))]
    {
        std::arch::is_x86_feature_detected!("avx512f")
            && std::arch::is_x86_feature_detected!("avx512bw")
            && std::arch::is_x86_feature_detected!("avx512vnni")
    }
    #[cfg(not(any(feature = "std", test)))]
    {
        cfg!(target_feature = "avx512vnni")
    }
}

// ---------------------------------------------------------------------------
// i8 x i8 -> i32
// ---------------------------------------------------------------------------

const A2_I8_MR: usize = 6;
const A2_I8_NR: usize = 16;

/// AVX2 `i8`: widen with `cvtepi8_epi16`, then `madd` a pair of `k`-steps into
/// an `i32` lane.
///
/// `madd` on i8-derived i16 peaks at `2 * 128 * 128 = 32768`, far inside `i32`,
/// so the pairing costs nothing in reach: the lane fills at the same depth the
/// plain `i32` tile does.
pub const AVX2_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: A2_I8_MR,
    nr: A2_I8_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    // `madd`'s pair sum is `2 * bound^2`; an `i8` alphabet cannot reach the
    // bound where that leaves an `i32`, so this is stated rather than binding.
    max_bound: 32767,
    mac_tile: avx2_i8,
};

/// # Safety
///
/// `pa` must have `6 * kc` readable elements, `pb` `16 * kc`, `acc` 96 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i8_inner::<A2_I8_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i8`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i8_inner<const MR: usize>(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    const NR: usize = A2_I8_NR;
    // SAFETY: the caller guaranteed the three extents. One conversion here
    // keeps every panel read below safe, so the only remaining `unsafe` is the
    // vector loads and stores, which is where it belongs.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    // The panel is packed in `k`-pairs, so the two bytes `madd` multiplies and
    // sums are already adjacent in memory for both operands. `B`'s 32 bytes for
    // this pair widen straight into the two `i16` vectors `madd` consumes, in
    // column order, so there is no interleave to do and no permutation to undo.
    let mut lo = [_mm256_setzero_si256(); MR];
    let mut hi = [_mm256_setzero_si256(); MR];

    for q in 0..kc / 2 {
        // SAFETY: `pb[q * NR * 2 ..][..32]` is in bounds; each is one 128-bit
        // load widened to sixteen `i16`, and lane `j` holds the pair
        // `(b[p0][j], b[p1][j])`, which is what `madd` sums.
        let (bv_lo, bv_hi) = unsafe {
            let base = pb.as_ptr().add(q * NR * 2);
            (
                _mm256_cvtepi8_epi16(_mm_loadu_si128(base.cast::<__m128i>())),
                _mm256_cvtepi8_epi16(_mm_loadu_si128(base.add(16).cast::<__m128i>())),
            )
        };

        for i in 0..MR {
            // Broadcasting the *pair* as a word and sign-extending it gives
            // `(a1 << 16) | a0` in every 32-bit lane: two instructions, against
            // the two loads, two shifts and an or it takes to build that value
            // out of a `k`-major panel.
            //
            // SAFETY: `q * MR * 2 + i * 2 + 1 < MR * kc`, and `read_unaligned`
            // waives the alignment `i16` would otherwise require.
            let av = unsafe {
                let pair = pa.as_ptr().add(q * MR * 2 + i * 2).cast::<i16>();
                _mm256_cvtepi8_epi16(_mm_set1_epi16(pair.read_unaligned()))
            };
            // Exact: `|a0*b0 + a1*b1| <= 2 * 128 * 128`, far inside `i32`.
            lo[i] = _mm256_add_epi32(lo[i], _mm256_madd_epi16(av, bv_lo));
            hi[i] = _mm256_add_epi32(hi[i], _mm256_madd_epi16(av, bv_hi));
        }
    }

    for i in 0..MR {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), lo[i]);
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR + 8).cast::<__m256i>(), hi[i]);
        }
    }
}

/// The same sequence over an eight-column panel: one accumulator vector per row
/// rather than two.
///
/// Written out beside [`avx2_i8_inner`] rather than folded into it behind a
/// width parameter. That was tried: an accumulator array indexed by a width
/// parameter costs the sixteen-column panel its register allocation, and
/// measured it took `n = 2048` from 31.3 Gmac/s to 24.9. Two panel widths are
/// two sequences, which is what the table is a table of --- and `CB-01` .. `CB-06`
/// hold both to the same integer.
///
/// # Safety
///
/// As [`avx2_i8`], with an eight-column panel: `pb` must have `8 * kc` readable
/// elements and `acc` `MR * 8` writable lanes.
#[target_feature(enable = "avx2")]
unsafe fn avx2_i8_half_inner<const MR: usize>(
    kc: usize,
    pa: *const i8,
    pb: *const i8,
    acc: *mut i32,
) {
    const NR: usize = 8;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    let mut lo = [_mm256_setzero_si256(); MR];

    for q in 0..kc / 2 {
        // SAFETY: `pb[q * NR * 2 ..][..16]` is in bounds.
        let bv = unsafe {
            let base = pb.as_ptr().add(q * NR * 2);
            _mm256_cvtepi8_epi16(_mm_loadu_si128(base.cast::<__m128i>()))
        };
        for (i, lo) in lo.iter_mut().enumerate() {
            // SAFETY: `q * MR * 2 + i * 2 + 1 < MR * kc`.
            let av = unsafe {
                let pair = pa.as_ptr().add(q * MR * 2 + i * 2).cast::<i16>();
                _mm256_cvtepi8_epi16(_mm_set1_epi16(pair.read_unaligned()))
            };
            *lo = _mm256_add_epi32(*lo, _mm256_madd_epi16(av, bv));
        }
    }

    for (i, lo) in lo.iter().enumerate() {
        // SAFETY: `i < MR`, so the store lands inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), *lo);
        }
    }
}

// ---------------------------------------------------------------------------
// i16 x i16 -> i64
// ---------------------------------------------------------------------------

const A2_I16_MR: usize = 4;
const A2_I16_NR: usize = 8;

/// AVX2 `i16` on an alphabet bounded by `32767`: `madd` is exactly this
/// family's arithmetic.
///
/// `_mm256_madd_epi16` multiplies signed words and sums adjacent pairs into an
/// `i32`. That pair sum is `2 * bound^2`, so the sequence is exact exactly while
/// `bound <= 32767` --- and *not* at the full `i16` alphabet, where two products
/// of `i16::MIN * i16::MIN` reach `2^31` and the intermediate wraps. Widening
/// the result to `i64` afterwards cannot undo that; the overflow has already
/// happened inside the instruction.
///
/// So this sequence declares its alphabet, and [`AVX2_I16_I64_FULL`] is the one
/// that runs at the full one. Both are exact on what they declare, which is what
/// makes them two factorizations rather than a fast one and a safe one.
pub const AVX2_I16_I64: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: A2_I16_MR,
    nr: A2_I16_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i64::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_i16,
};

/// # Safety
///
/// `pa` must have `4 * kc` readable elements, `pb` `8 * kc`, `acc` 32 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i16(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_inner::<A2_I16_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i16`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i16_inner<const MR: usize>(
    kc: usize,
    pa: *const i16,
    pb: *const i16,
    acc: *mut i64,
) {
    const NR: usize = A2_I16_NR;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    // Two `__m256i` of four i64 lanes each cover the eight columns.
    let mut tile = [[_mm256_setzero_si256(); 2]; MR];

    for q in 0..kc / 2 {
        // The panel is packed in `k`-pairs, so lane `j` of this load already
        // holds `(b[p0][j], b[p1][j])` --- the pair `madd` sums.
        //
        // SAFETY: `pb[q * NR * 2 ..][..16]` is in bounds: one 256-bit load.
        let bv = unsafe { _mm256_loadu_si256(pb.as_ptr().add(q * NR * 2).cast::<__m256i>()) };

        for (i, row) in tile.iter_mut().enumerate() {
            // The two `i16` of `A`'s pair are adjacent, so the broadcast is one
            // unaligned dword load.
            //
            // SAFETY: `q * MR * 2 + i * 2 + 1 < MR * kc`, and `read_unaligned`
            // waives the alignment `i32` would otherwise require.
            let av = unsafe {
                let pair = pa.as_ptr().add(q * MR * 2 + i * 2).cast::<i32>();
                _mm256_set1_epi32(pair.read_unaligned())
            };
            // Eight i32 pair-sums, each exact and at most 2^31.
            let m = _mm256_madd_epi16(av, bv);
            // Widen to i64 before accumulating, so no depth can fill the lane.
            row[0] = _mm256_add_epi64(row[0], _mm256_cvtepi32_epi64(_mm256_castsi256_si128(m)));
            row[1] = _mm256_add_epi64(
                row[1],
                _mm256_cvtepi32_epi64(_mm256_extracti128_si256(m, 1)),
            );
        }
    }

    for (i, row) in tile.iter().enumerate() {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), row[0]);
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR + 4).cast::<__m256i>(), row[1]);
        }
    }
}

/// AVX2 `i16` at the full alphabet: widen, then multiply at the product's own
/// width.
///
/// `_mm256_cvtepi16_epi32` widens eight columns and `_mm256_mullo_epi32`
/// multiplies them, and an `i16 x i16` product needs 31 bits --- so every
/// product is exact for every `i16`, including `i16::MIN * i16::MIN`. The
/// products are then widened to `i64` and accumulated, so no depth fills the
/// lane either.
///
/// It issues more instructions per product than [`AVX2_I16_I64`], and it is not
/// a safe fallback for it: at the full alphabet the paired sequence computes a
/// different number, so there is no choice being made between speed and
/// correctness. There are two alphabets and one sequence for each.
pub const AVX2_I16_I64_FULL: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: A2_I16_MR,
    nr: A2_I16_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 8,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_i16_full,
};

/// # Safety
///
/// `pa` must have `4 * kc` readable elements, `pb` `8 * kc`, `acc` 32 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i16_full(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_full_inner::<A2_I16_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i16_full`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i16_full_inner<const MR: usize>(
    kc: usize,
    pa: *const i16,
    pb: *const i16,
    acc: *mut i64,
) {
    const NR: usize = A2_I16_NR;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    let mut tile = [[_mm256_setzero_si256(); 2]; MR];

    for p in 0..kc {
        // SAFETY: `pb[p * NR ..][..8]` is in bounds: one 128-bit load widened to
        // eight `i32`.
        let bv = unsafe {
            _mm256_cvtepi16_epi32(_mm_loadu_si128(pb.as_ptr().add(p * NR).cast::<__m128i>()))
        };
        for (i, row) in tile.iter_mut().enumerate() {
            let av = _mm256_set1_epi32(i32::from(pa[p * MR + i]));
            // Exact: `|a * b| <= 2^30`, inside `i32`, for every pair of `i16`.
            let m = _mm256_mullo_epi32(av, bv);
            row[0] = _mm256_add_epi64(row[0], _mm256_cvtepi32_epi64(_mm256_castsi256_si128(m)));
            row[1] = _mm256_add_epi64(
                row[1],
                _mm256_cvtepi32_epi64(_mm256_extracti128_si256(m, 1)),
            );
        }
    }

    for (i, row) in tile.iter().enumerate() {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), row[0]);
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR + 4).cast::<__m256i>(), row[1]);
        }
    }
}

// ---------------------------------------------------------------------------
// i32 x i32 -> i64, exact
// ---------------------------------------------------------------------------

const A2_I32_MR: usize = 4;
const A2_I32_NR: usize = 8;

/// AVX2 `i32`, exact: `_mm256_mul_epi32` is a signed `32x32 -> 64` multiply,
/// which is this family's whole arithmetic in one instruction.
///
/// It multiplies the *even* 32-bit lanes, so the odd ones are reached by
/// shifting both operands down 32 bits --- two multiplies for eight products,
/// which is the arrangement AVX2 offers.
pub const AVX2_I32_I64: KernelSpec<i32, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: A2_I32_MR,
    nr: A2_I32_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 4,
    lane_cap: i64::MAX as u128,
    // Each product is computed at its own full width, so every alphabet.
    max_bound: u128::MAX,
    mac_tile: avx2_i32_exact,
};

/// # Safety
///
/// `pa` must have `4 * kc` readable elements, `pb` `8 * kc`, `acc` 32 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i32_exact(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i32_exact_inner::<A2_I32_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i32_exact`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i32_exact_inner<const MR: usize>(
    kc: usize,
    pa: *const i32,
    pb: *const i32,
    acc: *mut i64,
) {
    const NR: usize = A2_I32_NR;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    // `even[i]` holds columns 0, 2, 4, 6 and `odd[i]` holds 1, 3, 5, 7, which
    // is the lane order `mul_epi32` produces. They are interleaved back on the
    // way out rather than on every step.
    let mut even = [_mm256_setzero_si256(); MR];
    let mut odd = [_mm256_setzero_si256(); MR];

    for p in 0..kc {
        // SAFETY: `pb[p * NR ..][..8]` is in bounds, and this is one 256-bit
        // load of eight i32.
        let bv = unsafe { _mm256_loadu_si256(pb.as_ptr().add(p * NR).cast::<__m256i>()) };
        let bv_odd = _mm256_srli_epi64(bv, 32);
        for i in 0..MR {
            let av = _mm256_set1_epi32(pa[p * MR + i]);
            let av_odd = _mm256_srli_epi64(av, 32);
            // Exact: each product needs at most 62 bits and lands in an i64.
            even[i] = _mm256_add_epi64(even[i], _mm256_mul_epi32(av, bv));
            odd[i] = _mm256_add_epi64(odd[i], _mm256_mul_epi32(av_odd, bv_odd));
        }
    }

    for i in 0..MR {
        let mut e = [0i64; 4];
        let mut o = [0i64; 4];
        // SAFETY: both destinations hold exactly four i64.
        unsafe {
            _mm256_storeu_si256(e.as_mut_ptr().cast::<__m256i>(), even[i]);
            _mm256_storeu_si256(o.as_mut_ptr().cast::<__m256i>(), odd[i]);
        }
        for c in 0..4 {
            acc[i * NR + c * 2] = e[c];
            acc[i * NR + c * 2 + 1] = o[c];
        }
    }
}

// ---------------------------------------------------------------------------
// i32 x i32 -> i32, modular
// ---------------------------------------------------------------------------

/// AVX2 `i32` in `Z/2^32`: `_mm256_mullo_epi32` gives the low half of eight
/// products at once, which is the whole of the arithmetic in the quotient.
///
/// Eight products per instruction against the exact kernel's four, and no
/// widening, because in `Z/2^32` there is nothing to widen *to*. This is what
/// the caller gets for asking to encode by wrapping.
pub const AVX2_I32_MOD: KernelSpec<i32, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 6,
    nr: 16,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 8,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_i32_mod,
};

/// # Safety
///
/// `pa` must have `6 * kc` readable elements, `pb` `16 * kc`, `acc` 96 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i32_mod(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i32_mod_inner::<6>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i32_mod`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i32_mod_inner<const MR: usize>(
    kc: usize,
    pa: *const i32,
    pb: *const i32,
    acc: *mut i32,
) {
    const NR: usize = 16;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    let mut tile = [[_mm256_setzero_si256(); 2]; MR];

    for p in 0..kc {
        // SAFETY: `pb[p * NR ..][..16]` is in bounds: two 256-bit loads.
        let (bv0, bv1) = unsafe {
            (
                _mm256_loadu_si256(pb.as_ptr().add(p * NR).cast::<__m256i>()),
                _mm256_loadu_si256(pb.as_ptr().add(p * NR + 8).cast::<__m256i>()),
            )
        };
        for (i, row) in tile.iter_mut().enumerate() {
            let av = _mm256_set1_epi32(pa[p * MR + i]);
            // `mullo` keeps the low 32 bits, and the add wraps. Both are the
            // ring operations of `Z/2^32`, so the lane holds the exact value
            // the caller asked to encode into.
            row[0] = _mm256_add_epi32(row[0], _mm256_mullo_epi32(av, bv0));
            row[1] = _mm256_add_epi32(row[1], _mm256_mullo_epi32(av, bv1));
        }
    }

    for (i, row) in tile.iter().enumerate() {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), row[0]);
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR + 8).cast::<__m256i>(), row[1]);
        }
    }
}

// ---------------------------------------------------------------------------
// i16 x i16 -> i32, modular
// ---------------------------------------------------------------------------

/// AVX2 `i16` in `Z/2^32`: `madd` lands in `i32` and stays there.
///
/// Twice the columns of the exact `i16` kernel per instruction, because in the
/// quotient there is nothing to widen to. This is what the caller gets for
/// asking to encode by wrapping.
pub const AVX2_I16_MOD: KernelSpec<i16, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 6,
    nr: 16,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: 0,
    // `madd` wraps, and in `Z/2^32` the wrap *is* the answer --- so the pair
    // sum overflowing an `i32` is not an error here, it is the ring's addition.
    max_bound: u128::MAX,
    mac_tile: avx2_i16_mod,
};

/// # Safety
///
/// `pa` must have `6 * kc` readable elements, `pb` `16 * kc`, `acc` 96 writable
/// lanes, and the host must have `avx2`.
unsafe fn avx2_i16_mod(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_mod_inner::<6>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i16_mod`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_i16_mod_inner<const MR: usize>(
    kc: usize,
    pa: *const i16,
    pb: *const i16,
    acc: *mut i32,
) {
    const NR: usize = 16;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, NR * kc),
            core::slice::from_raw_parts_mut(acc, MR * NR),
        )
    };
    let mut tile = [[_mm256_setzero_si256(); 2]; MR];

    for q in 0..kc / 2 {
        // The panel is packed in `k`-pairs, so lane `j` already holds the pair
        // `madd` sums.
        //
        // SAFETY: `pb[q * NR * 2 ..][..32]` is in bounds: two 256-bit loads.
        let (bv0, bv1) = unsafe {
            let base = pb.as_ptr().add(q * NR * 2);
            (
                _mm256_loadu_si256(base.cast::<__m256i>()),
                _mm256_loadu_si256(base.add(16).cast::<__m256i>()),
            )
        };
        for (i, row) in tile.iter_mut().enumerate() {
            // SAFETY: `q * MR * 2 + i * 2 + 1 < MR * kc`, and `read_unaligned`
            // waives the alignment `i32` would otherwise require.
            let av = unsafe {
                let pair = pa.as_ptr().add(q * MR * 2 + i * 2).cast::<i32>();
                _mm256_set1_epi32(pair.read_unaligned())
            };
            // `madd` and the add both wrap, and both are the ring operations of
            // `Z/2^32`, so the lane holds the value the caller asked to encode.
            row[0] = _mm256_add_epi32(row[0], _mm256_madd_epi16(av, bv0));
            row[1] = _mm256_add_epi32(row[1], _mm256_madd_epi16(av, bv1));
        }
    }

    for (i, row) in tile.iter().enumerate() {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR).cast::<__m256i>(), row[0]);
            _mm256_storeu_si256(acc.as_mut_ptr().add(i * NR + 8).cast::<__m256i>(), row[1]);
        }
    }
}

// ---------------------------------------------------------------------------
// AVX-512 VNNI, i8 x i8 -> i32
// ---------------------------------------------------------------------------

const V_MR: usize = 8;
const V_NR: usize = 16;

/// The signed-word VNNI sequence. Reaches further per lane than the offset one
/// and needs no compensation term.
pub const AVX512_DPWSSD_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx512Vnni,
    factorization: Factorization::Exact,
    mr: V_MR,
    nr: V_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 32,
    lane_cap: i32::MAX as u128,
    // `dpwssd` accumulates pair sums into the `i32` lane itself, so the depth
    // bound above is the whole of the question: `lane_cap / bound^2` keeps the
    // running total inside the lane, and there is no separate intermediate.
    max_bound: u128::MAX,
    mac_tile: vnni_dpwssd,
};

/// The offset VNNI sequence: four bytes per lane instead of two.
///
/// `vpdpbusd` multiplies **unsigned** bytes by signed bytes, so reaching it
/// from `i8 x i8` needs the offset identity
///
/// ```text
/// sum(a_i8 * b) = sum((a_i8 + 128) * b) - 128 * sum(b)
/// ```
///
/// with `sum(b)` accumulated per column. Both terms are exact integers, so the
/// result is still the exact accumulation. The *intermediates* are not free:
/// the offset term reaches `255 * 128` per step against `dpwssd`'s `128 * 128`,
/// so it fills its lane sooner --- a threshold on a register rather than on an
/// answer, which is why `lane_cap` says so and the driver simply chunks more.
pub const AVX512_DPBUSD_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx512Vnni,
    factorization: Factorization::Exact,
    mr: V_MR,
    nr: V_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 4,
    products_per_step: 64,
    lane_cap: (i32::MAX as u128) / 255 * 128,
    max_bound: u128::MAX,
    mac_tile: vnni_dpbusd,
};

/// # Safety
///
/// `pa` must have `8 * kc` readable elements, `pb` `16 * kc`, `acc` 128
/// writable lanes, and the host must have `avx512f`, `avx512bw`, `avx512vnni`.
unsafe fn vnni_dpwssd(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the target features and the lengths.
    unsafe { dpwssd_inner(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`vnni_dpwssd`].
#[target_feature(enable = "avx512f,avx512bw,avx512vnni")]
unsafe fn dpwssd_inner(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, V_MR * kc),
            core::slice::from_raw_parts(pb, V_NR * kc),
            core::slice::from_raw_parts_mut(acc, V_MR * V_NR),
        )
    };
    let mut tile = [_mm512_setzero_si512(); V_MR];

    for q in 0..kc / 2 {
        // The panel is packed in `k`-pairs, so `B`'s 32 bytes for this pair
        // widen straight into the 32 `i16` `dpwssd` consumes, in column order.
        //
        // SAFETY: `pb[q * V_NR * 2 ..][..32]` is in bounds: one 256-bit load,
        // widened to 512 bits of `i16`.
        let bv = unsafe {
            _mm512_cvtepi8_epi16(_mm256_loadu_si256(
                pb.as_ptr().add(q * V_NR * 2).cast::<__m256i>(),
            ))
        };
        for (i, lane) in tile.iter_mut().enumerate() {
            // Broadcasting the pair as a word and sign-extending it puts
            // `(a1 << 16) | a0` in every 32-bit lane.
            //
            // SAFETY: `q * V_MR * 2 + i * 2 + 1 < V_MR * kc`, and
            // `read_unaligned` waives `i16`'s alignment.
            let av = unsafe {
                let pair = pa.as_ptr().add(q * V_MR * 2 + i * 2).cast::<i16>();
                _mm512_cvtepi8_epi16(_mm256_set1_epi16(pair.read_unaligned()))
            };
            *lane = _mm512_dpwssd_epi32(*lane, av, bv);
        }
    }

    // SAFETY: `acc` has `V_MR * V_NR` lanes.
    unsafe { vnni_store(acc, &tile) };
}

/// # Safety
///
/// As [`vnni_dpwssd`].
unsafe fn vnni_dpbusd(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the target features and the lengths.
    unsafe { dpbusd_inner(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`vnni_dpwssd`].
#[target_feature(enable = "avx512f,avx512bw,avx512vnni")]
unsafe fn dpbusd_inner(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    const G: usize = 4;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, V_MR * kc),
            core::slice::from_raw_parts(pb, V_NR * kc),
            core::slice::from_raw_parts_mut(acc, V_MR * V_NR),
        )
    };
    let mut tile = [_mm512_setzero_si512(); V_MR];
    // The offset identity's compensation term, `sum(b)` per column. Accumulated
    // with `dpbusd` against an all-ones unsigned vector, which is the same
    // instruction the products use and reads the same packed bytes.
    let mut colsum = _mm512_setzero_si512();
    let ones = _mm512_set1_epi32(0x0101_0101);

    for q in 0..kc / G {
        // The panel is packed in `k`-quads, so `B`'s 64 bytes for this quad are
        // exactly the `dpbusd` operand: column-major, `k` within a column.
        //
        // SAFETY: `pb[q * V_NR * G ..][..64]` is in bounds: one 512-bit load.
        let bv = unsafe { _mm512_loadu_si512(pb.as_ptr().add(q * V_NR * G).cast()) };
        colsum = _mm512_dpbusd_epi32(colsum, ones, bv);
        for (i, lane) in tile.iter_mut().enumerate() {
            // `a + 128` is exactly `a as u8` with its top bit flipped, so the
            // identity costs one xor over the whole quad.
            //
            // SAFETY: `q * V_MR * G + i * G + 3 < V_MR * kc`, and
            // `read_unaligned` waives `u32`'s alignment.
            let quad = unsafe {
                pa.as_ptr()
                    .add(q * V_MR * G + i * G)
                    .cast::<u32>()
                    .read_unaligned()
            };
            let av = _mm512_set1_epi32((quad ^ 0x8080_8080) as i32);
            *lane = _mm512_dpbusd_epi32(*lane, av, bv);
        }
    }

    // The compensation. Both terms are exact integers, so the total is still
    // the exact accumulation.
    let scaled = _mm512_mullo_epi32(colsum, _mm512_set1_epi32(128));
    for lane in tile.iter_mut() {
        *lane = _mm512_sub_epi32(*lane, scaled);
    }

    // SAFETY: `acc` has `V_MR * V_NR` lanes.
    unsafe { vnni_store(acc, &tile) };
}

/// # Safety
///
/// `acc` must have `V_MR * V_NR` writable lanes, and the host must have
/// `avx512f`.
#[target_feature(enable = "avx512f")]
unsafe fn vnni_store(acc: &mut [i32], tile: &[__m512i; V_MR]) {
    for (i, lane) in tile.iter().enumerate() {
        // SAFETY: `i < V_MR`, so this 512-bit store lands inside `MR * NR`.
        unsafe { _mm512_storeu_si512(acc.as_mut_ptr().add(i * V_NR).cast(), *lane) };
    }
}

// ---------------------------------------------------------------------------
// The reduce factorization: vector lanes on `k` rather than on the output
// ---------------------------------------------------------------------------

/// Four rows at a time, against one column.
///
/// Four is what fits: eight accumulator vectors for the widening families, plus
/// the column's two, plus the row being loaded, is within the sixteen `ymm`
/// registers. A wider `mr` would spill, and spilling costs more than the extra
/// reuse buys.
const R_MR: usize = 4;

crate::tile_fits!(R_MR, 1);
crate::tile_fits!(1, 1);

/// Sum the eight `i32` lanes of `v`.
///
/// Every partial sum is bounded by the sum of the lane magnitudes, which
/// `lane_cap` already keeps inside an `i32`, so the tree cannot overflow where
/// the total does not.
///
/// # Safety
///
/// The host must have `avx2`.
#[target_feature(enable = "avx2")]
#[inline]
unsafe fn hsum_epi32(v: __m256i) -> i32 {
    let s = _mm_add_epi32(_mm256_castsi256_si128(v), _mm256_extracti128_si256(v, 1));
    let s = _mm_add_epi32(s, _mm_shuffle_epi32(s, 0b0100_1110));
    let s = _mm_add_epi32(s, _mm_shuffle_epi32(s, 0b0001_0001));
    _mm_cvtsi128_si32(s)
}

/// Sum the four `i64` lanes of `v`.
///
/// # Safety
///
/// The host must have `avx2`.
#[target_feature(enable = "avx2")]
#[inline]
unsafe fn hsum_epi64(v: __m256i) -> i64 {
    let mut out = [0i64; 4];
    // SAFETY: `out` holds exactly four `i64`.
    unsafe { _mm256_storeu_si256(out.as_mut_ptr().cast::<__m256i>(), v) };
    // The lane sums are exact integers and the total is what `lane_cap` bounds,
    // so this is an ordinary `i64` addition, not a widening question.
    out[0]
        .wrapping_add(out[1])
        .wrapping_add(out[2])
        .wrapping_add(out[3])
}

/// AVX2 `i8`, reducing four rows against one column with the lanes on `k`.
///
/// Thirty-two `k`-steps per iteration: `B`'s run widens into two `i16` vectors
/// once and serves all four rows, and each row's run widens the same way. The
/// pair sum is `madd`'s, so the declared alphabet is the same `32767` as the tile
/// sequence's --- and an `i8` alphabet cannot reach it.
pub const AVX2_R_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 32,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_r_i8,
};

/// # Safety
///
/// `pa` must have `4 * kc` readable elements with row `i` at `pa[i * kc ..][..kc]`,
/// `pb` must have `kc`, `acc` 4 writable lanes, `kc` a multiple of 32, and the
/// host must have `avx2`.
unsafe fn avx2_r_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i8_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_r_i8`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_r_i8_inner<const MR: usize>(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [_mm256_setzero_si256(); MR];

    for q in 0..kc / 32 {
        // SAFETY: `pb[q * 32 ..][..32]` is in bounds: two 128-bit loads widened
        // to sixteen `i16` each.
        let (bl, bh) = unsafe {
            let base = pb.as_ptr().add(q * 32);
            (
                _mm256_cvtepi8_epi16(_mm_loadu_si128(base.cast::<__m128i>())),
                _mm256_cvtepi8_epi16(_mm_loadu_si128(base.add(16).cast::<__m128i>())),
            )
        };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 32 + 32 <= MR * kc`.
            let (al, ah) = unsafe {
                let base = pa.as_ptr().add(i * kc + q * 32);
                (
                    _mm256_cvtepi8_epi16(_mm_loadu_si128(base.cast::<__m128i>())),
                    _mm256_cvtepi8_epi16(_mm_loadu_si128(base.add(16).cast::<__m128i>())),
                )
            };
            *sum = _mm256_add_epi32(*sum, _mm256_madd_epi16(al, bl));
            *sum = _mm256_add_epi32(*sum, _mm256_madd_epi16(ah, bh));
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        // SAFETY: `avx2` is enabled on this function.
        acc[i] = unsafe { hsum_epi32(*sum) };
    }
}

/// AVX2 `i32` in `Z/2^32`, reducing four rows against one column.
///
/// `mullo` gives eight products per instruction and the adds wrap; both are the
/// ring operations of `Z/2^32`, so the lane holds the value the caller asked to
/// encode into, at every depth.
pub const AVX2_R_I32_MOD: KernelSpec<i32, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 8,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i32_mod,
};

/// # Safety
///
/// As [`avx2_r_i8`], with `kc` a multiple of 8.
unsafe fn avx2_r_i32_mod(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i32_mod_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_r_i32_mod`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_r_i32_mod_inner<const MR: usize>(
    kc: usize,
    pa: *const i32,
    pb: *const i32,
    acc: *mut i32,
) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [_mm256_setzero_si256(); MR];

    for q in 0..kc / 8 {
        // SAFETY: `pb[q * 8 ..][..8]` is in bounds: one 256-bit load.
        let bv = unsafe { _mm256_loadu_si256(pb.as_ptr().add(q * 8).cast::<__m256i>()) };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 8 + 8 <= MR * kc`.
            let av =
                unsafe { _mm256_loadu_si256(pa.as_ptr().add(i * kc + q * 8).cast::<__m256i>()) };
            *sum = _mm256_add_epi32(*sum, _mm256_mullo_epi32(av, bv));
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        // SAFETY: `avx2` is enabled on this function. The horizontal sum wraps,
        // which in `Z/2^32` is the addition.
        acc[i] = unsafe { hsum_epi32(*sum) };
    }
}

/// AVX2 `i16` in `Z/2^32`, reducing four rows against one column.
pub const AVX2_R_I16_MOD: KernelSpec<i16, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 16,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i16_mod,
};

/// # Safety
///
/// As [`avx2_r_i8`], with `kc` a multiple of 16.
unsafe fn avx2_r_i16_mod(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i16_mod_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_r_i16_mod`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_r_i16_mod_inner<const MR: usize>(
    kc: usize,
    pa: *const i16,
    pb: *const i16,
    acc: *mut i32,
) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [_mm256_setzero_si256(); MR];

    for q in 0..kc / 16 {
        // SAFETY: `pb[q * 16 ..][..16]` is in bounds: one 256-bit load.
        let bv = unsafe { _mm256_loadu_si256(pb.as_ptr().add(q * 16).cast::<__m256i>()) };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 16 + 16 <= MR * kc`.
            let av =
                unsafe { _mm256_loadu_si256(pa.as_ptr().add(i * kc + q * 16).cast::<__m256i>()) };
            // `madd` wraps and so does the add; in `Z/2^32` both are the ring's.
            *sum = _mm256_add_epi32(*sum, _mm256_madd_epi16(av, bv));
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        // SAFETY: `avx2` is enabled on this function.
        acc[i] = unsafe { hsum_epi32(*sum) };
    }
}

/// AVX2 `i16 -> i64`, exact at every `i16`, reducing four rows against one
/// column.
///
/// `madd`'s pair sum is not admissible here for the same reason it is not in the
/// tile kernel, so the products are widened first: `cvtepi16_epi32` then
/// `mullo_epi32`, each product exact in 31 bits, then widened to `i64`.
pub const AVX2_R_I16_I64: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 8,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i16,
};

/// # Safety
///
/// As [`avx2_r_i8`], with `kc` a multiple of 8.
unsafe fn avx2_r_i16(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i16_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_r_i16`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_r_i16_inner<const MR: usize>(
    kc: usize,
    pa: *const i16,
    pb: *const i16,
    acc: *mut i64,
) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [[_mm256_setzero_si256(); 2]; MR];

    for q in 0..kc / 8 {
        // SAFETY: `pb[q * 8 ..][..8]` is in bounds: one 128-bit load widened.
        let bv = unsafe {
            _mm256_cvtepi16_epi32(_mm_loadu_si128(pb.as_ptr().add(q * 8).cast::<__m128i>()))
        };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 8 + 8 <= MR * kc`.
            let av = unsafe {
                _mm256_cvtepi16_epi32(_mm_loadu_si128(
                    pa.as_ptr().add(i * kc + q * 8).cast::<__m128i>(),
                ))
            };
            let m = _mm256_mullo_epi32(av, bv);
            sum[0] = _mm256_add_epi64(sum[0], _mm256_cvtepi32_epi64(_mm256_castsi256_si128(m)));
            sum[1] = _mm256_add_epi64(
                sum[1],
                _mm256_cvtepi32_epi64(_mm256_extracti128_si256(m, 1)),
            );
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        // SAFETY: `avx2` is enabled on this function.
        acc[i] = unsafe { hsum_epi64(sum[0]).wrapping_add(hsum_epi64(sum[1])) };
    }
}

/// AVX2 `i32 -> i64`, exact, reducing four rows against one column.
///
/// `mul_epi32` multiplies the even 32-bit lanes into `i64`, so the odd ones are
/// reached by shifting both operands down 32 bits --- two multiplies for eight
/// products, which is the arrangement AVX2 offers.
pub const AVX2_R_I32_I64: KernelSpec<i32, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 4,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i32,
};

/// # Safety
///
/// As [`avx2_r_i8`], with `kc` a multiple of 8.
unsafe fn avx2_r_i32(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i32_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_r_i32`].
#[target_feature(enable = "avx2")]
unsafe fn avx2_r_i32_inner<const MR: usize>(
    kc: usize,
    pa: *const i32,
    pb: *const i32,
    acc: *mut i64,
) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [[_mm256_setzero_si256(); 2]; MR];

    for q in 0..kc / 8 {
        // SAFETY: `pb[q * 8 ..][..8]` is in bounds: one 256-bit load.
        let bv = unsafe { _mm256_loadu_si256(pb.as_ptr().add(q * 8).cast::<__m256i>()) };
        let bv_odd = _mm256_srli_epi64(bv, 32);
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 8 + 8 <= MR * kc`.
            let av =
                unsafe { _mm256_loadu_si256(pa.as_ptr().add(i * kc + q * 8).cast::<__m256i>()) };
            let av_odd = _mm256_srli_epi64(av, 32);
            // Exact: each product needs at most 62 bits and lands in an `i64`.
            sum[0] = _mm256_add_epi64(sum[0], _mm256_mul_epi32(av, bv));
            sum[1] = _mm256_add_epi64(sum[1], _mm256_mul_epi32(av_odd, bv_odd));
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        // SAFETY: `avx2` is enabled on this function.
        acc[i] = unsafe { hsum_epi64(sum[0]).wrapping_add(hsum_epi64(sum[1])) };
    }
}

/// The same sequence at a one-row panel.
///
/// A panel wider than the output is zero-padded, and for a reduce kernel that
/// padding is copied at `k` elements a row --- which for a single dot product is
/// the whole cost. So the table offers the widths the shapes need, and the driver
/// takes the widest panel the rows fill. Same instructions, same answer.
pub const AVX2_R_I8_I32_1: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 32,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_r_i8_one,
};

/// # Safety
///
/// As [`avx2_r_i8`], with a one-row panel.
unsafe fn avx2_r_i8_one(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i8_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A panel wider than the output is zero-padded, and for a reduce kernel that
/// padding is copied at `k` elements a row --- which for a single dot product is
/// the whole cost. So the table offers the widths the shapes need, and the driver
/// takes the widest panel the rows fill. Same instructions, same answer.
pub const AVX2_R_I32_MOD_1: KernelSpec<i32, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 8,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i32_mod_one,
};

/// # Safety
///
/// As [`avx2_r_i32_mod`], with a one-row panel.
unsafe fn avx2_r_i32_mod_one(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i32_mod_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A panel wider than the output is zero-padded, and for a reduce kernel that
/// padding is copied at `k` elements a row --- which for a single dot product is
/// the whole cost. So the table offers the widths the shapes need, and the driver
/// takes the widest panel the rows fill. Same instructions, same answer.
pub const AVX2_R_I16_MOD_1: KernelSpec<i16, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 16,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i16_mod_one,
};

/// # Safety
///
/// As [`avx2_r_i16_mod`], with a one-row panel.
unsafe fn avx2_r_i16_mod_one(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i16_mod_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A panel wider than the output is zero-padded, and for a reduce kernel that
/// padding is copied at `k` elements a row --- which for a single dot product is
/// the whole cost. So the table offers the widths the shapes need, and the driver
/// takes the widest panel the rows fill. Same instructions, same answer.
pub const AVX2_R_I16_I64_1: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 8,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i16_one,
};

/// # Safety
///
/// As [`avx2_r_i16`], with a one-row panel.
unsafe fn avx2_r_i16_one(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i16_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A panel wider than the output is zero-padded, and for a reduce kernel that
/// padding is copied at `k` elements a row --- which for a single dot product is
/// the whole cost. So the table offers the widths the shapes need, and the driver
/// takes the widest panel the rows fill. Same instructions, same answer.
pub const AVX2_R_I32_I64_1: KernelSpec<i32, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 8,
    products_per_step: 4,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_r_i32_one,
};

/// # Safety
///
/// As [`avx2_r_i32`], with a one-row panel.
unsafe fn avx2_r_i32_one(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_r_i32_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I8_I32_M1: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: A2_I8_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    // `madd`'s pair sum is `2 * bound^2`; an `i8` alphabet cannot reach the
    // bound where that leaves an `i32`, so this is stated rather than binding.
    max_bound: 32767,
    mac_tile: avx2_i8_one,
};

/// The same sequence at a half-width panel.
///
/// The mirror of [`AVX2_I8_I32_M1`], on the other axis and for the same reason:
/// a tile panel wider than the output is zero-padded, and the kernel does that
/// padding's arithmetic. At `n = 8` a sixteen-column panel is twice the work the
/// product needs --- measured, that made `i8` at `n = 8` slower than the same
/// kernel at `n = 16`, which is a padding artefact and not a property of the
/// shape. Same instructions, same answer (`CB-06`).
pub const AVX2_I8_I32_N8: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: A2_I8_MR,
    nr: 8,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_i8_half,
};

/// # Safety
///
/// As [`avx2_i8`], with an eight-column panel.
unsafe fn avx2_i8_half(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i8_half_inner::<A2_I8_MR>(kc, pa, pb, acc) }
}

/// [`AVX2_I8_I32_N8`] at a one-row panel: the corner both narrowings meet in.
pub const AVX2_I8_I32_M1_N8: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 8,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_i8_one_half,
};

/// # Safety
///
/// As [`avx2_i8`], with a one-row eight-column panel.
unsafe fn avx2_i8_one_half(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i8_half_inner::<1>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`avx2_i8`], with a one-row panel.
unsafe fn avx2_i8_one(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i8_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I16_I64_M1: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: A2_I16_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: i64::MAX as u128,
    max_bound: 32767,
    mac_tile: avx2_i16_one,
};

/// # Safety
///
/// As [`avx2_i16`], with a one-row panel.
unsafe fn avx2_i16_one(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I16_I64_FULL_M1: KernelSpec<i16, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: A2_I16_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 8,
    lane_cap: i64::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: avx2_i16_full_one,
};

/// # Safety
///
/// As [`avx2_i16_full`], with a one-row panel.
unsafe fn avx2_i16_full_one(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_full_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I32_I64_M1: KernelSpec<i32, i64> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Exact,
    mr: 1,
    nr: A2_I32_NR,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 4,
    lane_cap: i64::MAX as u128,
    // Each product is computed at its own full width, so every alphabet.
    max_bound: u128::MAX,
    mac_tile: avx2_i32_exact_one,
};

/// # Safety
///
/// As [`avx2_i32_exact`], with a one-row panel.
unsafe fn avx2_i32_exact_one(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i64) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i32_exact_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I32_MOD_M1: KernelSpec<i32, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 1,
    nr: 16,
    lane_layout: LaneLayout::Interleaved,
    k_group: 1,
    products_per_step: 8,
    lane_cap: 0,
    max_bound: u128::MAX,
    mac_tile: avx2_i32_mod_one,
};

/// # Safety
///
/// As [`avx2_i32_mod`], with a one-row panel.
unsafe fn avx2_i32_mod_one(kc: usize, pa: *const i32, pb: *const i32, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i32_mod_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel.
///
/// A tile panel taller than the output is zero-padded, and the kernel does that
/// padding's arithmetic: at `m = 1` a six-row panel is six times the work the
/// product needs. So the table offers the heights the shapes fill, and the
/// driver takes the tallest one the rows do. Same instructions, same answer
/// (`CB-06`).
pub const AVX2_I16_MOD_M1: KernelSpec<i16, i32> = KernelSpec {
    backend: Backend::Avx2,
    factorization: Factorization::Modular,
    mr: 1,
    nr: 16,
    lane_layout: LaneLayout::Interleaved,
    k_group: 2,
    products_per_step: 16,
    lane_cap: 0,
    // `madd` wraps, and in `Z/2^32` the wrap *is* the answer --- so the pair
    // sum overflowing an `i32` is not an error here, it is the ring's addition.
    max_bound: u128::MAX,
    mac_tile: avx2_i16_mod_one,
};

/// # Safety
///
/// As [`avx2_i16_mod`], with a one-row panel.
unsafe fn avx2_i16_mod_one(kc: usize, pa: *const i16, pb: *const i16, acc: *mut i32) {
    // SAFETY: the caller established `avx2` and forwarded the lengths.
    unsafe { avx2_i16_mod_inner::<1>(kc, pa, pb, acc) }
}
