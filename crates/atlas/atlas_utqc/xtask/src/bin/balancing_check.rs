#![allow(clippy::unwrap_used)]
#![allow(missing_docs)]

use tqc_atlas::canonical;
use tqc_model::Model;

fn main() {
    let p = canonical(&Model::load().unwrap()).unwrap();
    let m = tqc_mtc::native::construct_atlas_native(&p).unwrap();
    let dim = m.dim();
    let t = m.t_diag();
    let mut passed = true;
    for i in 0..dim {
        for j in 0..dim {
            for k in 0..dim {
                if m.n_ijk(i, j, k) > 0.5 {
                    // For abelian, N_ij^k = 1 for a single k.
                    let r1 = m.r_symbol(i, j, k);
                    let r2 = m.r_symbol(j, i, k);
                    let lhs = r1.times(r2);

                    let rhs = t[k].times(t[i].conj()).times(t[j].conj());
                    if !lhs.close(rhs, 1e-9) {
                        println!("Balancing fails at i={}, j={}, k={}: R_ij R_ji = {:?}, T_k/(T_i T_j) = {:?}", i, j, k, lhs, rhs);
                        passed = false;
                    }
                }
            }
        }
    }
    if passed {
        println!("Balancing holds!");
    } else {
        println!("Balancing failed!");
    }
}
