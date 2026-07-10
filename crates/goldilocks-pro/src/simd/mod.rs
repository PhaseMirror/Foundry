pub mod avx512;
pub mod neon;

use crate::GoldilocksField;

/// SIMD Trait for vectorized Goldilocks arithmetic.
pub trait GoldilocksSimd {
    const LANES: usize;
    
    fn vec_add(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]);
    fn vec_sub(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]);
    fn vec_mul(a: &[GoldilocksField], b: &[GoldilocksField], out: &mut [GoldilocksField]);
}
