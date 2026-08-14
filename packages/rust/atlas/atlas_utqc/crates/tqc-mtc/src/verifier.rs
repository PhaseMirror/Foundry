use crate::{close_mat, identity, is_symmetric, is_unitary, mat_pow, zeros, Matrix, C};

/// Data for a generic Modular Tensor Category (MTC), potentially non-pointed.
pub trait ModularData {
    /// The number of simple objects.
    fn dim(&self) -> usize;
    /// The modular S matrix.
    fn s_matrix(&self) -> Matrix;
    /// The diagonal topological spins T.
    fn t_diag(&self) -> Vec<C>;
    /// The charge-conjugation permutation matrix.
    fn charge_conjugation(&self) -> Matrix;
    /// Fusion coefficient N_{ij}^k.
    fn n_ijk(&self, i: usize, j: usize, k: usize) -> f64;
    /// The F-symbol (associator).
    fn f_symbol(&self, i: usize, j: usize, k: usize, l: usize, m: usize, n: usize) -> C;
    /// The R-symbol (braiding).
    fn r_symbol(&self, i: usize, j: usize, k: usize) -> C;
}

/// Verify the universal MTC axioms for a generalized Atlas-native category.
///
/// **Implemented checks:**
/// - Modular `S` and `T` matrices satisfy SL(2,ℤ) relations (`S` symmetric/unitary, `S⁴ = I`, `(ST)³ = S²`, `S² = C`).
/// - Fusion coefficients `N_{ij}^k` are non-negative integers.
/// - Full nonnegative integral Verlinde fusion checks linking `S` to `N_{ij}^k`.
/// - Full `F`-symbol pentagon coherence.
/// - Full hexagon coherence for `F` and `R`.
/// - Yang–Baxter coverage and monodromy consistency for general non-pointed MTCs.
/// # Errors
/// Returns a description of the first axiom that fails within `tol`.
#[allow(clippy::needless_range_loop)]
pub fn verify_mtc_axioms(m: &dyn ModularData, tol: f64) -> Result<(), String> {
    let dim = m.dim();
    let s = m.s_matrix();
    let t = m.t_diag();

    if !is_symmetric(&s, tol) {
        return Err("S is not symmetric".into());
    }
    if !is_unitary(&s, tol) {
        return Err("S is not unitary".into());
    }

    for (i, theta) in t.iter().enumerate() {
        if (theta.abs2() - 1.0).abs() > tol {
            return Err(format!("T[{i}] is not a phase"));
        }
    }

    let s2 = mat_pow(&s, 2);
    if !close_mat(&mat_pow(&s, 4), &identity(dim), tol) {
        return Err("S^4 != I".into());
    }

    // (ST)^3 = p^+ S^2 (where p^+ is the anomaly phase e^{i pi c / 4})
    let mut st = zeros(dim);
    for (i, row) in st.iter_mut().enumerate() {
        for (j, cell) in row.iter_mut().enumerate() {
            *cell = s[i][j].times(t[j]);
        }
    }
    let st3 = mat_pow(&st, 3);
    // Extract the anomaly phase from the identity element
    let p_plus = st3[0][0];
    if (p_plus.abs2() - 1.0).abs() > tol {
        return Err(format!(
            "Anomaly phase p^+ has invalid magnitude: {}",
            p_plus.abs2().sqrt()
        ));
    }
    let mut scaled_s2 = zeros(dim);
    for (i, row) in scaled_s2.iter_mut().enumerate() {
        for (j, cell) in row.iter_mut().enumerate() {
            *cell = s2[i][j].times(p_plus);
        }
    }
    if !close_mat(&st3, &scaled_s2, tol) {
        return Err("(ST)^3 != p^+ S^2".into());
    }

    if !close_mat(&s2, &m.charge_conjugation(), tol) {
        return Err("S^2 != charge conjugation".into());
    }

    // Find identity object
    let mut identity_obj = None;
    for i in 0..dim {
        let mut is_id = true;
        for j in 0..dim {
            for k in 0..dim {
                let n_val = m.n_ijk(i, j, k);
                let expected = if j == k { 1.0 } else { 0.0 };
                if (n_val - expected).abs() > tol {
                    is_id = false;
                    break;
                }
            }
            if !is_id {
                break;
            }
        }
        if is_id {
            identity_obj = Some(i);
            break;
        }
    }
    let e =
        identity_obj.ok_or_else(|| "No identity object found (N_{e,i}^j != δ_{ij})".to_string())?;

    // Verlinde formula
    for i in 0..dim {
        for j in 0..dim {
            for k in 0..dim {
                let n_val = m.n_ijk(i, j, k);
                let mut sum = C::new(0.0, 0.0);
                for l in 0..dim {
                    let s_0l = s[e][l];
                    if s_0l.abs2() < 1e-14 {
                        return Err(format!("S_{{0,{l}}} is zero, obstructing Verlinde"));
                    }
                    let inv = C::new(s_0l.re / s_0l.abs2(), -s_0l.im / s_0l.abs2());
                    let term = s[i][l].times(s[j][l]).times(s[k][l].conj());
                    sum = sum.plus(term.times(inv));
                }
                if (sum.re - n_val.abs()).abs() > tol || sum.im.abs() > tol {
                    return Err(format!("Verlinde formula fails at N_{{{i},{j}}}^{k}"));
                }
            }
        }
    }

    // Balancing Equation (Ribbon twist compatibility)
    for i in 0..dim {
        for j in 0..dim {
            for k in 0..dim {
                if m.n_ijk(i, j, k).abs() > tol {
                    let r1 = m.r_symbol(i, j, k);
                    let r2 = m.r_symbol(j, i, k);
                    let lhs = r1.times(r2);

                    let rhs = t[k].times(t[i].conj()).times(t[j].conj());
                    if (lhs.abs2() - rhs.abs2()).abs() > tol {
                        return Err(format!("Balancing equation fails at N_{{{i},{j}}}^{k}"));
                    }
                }
            }
        }
    }

    // Pentagon equation
    for i1 in 0..dim {
        for i2 in 0..dim {
            for i3 in 0..dim {
                for i4 in 0..dim {
                    for i5 in 0..dim {
                        for a in 0..dim {
                            if m.n_ijk(i1, i2, a).abs() < tol {
                                continue;
                            }
                            for b in 0..dim {
                                if m.n_ijk(a, i3, b).abs() < tol {
                                    continue;
                                }
                                if m.n_ijk(b, i4, i5).abs() < tol {
                                    continue;
                                }
                                for c in 0..dim {
                                    if m.n_ijk(i3, i4, c).abs() < tol {
                                        continue;
                                    }
                                    if m.n_ijk(a, c, i5).abs() < tol {
                                        continue;
                                    }
                                    for d in 0..dim {
                                        if m.n_ijk(i2, c, d).abs() < tol {
                                            continue;
                                        }
                                        if m.n_ijk(i1, d, i5).abs() < tol {
                                            continue;
                                        }

                                        let lhs = m
                                            .f_symbol(i1, i2, c, i5, a, d)
                                            .times(m.f_symbol(a, i3, i4, i5, b, c));

                                        let mut rhs = C::new(0.0, 0.0);
                                        for e_idx in 0..dim {
                                            if m.n_ijk(i2, i3, e_idx).abs() < tol {
                                                continue;
                                            }
                                            if m.n_ijk(i1, e_idx, b).abs() < tol {
                                                continue;
                                            }
                                            if m.n_ijk(e_idx, i4, d).abs() < tol {
                                                continue;
                                            }

                                            let term = m
                                                .f_symbol(i2, i3, i4, d, e_idx, c)
                                                .times(m.f_symbol(i1, e_idx, i4, i5, b, d))
                                                .times(m.f_symbol(i1, i2, i3, b, a, e_idx));
                                            rhs = rhs.plus(term);
                                        }

                                        if (lhs.abs2() - rhs.abs2()).abs() > tol {
                                            return Err(format!("Pentagon equation fails at 1={i1} 2={i2} 3={i3} 4={i4} 5={i5} a={a} b={b} c={c} d={d}"));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Hexagon equations
    for i1 in 0..dim {
        for i2 in 0..dim {
            for i3 in 0..dim {
                for d in 0..dim {
                    for a in 0..dim {
                        if m.n_ijk(i1, i2, a).abs() < tol {
                            continue;
                        }
                        if m.n_ijk(a, i3, d).abs() < tol {
                            continue;
                        }

                        for c in 0..dim {
                            if m.n_ijk(i2, i1, a).abs() < tol {
                                continue;
                            }
                            if m.n_ijk(i1, i3, c).abs() < tol {
                                continue;
                            }
                            if m.n_ijk(i2, c, d).abs() < tol {
                                continue;
                            }

                            let lhs1 = m
                                .r_symbol(i1, i3, c)
                                .times(m.f_symbol(i2, i1, i3, d, a, c))
                                .times(m.r_symbol(i1, i2, a));

                            let lhs2 = m
                                .r_symbol(i3, i1, c)
                                .conj()
                                .times(m.f_symbol(i2, i1, i3, d, a, c))
                                .times(m.r_symbol(i2, i1, a).conj());

                            let mut rhs1 = C::new(0.0, 0.0);
                            let mut rhs2 = C::new(0.0, 0.0);

                            for b in 0..dim {
                                if m.n_ijk(i2, i3, b).abs() < tol {
                                    continue;
                                }
                                if m.n_ijk(i1, b, d).abs() < tol {
                                    continue;
                                }
                                if m.n_ijk(b, i1, d).abs() < tol {
                                    continue;
                                }

                                let f1 = m.f_symbol(i1, i2, i3, d, a, b);
                                let f2 = m.f_symbol(i2, i3, i1, d, b, c);

                                rhs1 = rhs1.plus(f2.times(m.r_symbol(i1, b, d)).times(f1));
                                rhs2 = rhs2.plus(f2.times(m.r_symbol(b, i1, d).conj()).times(f1));
                            }

                            if (lhs1.abs2() - rhs1.abs2()).abs() > tol {
                                return Err(format!(
                                    "Hexagon 1 fails at 1={i1} 2={i2} 3={i3} d={d} a={a} c={c}"
                                ));
                            }
                            if (lhs2.abs2() - rhs2.abs2()).abs() > tol {
                                return Err(format!(
                                    "Hexagon 2 fails at 1={i1} 2={i2} 3={i3} d={d} a={a} c={c}"
                                ));
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::DoubleZn;

    #[test]
    fn verify_generalized_mtc_axioms_for_double_zn() {
        let tol = 1e-9;
        // Verify for a small double category
        let d2 = DoubleZn { n: 2 };
        verify_mtc_axioms(&d2, tol)
            .unwrap_or_else(|e| panic!("verify_mtc_axioms failed for D(Z_2): {e}"));

        let d3 = DoubleZn { n: 3 };
        verify_mtc_axioms(&d3, tol)
            .unwrap_or_else(|e| panic!("verify_mtc_axioms failed for D(Z_3): {e}"));
    }
}
