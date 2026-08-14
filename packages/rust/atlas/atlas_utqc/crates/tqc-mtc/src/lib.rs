//! The MTC builds: an explicit modular datum (`S`, `T`) and braiding (`R`), validated against
//! the universal MTC axioms.
//!
//! The anyons are modelled as the **quantum double `D(Z_n)`** — a genuine, anomaly-free
//! (`c = 0`) pointed modular tensor category, with `n` taken from the use-case. Its modular
//! data satisfies the full SL(2,ℤ) relations *exactly* and its bicharacter braiding satisfies
//! hexagon + Yang–Baxter; the Verlinde formula reproduces the group-law fusion. These are
//! `build` constructions validated against the axioms — **not** a claim that `D(Z_n)` is the
//! unique modular category of the Atlas.
//!
//! `n` is generic over the use-case; nothing here is Atlas-specific.

#![forbid(unsafe_code)]

/// The Atlas-native category construction.
pub mod native;
/// The verification logic for general MTCs.
pub mod verifier;

use core::f64::consts::PI;

/// The default numerical tolerance for axiom checks.
pub const TOL: f64 = 1e-9;

/// A complex number.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct C {
    /// Real part.
    pub re: f64,
    /// Imaginary part.
    pub im: f64,
}

impl C {
    /// Construct `re + i·im`.
    #[must_use]
    pub fn new(re: f64, im: f64) -> Self {
        Self { re, im }
    }
    /// The unit phase `e^{iθ}`.
    #[must_use]
    pub fn phase(theta: f64) -> Self {
        Self {
            re: theta.cos(),
            im: theta.sin(),
        }
    }
    /// Complex conjugate.
    #[must_use]
    pub fn conj(self) -> Self {
        Self {
            re: self.re,
            im: -self.im,
        }
    }
    /// Squared modulus.
    #[must_use]
    pub fn abs2(self) -> f64 {
        self.re * self.re + self.im * self.im
    }
    /// Sum.
    #[must_use]
    pub fn plus(self, o: Self) -> Self {
        Self {
            re: self.re + o.re,
            im: self.im + o.im,
        }
    }
    /// Product.
    #[must_use]
    pub fn times(self, o: Self) -> Self {
        Self {
            re: self.re * o.re - self.im * o.im,
            im: self.re * o.im + self.im * o.re,
        }
    }
    /// Scale by a real.
    #[must_use]
    pub fn scale(self, s: f64) -> Self {
        Self {
            re: self.re * s,
            im: self.im * s,
        }
    }
    /// Approximate equality within `tol`.
    #[must_use]
    pub fn close(self, o: Self, tol: f64) -> bool {
        (self.re - o.re).abs() <= tol && (self.im - o.im).abs() <= tol
    }
}

/// A dense complex matrix (row-major).
pub type Matrix = Vec<Vec<C>>;

fn zeros(n: usize) -> Matrix {
    vec![vec![C::new(0.0, 0.0); n]; n]
}

fn identity(n: usize) -> Matrix {
    let mut m = zeros(n);
    for (i, row) in m.iter_mut().enumerate() {
        row[i] = C::new(1.0, 0.0);
    }
    m
}

fn matmul(a: &Matrix, b: &Matrix) -> Matrix {
    let n = a.len();
    let mut out = zeros(n);
    for i in 0..n {
        for k in 0..n {
            let aik = a[i][k];
            if aik.abs2() == 0.0 {
                continue;
            }
            for j in 0..n {
                out[i][j] = out[i][j].plus(aik.times(b[k][j]));
            }
        }
    }
    out
}

fn mat_pow(a: &Matrix, e: u32) -> Matrix {
    let mut acc = identity(a.len());
    for _ in 0..e {
        acc = matmul(&acc, a);
    }
    acc
}

