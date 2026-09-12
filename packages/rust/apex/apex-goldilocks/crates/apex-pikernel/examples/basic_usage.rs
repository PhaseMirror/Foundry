use std::collections::HashMap;
use ndarray::{Array1, Array2};
use num_traits::{Zero, One};
use apex_pikernel::{
    ProjectorFamily, PiIndexGrid, PiKernel,
    DefaultLedger, Rational
};

fn main() -> anyhow::Result<()> {
    // 1. Define projector families (orthogonal partitions)
    let a = ProjectorFamily::new(
        vec![vec![0, 2, 4, 6], vec![1, 3, 5, 7]],
        "FunctionType".to_string()
    );
    let b = ProjectorFamily::new(
        vec![vec![0, 1, 2, 3], vec![4, 5, 6, 7]],
        "MemoryRegion".to_string()
    );

    // 2. Build PI-atom grid
    let grid = PiIndexGrid::new(vec![a, b]).map_err(|e| anyhow::anyhow!(e))?;
    let piids = &grid.pi_ids;

    // 3. Configure dynamics
    let mut alphas = HashMap::new();
    let mut weights = HashMap::new();
    let mut taus = HashMap::new();

    let alpha_val = Rational::new(25, 100);
    let tau_val = Rational::new(15, 10);

    for pi in piids {
        alphas.insert(pi.clone(), alpha_val);
        let indices = grid.indices(pi).unwrap();
        weights.insert(pi.clone(), Array1::from_elem(indices.len(), Rational::one()));
        taus.insert(pi.clone(), tau_val);
    }

    // Coupling matrix
    let m = piids.len();
    let mut k = Array2::from_elem((m, m), Rational::new(5, 100));
    for i in 0..m {
        k[[i, i]] = Rational::zero();
    }

    // 4. Initialize kernel
    let ledger = Box::new(DefaultLedger::new(None));
    let mut kernel = PiKernel::new(
        &grid,
        alphas,
        weights,
        taus,
        k,
        None,
        Some(ledger),
    )?;

    // 5. Run
    let mut x = Array1::from_elem(8, Rational::one());
    
    for t in 0..10 {
        let result = kernel.step(&x)?;
        x = result.x_new;
        
        println!("Step {}: SlopeUB={}, GapLB={}, Touched={}", 
            t, result.slope_ub, result.gap_lb, result.touched.len());
        
        assert!(result.gap_lb > Rational::zero(), "Contraction violated!");
    }

    Ok(())
}
