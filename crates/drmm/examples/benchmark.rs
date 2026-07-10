use drmm_rs::moonshine::MoonshineOperator;
use ndarray::Array2;
use std::time::Instant;

fn main() {
    let dim = 64;
    let steps = 1000;
    let mut x = Array2::from_elem((dim, dim), 0.5); // Using a fixed value for consistency in computation
    let moon = MoonshineOperator::new(2, None);
    
    let start = Instant::now();
    for t in 0..steps {
        x = moon.apply(&x, (t as f64) / (steps as f64));
    }
    let duration = start.elapsed();
    
    println!("Rust DRMM Benchmark (dim={}, steps={}): {:.4} seconds", dim, steps, duration.as_secs_f64());
}
