#![allow(clippy::unwrap_used)]
#![allow(missing_docs)]

use std::time::Instant;
use tqc_atlas::canonical;
use tqc_core::amplitude::{self, Amplitude};
use tqc_core::generators::{Generators, Permutation};
use tqc_model::Model;

fn main() {
    let model = Model::load().unwrap();
    let p = canonical(&model).unwrap();
    let g = Generators::new(&p);
    let gens = [&g.sigma, &g.tau, &g.mu];
    let n = p.class_count() as usize;
    let base: Vec<i64> = (0..n as i64).map(|i| i % 7 - 3).collect();

    println!("Holospaces / Atlas-Native MTC Scaling Benchmark");
    println!("-----------------------------------------------");
    println!("Evaluating topological memory collapse via UOR content-addressing.");
    println!(
        "Carrier Dimension (Topological State Size): {} bytes",
        base.len() * 8
    );
    println!();

    // We will measure scaling for increasing braid depths.
    for length in [2, 4, 6, 8, 10] {
        let total = 3usize.pow(length);
        let mut distinct: Vec<String> = Vec::new();
        let start = Instant::now();

        for w in 0..total {
            let mut perm = Permutation::identity(p.class_count());
            let mut x = w;
            for _ in 0..length {
                perm = perm.then(gens[x % 3]);
                x /= 3;
            }
            let state = perm.permute_amplitudes(&base);
            let amp: Vec<(u64, Amplitude)> = state
                .iter()
                .enumerate()
                .map(|(i, &v)| (i as u64, Amplitude { re: v, im: 0 }))
                .collect();
            let k = tqc_substrate::kappa(&amplitude::encode(&amp)).to_string();
            if !distinct.contains(&k) {
                distinct.push(k);
            }
        }

        let elapsed = start.elapsed();
        let classical_memory_estimate = (total * base.len() * 8) as f64 / 1024.0 / 1024.0; // MB
        let holospace_memory = (distinct.len() * base.len() * 8) as f64 / 1024.0; // KB

        println!(
            "Depth: {:<2} | Paths Evaluated: {:<8} | Distinct UOR States (κ): {:<4}",
            length,
            total,
            distinct.len()
        );
        println!(
            "  ├─ Classical State-Vector Ram: ~{:.2} MB",
            classical_memory_estimate
        );
        println!(
            "  ├─ Holospace Topological Ram:  ~{:.2} KB",
            holospace_memory
        );
        println!(
            "  ├─ Compression / Cache-Hit:    {:.2}%",
            100.0 * (1.0 - (distinct.len() as f64 / total as f64))
        );
        println!(
            "  └─ Elapsed Time:               {:.2}ms\n",
            elapsed.as_secs_f64() * 1000.0
        );
    }
}
