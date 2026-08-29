//! 1-D Affine Toy Fixture & Contractivity/Expansiveness Analysis

pub struct ToyFixture;

impl ToyFixture {
    /// 1-D Affine test fixture: F_10(y, u) = 4y + u (Expansive, Lip = 4 on integers).
    pub fn f10(y: i64, u: i64) -> i64 {
        4 * y + u
    }

    /// Scaled operator: F(y, u) = F_10(y, u) / 10 = 0.4y + 0.1u (Contractive, Lip = 0.4 on rationals/floats).
    pub fn f_scaled(y: f64, u: f64) -> f64 {
        0.4 * y + 0.1 * u
    }

    /// Verify Lipschitz scaling on integers: |F_10(y, u) - F_10(y', u)| == 4 * |y - y'|.
    pub fn verify_f10_lipschitz(y: i64, y_prime: i64, u: i64) -> bool {
        let diff_out = (Self::f10(y, u) - Self::f10(y_prime, u)).abs();
        let diff_in = (y - y_prime).abs();
        diff_out == 4 * diff_in
    }

    /// Verify scaled Lipschitz bound on floats: |F(y, u) - F(y', u)| <= 0.4 * |y - y'| + 1e-9.
    pub fn verify_f_scaled_lipschitz(y: f64, y_prime: f64, u: f64) -> bool {
        let diff_out = (Self::f_scaled(y, u) - Self::f_scaled(y_prime, u)).abs();
        let diff_in = (y - y_prime).abs();
        diff_out <= 0.4 * diff_in + 1e-9
    }
}
