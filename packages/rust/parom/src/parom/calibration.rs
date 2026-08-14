use nalgebra::{DMatrix, DVector};

pub fn calibrate_operator(
    trajectories: &[Vec<DVector<f64>>],
    dimension: usize,
) -> DMatrix<f64> {
    // Collect all transitions into flat matrices
    let mut x_list = Vec::new();
    let mut y_list = Vec::new();
    
    for traj in trajectories {
        if traj.len() >= 2 {
            for i in 0..traj.len()-1 {
                x_list.push(traj[i].clone());
                y_list.push(traj[i+1].clone());
            }
        }
    }
    
    let n = x_list.len();
    if n > 0 {
        let mut a_matrix = DMatrix::zeros(n, dimension);
        let mut b_matrix = DMatrix::zeros(n, dimension);
        
        for i in 0..n {
            a_matrix.set_row(i, &x_list[i].transpose());
            b_matrix.set_row(i, &y_list[i].transpose());
        }
        
        // Solve for Xi_0: A * Xi_0^T = B  => Xi_0^T = (A^T * A)^-1 * A^T * B
        let ata = a_matrix.transpose() * &a_matrix;
        let atb = a_matrix.transpose() * &b_matrix;
        
        let xi_raw = match ata.pseudo_inverse(1e-9) {
            Ok(inv) => inv * atb,
            Err(_) => DMatrix::identity(dimension, dimension) * 0.9,
        };
        
        xi_raw.transpose()
    } else {
        DMatrix::identity(dimension, dimension) * 0.9
    }
}
