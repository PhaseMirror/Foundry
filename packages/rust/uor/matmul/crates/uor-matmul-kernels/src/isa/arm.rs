//! AArch64 NEON, with and without the dot-product extension (§7.2).

use core::arch::aarch64::*;

use uor_matmul_core::Backend;

use crate::spec::{Factorization, KernelSpec, LaneLayout};

crate::tile_fits!(4, 8);
crate::tile_fits!(8, 12);

/// Is NEON available? Mandatory on AArch64, so always.
pub fn neon_available() -> bool {
    true
}

/// Is the ARMv8.2-A dot-product extension available?
pub fn dotprod_available() -> bool {
    #[cfg(any(feature = "std", test))]
    {
        std::arch::is_aarch64_feature_detected!("dotprod")
    }
    #[cfg(not(any(feature = "std", test)))]
    {
        cfg!(target_feature = "dotprod")
    }
}

/// `i8 x i8 -> i32` through `vmull_s8`.
///
/// `vmull_s8` gives eight `i8 x i8` products as `i16`. Each is at most
/// `128 * 128 = 16384`, which fits --- but *two* do not (`3 * 127^2 = 48387 >
/// i16::MAX`), so the products are widened to `i32` immediately rather than
/// accumulated in `i16`. That is not a precaution against a rare case: it is
/// the difference between an exact kernel and one that silently saturates (R3).
pub const NEON_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Neon,
    factorization: Factorization::Exact,
    mr: 4,
    nr: 8,
    lane_layout: LaneLayout::Interleaved,
    // `vmull_s8` widens across the *columns* of one `k`-step, not across `k`, so
    // this kernel consumes one step at a time and wants the plain `k`-major
    // panel. Its eight is the vector's width in columns, which is `nr`.
    k_group: 1,
    products_per_step: 8,
    lane_cap: i32::MAX as u128,
    // `vmull_s8` widens each product to `i16` and this kernel widens again to
    // `i32` before accumulating, so nothing narrower than the lane is held.
    max_bound: u128::MAX,
    mac_tile: neon_i8,
};

/// `i8 x i8 -> i32` through `sdot`.
///
/// Four `k`-steps per lane in one instruction, accumulating straight into
/// `i32`, so there is no intermediate width to overflow and no compensation
/// term. The widest reach of any sequence in this crate.
pub const NEON_DOTPROD_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::NeonDotprod,
    factorization: Factorization::Exact,
    mr: 8,
    nr: 12,
    lane_layout: LaneLayout::Interleaved,
    k_group: 4,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: neon_dotprod_i8,
};

const NEON_MR: usize = 4;
const NEON_NR: usize = 8;

/// # Safety
///
/// `pa` must have `4 * kc` readable elements, `pb` `8 * kc`, `acc` 32 writable
/// lanes.
unsafe fn neon_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller forwarded the length guarantees, and NEON is
    // unconditionally present on this target.
    unsafe { neon_i8_inner(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`neon_i8`].
#[target_feature(enable = "neon")]
unsafe fn neon_i8_inner(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, NEON_MR * kc),
            core::slice::from_raw_parts(pb, NEON_NR * kc),
            core::slice::from_raw_parts_mut(acc, NEON_MR * NEON_NR),
        )
    };
    let mut lo = [vdupq_n_s32(0); NEON_MR];
    let mut hi = [vdupq_n_s32(0); NEON_MR];

    for p in 0..kc {
        // SAFETY: `pb[p * NR ..][..8]` is in bounds.
        let bv = unsafe { vld1_s8(pb[p * NEON_NR..].as_ptr()) };
        for i in 0..NEON_MR {
            let prod = vmull_s8(vdup_n_s8(pa[p * NEON_MR + i]), bv);
            lo[i] = vaddq_s32(lo[i], vmovl_s16(vget_low_s16(prod)));
            hi[i] = vaddq_s32(hi[i], vmovl_s16(vget_high_s16(prod)));
        }
    }
    for i in 0..NEON_MR {
        // SAFETY: `i < MR`, so these two stores land inside `MR * NR`.
        unsafe {
            vst1q_s32(acc.as_mut_ptr().add(i * NEON_NR), lo[i]);
            vst1q_s32(acc.as_mut_ptr().add(i * NEON_NR + 4), hi[i]);
        }
    }
}

const DOT_MR: usize = 8;
const DOT_NR: usize = 12;

