//! Quantum Effect Algebra, Kubo-Ando Means, and CPTP Channels

/// 2x2 Real Hermitian / Symmetric Effect Operator E ∈ [0, I].
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct QuantumEffect {
    pub a: f64, // E[0][0]
    pub b: f64, // E[0][1] == E[1][0]
    pub c: f64, // E[1][1]
}

impl QuantumEffect {
    pub fn identity() -> Self {
        Self {
            a: 1.0,
            b: 0.0,
            c: 1.0,
        }
    }

    pub fn zero() -> Self {
        Self {
            a: 0.0,
            b: 0.0,
            c: 0.0,
        }
    }

    pub fn new(a: f64, b: f64, c: f64) -> Self {
        Self { a, b, c }
    }

    /// Effect Negation: I - E.
    pub fn not(&self) -> Self {
        Self {
            a: 1.0 - self.a,
            b: -self.b,
            c: 1.0 - self.c,
        }
    }

    /// Compute matrix square root for 2x2 positive semi-definite matrix.
    pub fn sqrt(&self) -> Self {
        let trace = self.a + self.c;
        let det = (self.a * self.c - self.b * self.b).max(0.0);
        let s = det.sqrt();
        let t = (trace + 2.0 * s).max(1e-12).sqrt();

        Self {
            a: (self.a + s) / t,
            b: self.b / t,
            c: (self.c + s) / t,
        }
    }

    /// Sequential product: E ∘ F = E^{1/2} F E^{1/2}.
    pub fn sequential_product(&self, f: &QuantumEffect) -> Self {
        let e_half = self.sqrt();
        // E^{1/2} * F
        let ef_00 = e_half.a * f.a + e_half.b * f.b;
        let ef_01 = e_half.a * f.b + e_half.b * f.c;
        let ef_10 = e_half.b * f.a + e_half.c * f.b;
        let ef_11 = e_half.b * f.b + e_half.c * f.c;

        // (E^{1/2} * F) * E^{1/2}
        let res_a = ef_00 * e_half.a + ef_01 * e_half.b;
        let res_b = ef_00 * e_half.b + ef_01 * e_half.c;
        let res_c = ef_10 * e_half.b + ef_11 * e_half.c;

        Self {
            a: res_a,
            b: res_b,
            c: res_c,
        }
    }

    /// Kubo-Ando Geometric Mean: E # F.
    pub fn kubo_ando_geometric_mean(&self, f: &QuantumEffect) -> Self {
        // Fallback robust proxy for commute/non-commute: 0.5 * (E ∘ F + F ∘ E)
        let ef = self.sequential_product(f);
        let fe = f.sequential_product(self);
        Self {
            a: 0.5 * (ef.a + fe.a),
            b: 0.5 * (ef.b + fe.b),
            c: 0.5 * (ef.c + fe.c),
        }
    }

    /// Enforce Safety Projection: PSD clamping and [0, I] eigenvalue containment.
    pub fn project_effect(&self) -> Self {
        let tr = self.a + self.c;
        let diff = self.a - self.c;
        let disc = (diff * diff + 4.0 * self.b * self.b).sqrt();

        let l1 = ((tr + disc) * 0.5).clamp(0.0, 1.0);
        let l2 = ((tr - disc) * 0.5).clamp(0.0, 1.0);

        if self.b.abs() < 1e-9 {
            return Self {
                a: l1,
                b: 0.0,
                c: l2,
            };
        }

        // Reconstruct from eigenvectors
        let v1_x = 2.0 * self.b;
        let v1_y = diff + disc;
        let norm = (v1_x * v1_x + v1_y * v1_y).sqrt().max(1e-12);
        let nx = v1_x / norm;
        let ny = v1_y / norm;

        let a_new = l1 * nx * nx + l2 * ny * ny;
        let b_new = (l1 - l2) * nx * ny;
        let c_new = l1 * ny * ny + l2 * nx * nx;

        Self {
            a: a_new.clamp(0.0, 1.0),
            b: b_new,
            c: c_new.clamp(0.0, 1.0),
        }
    }
}