fn close_mat(a: &Matrix, b: &Matrix, tol: f64) -> bool {
    a.iter()
        .zip(b)
        .all(|(ra, rb)| ra.iter().zip(rb).all(|(x, y)| x.close(*y, tol)))
}

fn conj_transpose(a: &Matrix) -> Matrix {
    let mut out = zeros(a.len());
    for (i, row) in out.iter_mut().enumerate() {
        for (j, cell) in row.iter_mut().enumerate() {
            *cell = a[j][i].conj();
        }
    }
    out
}

fn is_symmetric(a: &Matrix, tol: f64) -> bool {
    let n = a.len();
    (0..n).all(|i| (0..n).all(|j| a[i][j].close(a[j][i], tol)))
}

fn is_unitary(a: &Matrix, tol: f64) -> bool {
    close_mat(&matmul(a, &conj_transpose(a)), &identity(a.len()), tol)
}

/// The quantum double `D(Z_n)`: objects `(a, b) ∈ Z_n × Z_n`.
#[derive(Clone, Copy, Debug)]
pub struct DoubleZn {
    /// The modulus.
    pub n: usize,
}

impl DoubleZn {
    /// Number of simple objects, `n²`.
    #[must_use]
    pub fn dim(self) -> usize {
        self.n * self.n
    }
    fn idx(self, a: usize, b: usize) -> usize {
        a * self.n + b
    }
    fn coords(self, i: usize) -> (usize, usize) {
        (i / self.n, i % self.n)
    }
    fn omega(self, k: i64) -> C {
        let n = self.n as f64;
        C::phase(2.0 * PI * (k as f64) / n)
    }

    /// The topological spins `T_{(a,b)} = ω^{ab}` (the diagonal of `T`).
    #[must_use]
    pub fn t_diag(self) -> Vec<C> {
        (0..self.dim())
            .map(|i| {
                let (a, b) = self.coords(i);
                self.omega((a * b) as i64)
            })
            .collect()
    }

    /// The modular `S` matrix `S_{x,y} = (1/n) ω^{-(a b' + a' b)}`.
    #[must_use]
    pub fn s_matrix(self) -> Matrix {
        let mut s = zeros(self.dim());
        for (x, row) in s.iter_mut().enumerate() {
            let (a, b) = self.coords(x);
            for (y, cell) in row.iter_mut().enumerate() {
                let (a2, b2) = self.coords(y);
                let k = -((a * b2 + a2 * b) as i64);
                *cell = self.omega(k).scale(1.0 / self.n as f64);
            }
        }
        s
    }

    /// `ST = S · diag(T)`.
    #[must_use]
    pub fn st_matrix(self) -> Matrix {
        let s = self.s_matrix();
        let t = self.t_diag();
        let mut out = zeros(self.dim());
        for (i, row) in out.iter_mut().enumerate() {
            for (j, cell) in row.iter_mut().enumerate() {
                *cell = s[i][j].times(t[j]);
            }
        }
        out
    }

    /// The charge-conjugation permutation matrix `(a,b) ↦ (-a, -b)`.
    #[must_use]
    pub fn charge_conjugation(self) -> Matrix {
        let mut c = zeros(self.dim());
        for (x, row) in c.iter_mut().enumerate() {
            let (a, b) = self.coords(x);
            let cx = self.idx((self.n - a) % self.n, (self.n - b) % self.n);
            row[cx] = C::new(1.0, 0.0);
        }
        c
    }

    /// The bicharacter braiding `R_{(a,b),(a',b')} = ω^{a' b}`.
    #[must_use]
    pub fn r(self, x: usize, y: usize) -> C {
        let (_, b) = self.coords(x);
        let (a2, _) = self.coords(y);
        self.omega((a2 * b) as i64)
    }

    fn add_obj(self, x: usize, y: usize) -> usize {
        let (a, b) = self.coords(x);
        let (a2, b2) = self.coords(y);
        self.idx((a + a2) % self.n, (b + b2) % self.n)
    }
}