/// `sdot Vd.4S, Vn.16B, Vm.16B`.
///
/// Inline assembly because `vdotq_s32` is still unstable in `core::arch`. The
/// instruction is the one the intrinsic emits, and reaching it through `asm!`
/// rather than a nightly feature keeps the crate on the pinned stable
/// toolchain --- which matters more than the spelling, because a backend that
/// cannot be built cannot be validated.
///
/// # Safety
///
/// The host must have the `dotprod` extension.
#[target_feature(enable = "neon,dotprod")]
#[inline]
unsafe fn sdot(acc: int32x4_t, a: int8x16_t, b: int8x16_t) -> int32x4_t {
    let mut out = acc;
    // SAFETY: `sdot` reads two vector registers and accumulates into a third.
    // It touches no memory, sets no flags, and its result depends only on its
    // inputs, which is what the options below declare.
    unsafe {
        core::arch::asm!(
            "sdot {out:v}.4s, {a:v}.16b, {b:v}.16b",
            out = inout(vreg) out,
            a = in(vreg) a,
            b = in(vreg) b,
            options(pure, nomem, nostack, preserves_flags),
        );
    }
    out
}

/// # Safety
///
/// As [`neon_i8`], with `8 * kc`, `12 * kc`, 96 lanes, and the host must have
/// `dotprod`.
unsafe fn neon_dotprod_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the lengths, and `available_i8` established
    // the `dotprod` feature before returning this spec.
    unsafe { neon_dotprod_inner(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`neon_dotprod_i8`].
#[target_feature(enable = "neon,dotprod")]
unsafe fn neon_dotprod_inner(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    const QUADS: usize = DOT_NR / 4;
    const G: usize = 4;
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, DOT_MR * kc),
            core::slice::from_raw_parts(pb, DOT_NR * kc),
            core::slice::from_raw_parts_mut(acc, DOT_MR * DOT_NR),
        )
    };
    let mut tile = [[vdupq_n_s32(0); QUADS]; DOT_MR];

    for q in 0..kc / G {
        // The panel is packed in `k`-quads, so lane `4c + g` of a sixteen-byte
        // load already holds `b[4q + g][4 * quad + c]`, which is exactly the
        // layout `sdot` reads --- no transpose, one load per quad of columns.
        let bv: [int8x16_t; QUADS] = core::array::from_fn(|quad| {
            // SAFETY: `q * DOT_NR * G + quad * 16 + 16 <= DOT_NR * kc`.
            unsafe { vld1q_s8(pb.as_ptr().add(q * DOT_NR * G + quad * 16)) }
        });

        for (i, row) in tile.iter_mut().enumerate() {
            // `A`'s four `k`-steps for this row are four contiguous bytes.
            //
            // SAFETY: `q * DOT_MR * G + i * G + 3 < DOT_MR * kc`, and
            // `read_unaligned` waives `i32`'s alignment.
            let quad = unsafe {
                pa.as_ptr()
                    .add(q * DOT_MR * G + i * G)
                    .cast::<i32>()
                    .read_unaligned()
            };
            let av = vreinterpretq_s8_s32(vdupq_n_s32(quad));
            for (quad, lane) in row.iter_mut().enumerate() {
                // SAFETY: `dotprod` is enabled on this function.
                *lane = unsafe { sdot(*lane, av, bv[quad]) };
            }
        }
    }

    for (i, row) in tile.iter().enumerate() {
        for (quad, lane) in row.iter().enumerate() {
            // SAFETY: `i < MR` and `quad * 4 + 4 <= NR`, inside `MR * NR`.
            unsafe { vst1q_s32(acc.as_mut_ptr().add(i * DOT_NR + quad * 4), *lane) };
        }
    }
}

// ---------------------------------------------------------------------------
// The reduce factorization: vector lanes on `k` rather than on the output
// ---------------------------------------------------------------------------

const R_MR: usize = 4;

crate::tile_fits!(R_MR, 1);
crate::tile_fits!(1, 1);

/// NEON `i8`, reducing four rows against one column with the lanes on `k`.
///
/// Sixteen `k`-steps per iteration. `vmull_s8` widens eight products to `i16` and
/// they are widened again to `i32` before accumulating, so nothing narrower than
/// the lane is held and the sequence is exact at every `i8`.
pub const NEON_R_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Neon,
    factorization: Factorization::Exact,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 8,
    lane_cap: i32::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: neon_r_i8,
};

/// # Safety
///
/// `pa` must have `4 * kc` readable elements with row `i` at `pa[i * kc ..][..kc]`,
/// `pb` must have `kc`, `acc` 4 writable lanes, and `kc` a multiple of 16.
unsafe fn neon_r_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller forwarded the lengths, and NEON is unconditionally
    // present on this target.
    unsafe { neon_r_i8_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`neon_r_i8`].
