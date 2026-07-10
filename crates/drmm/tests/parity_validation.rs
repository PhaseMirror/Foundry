use drmm_rs::*;
use ndarray::Array2;
use serde::Deserialize;
use std::fs;

#[derive(Deserialize)]
struct ParityVectors {
    primes: PrimesVector,
    tensor_core: TensorCoreVector,
    xi_evolution: XiEvolutionVector,
    lambdam_field: LambdaMFieldVector,
    moonshine: MoonshineVector,
    ethical_modulator: EthicalModulatorVector,
}

#[derive(Deserialize)]
struct PrimesVector {
    count: usize,
    expected: Vec<u64>,
}

#[derive(Deserialize)]
struct TensorCoreVector {
    input_n: usize,
    input_dim: usize,
    output_tensor: Vec<Vec<f64>>,
    normalized_tensor: Vec<Vec<f64>>,
}

#[derive(Deserialize)]
struct XiEvolutionVector {
    input: Vec<Vec<f64>>,
    alpha: f64,
    t: f64,
    output: Vec<Vec<f64>>,
}

#[derive(Deserialize)]
struct LambdaMFieldVector {
    t: f64,
    output: f64,
}

#[derive(Deserialize)]
struct MoonshineVector {
    group_id: i32,
    frequency: f64,
    input: Vec<Vec<f64>>,
    t: f64,
    output: Vec<Vec<f64>>,
}

#[derive(Deserialize)]
struct EthicalModulatorVector {
    filter_strength: f64,
    input: Vec<Vec<f64>>,
    output: Vec<Vec<f64>>,
}

fn vec_to_array2(v: Vec<Vec<f64>>) -> Array2<f64> {
    let rows = v.len();
    let cols = v[0].len();
    let mut arr = Array2::zeros((rows, cols));
    for i in 0..rows {
        for j in 0..cols {
            arr[[i, j]] = v[i][j];
        }
    }
    arr
}

#[test]
fn test_cross_language_parity() {
    let data = fs::read_to_string("../drmm/parity_vectors.json").expect("Unable to read parity_vectors.json");
    let vectors: ParityVectors = serde_json::from_str(&data).expect("JSON was not well-formatted");

    // 1. Primes
    let rust_primes = generate_first_n_primes(vectors.primes.count);
    assert_eq!(rust_primes, vectors.primes.expected);

    // 2. Tensor Core
    let t = prime_indexed_tensor(vectors.tensor_core.input_n, vectors.tensor_core.input_dim);
    println!("Rust Tensor:\n{:?}", t);
    let expected_t = vec_to_array2(vectors.tensor_core.output_tensor);
    assert!((&t - &expected_t).mapv(|v| v.abs()).sum() < 1e-9);

    let tn = normalize_tensor(&t);
    let expected_tn = vec_to_array2(vectors.tensor_core.normalized_tensor);
    assert!((&tn - &expected_tn).mapv(|v| v.abs()).sum() < 1e-9);

    // 3. Xi Evolution (Entropic Feedback)
    let mut x = vec_to_array2(vectors.xi_evolution.input);
    let loop_ctrl = EntropicFeedbackLoop::new(vectors.xi_evolution.alpha);
    loop_ctrl.update(&mut x, vectors.xi_evolution.t);
    let expected_x = vec_to_array2(vectors.xi_evolution.output);
    assert!((&x - &expected_x).mapv(|v| v.abs()).sum() < 1e-9);

    // 4. LambdaM Field
    let l_val = LambdaM::field(vectors.lambdam_field.t);
    assert!((l_val - vectors.lambdam_field.output).abs() < 1e-9);

    // 5. Moonshine Modulation
    let moon = MoonshineOperator::new(vectors.moonshine.group_id, Some(vectors.moonshine.frequency));
    let x_moon_in = vec_to_array2(vectors.moonshine.input);
    let x_moon_out = moon.apply(&x_moon_in, vectors.moonshine.t);
    let expected_moon = vec_to_array2(vectors.moonshine.output);
    assert!((&x_moon_out - &expected_moon).mapv(|v| v.abs()).sum() < 1e-9);

    // 6. Ethical Modulator
    let mut x_eth = vec_to_array2(vectors.ethical_modulator.input);
    let eth = EthicalModulator::new(vectors.ethical_modulator.filter_strength);
    eth.apply(&mut x_eth);
    let expected_eth = vec_to_array2(vectors.ethical_modulator.output);
    assert!((&x_eth - &expected_eth).mapv(|v| v.abs()).sum() < 1e-9);
}
