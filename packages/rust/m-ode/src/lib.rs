use nalgebra::DVector;

pub struct DynamicsParams {
    pub kappa2: f64,
    pub kappa3: f64,
    pub mu: f64,
    pub omega2: f64,
    pub omega3: f64,
    pub nu: f64,
}

pub fn multiplicity_dynamics(t: f64, y: &DVector<f64>, params: &DynamicsParams) -> DVector<f64> {
    let m2 = y[0];
    let m3 = y[1];
    let delta_phi = y[2];
    
    let interaction = params.mu * (m2 * m3).max(0.0).sqrt() * delta_phi.cos();
    
    let dm2_dt = params.kappa2 * m2 + interaction;
    let dm3_dt = params.kappa3 * m3 + interaction;
    
    let sync_strength = params.nu * (m2 + m3) / (1.0 + m2 * m3);
    let ddelta_phi_dt = (params.omega2 - params.omega3) - sync_strength * delta_phi.sin();
    
    DVector::from_vec(vec![dm2_dt, dm3_dt, ddelta_phi_dt])
}

pub fn rk4_step(
    t: f64, 
    y: &DVector<f64>, 
    dt: f64, 
    params: &DynamicsParams
) -> DVector<f64> {
    let k1 = multiplicity_dynamics(t, y, params);
    let k2 = multiplicity_dynamics(t + dt / 2.0, &(y + &k1 * (dt / 2.0)), params);
    let k3 = multiplicity_dynamics(t + dt / 2.0, &(y + &k2 * (dt / 2.0)), params);
    let k4 = multiplicity_dynamics(t + dt, &(y + &k3 * dt), params);
    
    y + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (dt / 6.0)
}

pub fn run_simulation(
    params: DynamicsParams,
    y0: DVector<f64>,
    t_start: f64,
    t_end: f64,
    steps: usize,
) -> Vec<(f64, DVector<f64>)> {
    let dt = (t_end - t_start) / steps as f64;
    let mut results = Vec::with_capacity(steps + 1);
    let mut y = y0;
    let mut t = t_start;
    
    results.push((t, y.clone()));
    
    for _ in 0..steps {
        y = rk4_step(t, &y, dt, &params);
        t += dt;
        results.push((t, y.clone()));
    }
    
    results
}