#[target_feature(enable = "neon")]
unsafe fn neon_r_i8_inner<const MR: usize>(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller guaranteed the three extents.
    let (pa, pb, acc) = unsafe {
        (
            core::slice::from_raw_parts(pa, MR * kc),
            core::slice::from_raw_parts(pb, kc),
            core::slice::from_raw_parts_mut(acc, MR),
        )
    };
    let mut sums = [vdupq_n_s32(0); MR];

    for q in 0..kc / 16 {
        // SAFETY: `pb[q * 16 ..][..16]` is in bounds: two eight-byte loads.
        let (bl, bh) = unsafe {
            let base = pb.as_ptr().add(q * 16);
            (vld1_s8(base), vld1_s8(base.add(8)))
        };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 16 + 16 <= MR * kc`.
            let (al, ah) = unsafe {
                let base = pa.as_ptr().add(i * kc + q * 16);
                (vld1_s8(base), vld1_s8(base.add(8)))
            };
            for (av, bv) in [(al, bl), (ah, bh)] {
                let prod = vmull_s8(av, bv);
                *sum = vaddq_s32(*sum, vmovl_s16(vget_low_s16(prod)));
                *sum = vaddq_s32(*sum, vmovl_s16(vget_high_s16(prod)));
            }
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        acc[i] = vaddvq_s32(*sum);
    }
}

/// NEON `i8` through `sdot`, reducing four rows against one column.
///
/// `sdot` accumulates four `i8` products straight into an `i32` lane, so there is
/// no intermediate width at all: sixteen `k`-steps per instruction per row.
pub const NEON_DOTPROD_R_I8_I32: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::NeonDotprod,
    factorization: Factorization::Exact,
    mr: R_MR,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: neon_dotprod_r_i8,
};

/// # Safety
///
/// As [`neon_r_i8`], and the host must have `dotprod`.
unsafe fn neon_dotprod_r_i8(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the lengths, and `available_reduce_i8`
    // established the `dotprod` feature before returning this spec.
    unsafe { neon_dotprod_r_i8_inner::<R_MR>(kc, pa, pb, acc) }
}

/// # Safety
///
/// As [`neon_dotprod_r_i8`].
#[target_feature(enable = "neon,dotprod")]
unsafe fn neon_dotprod_r_i8_inner<const MR: usize>(
    kc: usize,
    pa: *const i8,
    pb: *const i8,
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
    let mut sums = [vdupq_n_s32(0); MR];

    for q in 0..kc / 16 {
        // SAFETY: `pb[q * 16 ..][..16]` is in bounds: one sixteen-byte load.
        let bv = unsafe { vld1q_s8(pb.as_ptr().add(q * 16)) };
        for (i, sum) in sums.iter_mut().enumerate() {
            // SAFETY: `i * kc + q * 16 + 16 <= MR * kc`.
            let av = unsafe { vld1q_s8(pa.as_ptr().add(i * kc + q * 16)) };
            // SAFETY: `dotprod` is enabled on this function.
            *sum = unsafe { sdot(*sum, av, bv) };
        }
    }

    for (i, sum) in sums.iter().enumerate() {
        acc[i] = vaddvq_s32(*sum);
    }
}

/// The same sequence at a one-row panel. See [`NEON_R_I8_I32`].
pub const NEON_R_I8_I32_1: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::Neon,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 8,
    lane_cap: i32::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: neon_r_i8_one,
};

/// # Safety
///
/// As [`neon_r_i8`], with a one-row panel.
unsafe fn neon_r_i8_one(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the lengths and the target features.
    unsafe { neon_r_i8_inner::<1>(kc, pa, pb, acc) }
}

/// The same sequence at a one-row panel. See [`NEON_DOTPROD_R_I8_I32`].
pub const NEON_DOTPROD_R_I8_I32_1: KernelSpec<i8, i32> = KernelSpec {
    backend: Backend::NeonDotprod,
    factorization: Factorization::Exact,
    mr: 1,
    nr: 1,
    lane_layout: LaneLayout::Contiguous,
    k_group: 16,
    products_per_step: 16,
    lane_cap: i32::MAX as u128,
    max_bound: u128::MAX,
    mac_tile: neon_dotprod_r_i8_one,
};

/// # Safety
///
/// As [`neon_dotprod_r_i8`], with a one-row panel.
unsafe fn neon_dotprod_r_i8_one(kc: usize, pa: *const i8, pb: *const i8, acc: *mut i32) {
    // SAFETY: the caller established the lengths and the target features.
    unsafe { neon_dotprod_r_i8_inner::<1>(kc, pa, pb, acc) }
}
