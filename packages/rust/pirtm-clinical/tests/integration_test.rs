use c_pirtm_rs::core::{CROFLC, PrimeMask};
use c_pirtm_rs::math::{SpectralLinear, PrimeOperator, LowRankMixer, ResonanceGate};
use ndarray::{Array1, Array2};
use std::collections::HashMap;

#[test]
fn test_croflc_forward_pass() {
    let dim = 4;
    let rank = 2;
    
    // 1. Setup Encoder
    let encoder = SpectralLinear::new(
        Array2::eye(dim),
        Array1::zeros(dim),
        0.9
    );
    
    // 2. Setup Prime Operators
    let mut ops = HashMap::new();
    for &p in &[2, 3] {
        ops.insert(p, PrimeOperator {
            mixer: LowRankMixer {
                u: Array2::eye(dim).slice(ndarray::s![.., ..rank]).to_owned(),
                s: Array1::from_elem(rank, 0.5),
                v: Array2::eye(dim).slice(ndarray::s![.., ..rank]).to_owned(),
            },
            lin: SpectralLinear::new(
                Array2::eye(dim),
                Array1::zeros(dim),
                0.9
            ),
        });
    }
    
    // 3. Setup Resonance Gates
    let mut gates = HashMap::new();
    gates.insert(2, ResonanceGate {
        m: Array2::eye(2),
        tau: 0.0,
    });
    
    // 4. Assemble CROFLC
    let model = CROFLC {
        mask: PrimeMask::from_bit(2).or(&PrimeMask::from_bit(3)),
        encoder,
        ops,
        projectors: HashMap::new(),
        gates: Some(gates),
        gen_idx: vec![0, 1],
        bio_idx: vec![2, 3],
    };
    
    // 5. Run Forward Pass
    let input = Array1::from_vec(vec![1.0, 0.5, -0.2, 0.8]);
    let (output, trace) = model.forward(&input);
    
    println!("Output: {:?}", output);
    println!("Resonance Weights: {:?}", trace.resonance_weights);
    
    assert_eq!(output.len(), dim);
    assert!(trace.resonance_weights.contains_key(&2));
    assert!(trace.resonance_weights.contains_key(&3));
    assert!(trace.prime_activations.contains_key(&2));
    
    // Verify resonance gate logic for P2
    // x_gen = [1.0, 0.5], x_bio = [-0.2, 0.8]
    // res = 1.0 * 1.0 * -0.2 + 0.5 * 1.0 * 0.8 = -0.2 + 0.4 = 0.2
    // w = sigmoid(0.2 - 0.0) = 1 / (1 + e^-0.2) approx 0.5498
    let expected_w2 = 1.0 / (1.0 + (-0.2f64).exp());
    let (_, actual_w2) = trace.resonance_weights[&2].unpack_q29_29();
    assert!((actual_w2 - expected_w2).abs() < 1e-6);
}