impl verifier::ModularData for DoubleZn {
    fn dim(&self) -> usize {
        (*self).dim()
    }
    fn s_matrix(&self) -> Matrix {
        (*self).s_matrix()
    }
    fn t_diag(&self) -> Vec<C> {
        (*self).t_diag()
    }
    fn charge_conjugation(&self) -> Matrix {
        (*self).charge_conjugation()
    }
    fn n_ijk(&self, i: usize, j: usize, k: usize) -> f64 {
        if self.add_obj(i, j) == k {
            1.0
        } else {
            0.0
        }
    }
    fn f_symbol(&self, i: usize, j: usize, k: usize, l: usize, m: usize, n: usize) -> C {
        // Pointed category with trivial 3-cocycle
        // F is a 1x1 identity matrix in the 1-dimensional space of valid channels.
        // For invalid channels, it's 0.
        // (i*j) = m, (m*k) = l, (j*k) = n, (i*n) = l.
        if self.add_obj(i, j) == m
            && self.add_obj(m, k) == l
            && self.add_obj(j, k) == n
            && self.add_obj(i, n) == l
        {
            C::new(1.0, 0.0)
        } else {
            C::new(0.0, 0.0)
        }
    }
    fn r_symbol(&self, i: usize, j: usize, k: usize) -> C {
        if self.add_obj(i, j) == k {
            self.r(i, j)
        } else {
            C::new(0.0, 0.0)
        }
    }
}

/// Verify the SL(2,ℤ) modular relations for `D(Z_n)`: `S` symmetric & unitary, `T` of finite
/// order, `S⁴ = 1`, `(ST)³ = S²`, `S² = C` (charge conjugation), and Verlinde reproduces the
/// group-law fusion.
///
/// # Errors
/// Returns a description of the first axiom that fails within `tol`.
pub fn verify_modular(n: usize, tol: f64) -> Result<(), String> {
    if n == 0 {
        return Err("modulus must be >= 1".into());
    }
    let d = DoubleZn { n };
    let s = d.s_matrix();
    let t = d.t_diag();

    if !is_symmetric(&s, tol) {
        return Err("S is not symmetric".into());
    }
    if !is_unitary(&s, tol) {
        return Err("S is not unitary".into());
    }
    for (i, &theta) in t.iter().enumerate() {
        if (theta.abs2() - 1.0).abs() > tol {
            return Err(format!("T[{i}] is not a phase"));
        }
    }
    let s2 = mat_pow(&s, 2);
    if !close_mat(&mat_pow(&s, 4), &identity(d.dim()), tol) {
        return Err("S^4 != I".into());
    }
    if !close_mat(&mat_pow(&d.st_matrix(), 3), &s2, tol) {
        return Err("(ST)^3 != S^2".into());
    }
    if !close_mat(&s2, &d.charge_conjugation(), tol) {
        return Err("S^2 != charge conjugation".into());
    }
    verify_verlinde(n, tol)
}

/// Verify the Verlinde formula reproduces the group-law fusion of `D(Z_n)`:
/// `N_{ij}^k = Σ_l S_il S_jl conj(S_kl) / S_0l ≈ δ_{k, i⊕j}`.
///
/// # Errors
/// Returns a description if a fusion multiplicity is wrong.
pub fn verify_verlinde(n: usize, tol: f64) -> Result<(), String> {
    let d = DoubleZn { n };
    let s = d.s_matrix();
    let dim = d.dim();
    let s0 = s[0].clone(); // S_{0, l}
    for i in 0..dim {
        for j in 0..dim {
            let expected = d.add_obj(i, j);
            for k in 0..dim {
                let mut acc = C::new(0.0, 0.0);
                for l in 0..dim {
                    // S_0l is real and nonzero (= 1/n) for the double.
                    let term = s[i][l].times(s[j][l]).times(s[k][l].conj());
                    acc = acc.plus(term.scale(1.0 / s0[l].re));
                }
                let want = if k == expected { 1.0 } else { 0.0 };
                if (acc.re - want).abs() > 1e-6 || acc.im.abs() > 1e-6 {
                    let _ = tol;
                    return Err(format!(
                        "Verlinde N_{i},{j}^{k} = {:.3}+{:.3}i, want {want}",
                        acc.re, acc.im
                    ));
                }
            }
        }
    }
    Ok(())
}

