//! The AArch64 kernels, on a target that is not AArch64. See
//! [`crate::isa::x86`]'s absent twin for why the constants still resolve.

use crate::isa::portable;
use crate::spec::KernelSpec;

/// Is NEON available? Never, on a target that is not AArch64.
pub fn neon_available() -> bool {
    false
}

/// Is the dot-product extension available? Never, on a target that is not
/// AArch64.
pub fn dotprod_available() -> bool {
    false
}

/// Unreachable: [`neon_available`] is `false`.
pub const NEON_I8_I32: KernelSpec<i8, i32> = portable::I8_I32;
/// Unreachable: [`dotprod_available`] is `false`.
pub const NEON_DOTPROD_I8_I32: KernelSpec<i8, i32> = portable::I8_I32;

/// Absent here; the reference reduce sequence carries this family.
pub const NEON_R_I8_I32: KernelSpec<i8, i32> = portable::R_I8_I32;
/// Absent here; the reference reduce sequence carries this family.
pub const NEON_DOTPROD_R_I8_I32: KernelSpec<i8, i32> = portable::R_I8_I32;

/// Absent here; the reference reduce sequence carries this family.
pub const NEON_R_I8_I32_1: KernelSpec<i8, i32> = portable::R1_I8_I32;
/// Absent here; the reference reduce sequence carries this family.
pub const NEON_DOTPROD_R_I8_I32_1: KernelSpec<i8, i32> = portable::R1_I8_I32;
