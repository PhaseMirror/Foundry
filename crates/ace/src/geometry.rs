//! Geometry FFI bindings – expose Lean-verified projective geometry mapping.

use super::CayleyDickson;

/// Convert a projective dimension k (binary projective space PG(k, F2))
/// to the corresponding Cayley-Dickson level.
///
/// The mapping matches the Lean proof:
///   0 -> Level0, 1 -> Level1, 2 -> Level2, 3 -> Level3, k >= 4 -> Higher(k).
pub const fn pg_dim_to_cd(k: u32) -> CayleyDickson {
    match k {
        0 => CayleyDickson::Level0,
        1 => CayleyDickson::Level1,
        2 => CayleyDickson::Level2,
        3 => CayleyDickson::Level3,
        n => CayleyDickson::Higher(n),
    }
}

// Exported compile-time constants for the first few dimensions.
pub const PG_DIM_0_CD: CayleyDickson = CayleyDickson::Level0;
pub const PG_DIM_1_CD: CayleyDickson = CayleyDickson::Level1;
pub const PG_DIM_2_CD: CayleyDickson = CayleyDickson::Level2;
pub const PG_DIM_3_CD: CayleyDickson = CayleyDickson::Level3;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pg_dim_to_cd_base_cases() {
        assert_eq!(pg_dim_to_cd(0), CayleyDickson::Level0);
        assert_eq!(pg_dim_to_cd(1), CayleyDickson::Level1);
        assert_eq!(pg_dim_to_cd(2), CayleyDickson::Level2);
        assert_eq!(pg_dim_to_cd(3), CayleyDickson::Level3);
        // Higher dimension check
        assert_eq!(pg_dim_to_cd(7), CayleyDickson::Higher(7));
    }
}
