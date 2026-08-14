use nalgebra::{DMatrix, DVector};
use pirtm_rs::{EmissionPolicy, QARIConfig, SessionOrchestrator};

fn main() {
    println!("PIRTM-rs Smoke Test");

    let dim = 2;
    let mut orch = SessionOrchestrator::new();
    let config = QARIConfig {
        dim,
        epsilon: 0.05,
        op_norm_t: 0.8,
        emission_policy: EmissionPolicy::PassThrough,
        ..Default::default()
    };

    let session = orch.register("session-1", config).unwrap();

    let x = DVector::from_element(dim, 1.0);
    let xi = DMatrix::from_element(dim, dim, 0.2);
    let lam = DMatrix::from_element(dim, dim, 0.2);
    let g = DVector::zeros(dim);
    let t_op = |v: &DVector<f64>| 0.8 * v;

    let out = session.step(&x, &xi, &lam, t_op, &g).unwrap();
    println!("Step 0: emitted={}, q={:.4}", out.emitted, out.info.q);

    let cert = session.certify(0.0).unwrap();
    println!("Certified: {}, margin: {:.4}", cert.certified, cert.margin);

    let summary = session.summary();
    println!(
        "Summary: {}",
        serde_json::to_string_pretty(&summary).unwrap()
    );
}