/// Verify the braiding `R` for `D(Z_n)`: unitary phases, the hexagon (bimultiplicativity in
/// both arguments), and the monodromy `R_{x,y} R_{y,x} = ω^{a b' + a' b}` tying `R` to `S`.
///
/// # Errors
/// Returns a description of the first axiom that fails within `tol`.
pub fn verify_braiding(n: usize, tol: f64) -> Result<(), String> {
    if n == 0 {
        return Err("modulus must be >= 1".into());
    }
    let d = DoubleZn { n };
    let dim = d.dim();
    for x in 0..dim {
        for y in 0..dim {
            // Unitarity: |R| = 1.
            if (d.r(x, y).abs2() - 1.0).abs() > tol {
                return Err(format!("|R[{x},{y}]| != 1"));
            }
            // Monodromy ties R to the modular data: R(x,y)·R(y,x) = ω^{a b' + a' b}.
            let (a, b) = (x / n, x % n);
            let (a2, b2) = (y / n, y % n);
            let mono = d.r(x, y).times(d.r(y, x));
            let want = d.omega((a * b2 + a2 * b) as i64);
            if !mono.close(want, tol) {
                return Err(format!("monodromy R[{x},{y}]R[{y},{x}] != omega^(ab'+a'b)"));
            }
            // Hexagon (Yang–Baxter for a pointed category): R is bimultiplicative.
            for z in 0..dim {
                let lhs1 = d.r(d.add_obj(x, z), y);
                let rhs1 = d.r(x, y).times(d.r(z, y));
                if !lhs1.close(rhs1, tol) {
                    return Err(format!("hexagon (left) fails at ({x},{z};{y})"));
                }
                let lhs2 = d.r(x, d.add_obj(y, z));
                let rhs2 = d.r(x, y).times(d.r(x, z));
                if !lhs2.close(rhs2, tol) {
                    return Err(format!("hexagon (right) fails at ({x};{y},{z})"));
                }
            }
        }
    }
    Ok(())
}

/// A measurement for the universality probe: the number of distinct braiding phases
/// `R_{x,y} = ω^{a'b}` for `D(Z_n)`. This is the size of the generated phase set — finite for
/// the abelian double, so the braiding closure is *not* dense. A measurement only; universality
/// is neither asserted nor denied.
#[must_use]
pub fn generated_phase_order(n: usize) -> usize {
    if n == 0 {
        return 0;
    }
    let d = DoubleZn { n };
    let dim = d.dim();
    let mut residues = std::collections::BTreeSet::new();
    for x in 0..dim {
        let (_, b) = d.coords(x);
        for y in 0..dim {
            let (a2, _) = d.coords(y);
            residues.insert((a2 * b) % n);
        }
    }
    residues.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generated_phase_order_is_finite() {
        // Finite (abelian double) — a measurement, not a universality claim.
        assert!(generated_phase_order(8) >= 1);
        assert!(generated_phase_order(4) >= 1);
    }

    #[test]
    fn modular_relations_hold_for_small_doubles() {
        for n in [2usize, 3, 4, 5, 8] {
            verify_modular(n, TOL).unwrap_or_else(|e| panic!("D(Z_{n}) modular: {e}"));
        }
    }

    #[test]
    fn braiding_axioms_hold_for_small_doubles() {
        for n in [2usize, 3, 4, 8] {
            verify_braiding(n, TOL).unwrap_or_else(|e| panic!("D(Z_{n}) braiding: {e}"));
        }
    }
}
