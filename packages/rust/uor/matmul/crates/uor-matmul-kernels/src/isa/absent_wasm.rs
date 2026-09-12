//! The WebAssembly kernels, on a target that is not wasm32. See
//! [`crate::isa::x86`]'s absent twin for why the constant still resolves.

use crate::isa::portable;
use crate::spec::KernelSpec;

/// Is SIMD128 available? Never, on a target that is not wasm32.
pub fn simd128_available() -> bool {
    false
}

/// Unreachable: [`simd128_available`] is `false`.
pub const SIMD128_I8_I32: KernelSpec<i8, i32> = portable::I8_I32;

/// Absent here; the reference reduce sequence carries this family.
pub const SIMD128_R_I8_I32: KernelSpec<i8, i32> = portable::R_I8_I32;

/// Absent here; the reference reduce sequence carries this family.
pub const SIMD128_R_I8_I32_1: KernelSpec<i8, i32> = portable::R1_I8_I32;
