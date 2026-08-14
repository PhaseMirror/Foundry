use std::collections::HashMap;
use ndarray::{Array1, Array2};
use num_traits::{Zero, One};
use apex_pikernel::{
    ProjectorFamily, HologramAdapterManaged, HologramAdapterConfig, Rational
};

fn main() -> anyhow::Result<()> {
    // 1. Define families for 16D space
    let a = ProjectorFamily::new(
        vec![
            vec![0, 4, 8, 12],
            vec![1, 5, 9, 13],
            vec![2, 6, 10, 14],
            vec![3, 7, 11, 15]
        ],
        "SpectralBands".to_string()
    );

    let b = ProjectorFamily::new(
        vec![
            vec![0, 1, 2, 3, 4, 5, 6, 7],
            vec![8, 9, 10, 11, 12, 13, 14, 15]
        ],
        "MemoryHalves".to_string()
    );

    // 2. Build configuration
    let mut alphas = HashMap::new();
    let mut weights = HashMap::new();
    let mut taus = HashMap::new();

    let families = vec![a.clone(), b.clone()];
    let temp_grid = apex_pikernel::PiIndexGrid::new(families.clone()).map_err(|e| anyhow::anyhow!(e))?;
    
    let alpha_val = Rational::new(2, 10);
    let tau_val = Rational::new(2, 1);

    for pi in &temp_grid.pi_ids {
        alphas.insert(pi.clone(), alpha_val);
        let indices = temp_grid.indices(pi).unwrap();
        weights.insert(pi.clone(), Array1::from_elem(indices.len(), Rational::one()));
        taus.insert(pi.clone(), tau_val);
    }

    let m = temp_grid.pi_ids.len();
    let mut k = Array2::from_elem((m, m), Rational::new(5, 100));
    for i in 0..m {
        k[[i, i]] = Rational::zero();
    }

    let config = HologramAdapterConfig {
        families,
        alphas,
        weights,
        taus,
        k,
        use_poseidon: true,
        ledger_path: None,
        mub_threshold: 3.0,
        tau_shrink_factor: Rational::new(9, 10),
    };

    // 3. Initialize adapter
    let mut adapter = HologramAdapterManaged::new(config)?;

    // 4. Run
    let mut x = Array1::from_elem(16, Rational::new(5, 10));
    
    for t in 0..20 {
        let result = adapter.step(&x)?;
        x = result.x_new;
        
        if result.audit.alarm {
            println!("Step {}: MUB ALARM! D_t={:.4}", t, result.audit.d_t);
        } else {
            let mut x_norm_sq = Rational::zero();
            for i in 0..x.len() {
                x_norm_sq = x_norm_sq + (x[i] * x[i]);
            }
            println!("Step {}: x_norm_sq={}", t, x_norm_sq);
        }
    }

    println!("Final MUB alarms: {}", adapter.mub_alarms);
    println!("Ledger entries: {}", adapter.ledger.get_entries().len());

    Ok(())
}
