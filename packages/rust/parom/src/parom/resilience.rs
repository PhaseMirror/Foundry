use nalgebra::DVector;
use std::collections::HashMap;

pub struct ResilienceMap {
    pub multiplicity: HashMap<(i32, i32, i32), usize>,
    pub bins: i32,
}

impl ResilienceMap {
    pub fn new(bins: i32) -> Self {
        Self {
            multiplicity: HashMap::new(),
            bins,
        }
    }

    fn discretize(&self, v: &DVector<f64>) -> (i32, i32, i32) {
        // Normalize to [0, bins]
        // qr_ratio [0,1], ddq50 [-1,1] -> [0,1], w_t [0,1]
        let x = (v[0] * self.bins as f64).floor() as i32;
        let y = ((v[1] + 1.0) / 2.0 * self.bins as f64).floor() as i32;
        let z = (v[2] * self.bins as f64).floor() as i32;
        (x, y, z)
    }

    pub fn train(&mut self, trajectories: &[Vec<DVector<f64>>]) {
        for traj in trajectories {
            for v in traj {
                let cell = self.discretize(v);
                *self.multiplicity.entry(cell).or_insert(0) += 1;
            }
        }
    }

    pub fn get_omega(&self, v: &DVector<f64>) -> usize {
        let cell = self.discretize(v);
        *self.multiplicity.get(&cell).unwrap_or(&0)
    }
}

pub fn run_resilience_analysis(trajectories: Vec<Vec<DVector<f64>>>) {
    let mut map = ResilienceMap::new(4); // Coarser grid (4x4x4 = 64 cells)
    map.train(&trajectories);
    
    println!("----- Multiplicity Ω Resilience Analysis -----");
    println!("Total Occupied Macrostates: {}", map.multiplicity.len());
    
    for (i, traj) in trajectories.iter().enumerate() {
        println!("Trajectory {}:", i);
        let mut prev_omega = None;
        for (step, v) in traj.iter().enumerate() {
            let omega = map.get_omega(v);
            let trend = match prev_omega {
                Some(p) if omega < p => "FRAGILIZING",
                Some(p) if omega > p => "STABILIZING",
                _ => "STABLE",
            };
            println!("  Step {}: Ω = {}, Status: {}", step, omega, trend);
            prev_omega = Some(omega);
        }
    }
}
