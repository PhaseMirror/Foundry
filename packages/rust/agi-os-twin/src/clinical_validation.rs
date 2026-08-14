use anyhow::Result;
use nalgebra::DVector;
use csv::ReaderBuilder;
use serde::{Deserialize, Serialize};
use trace_serializer::{ExecutionTrace, TraceRow};

#[derive(Debug, Deserialize)]
pub struct CalerieRecord {
    pub deidnum: String,
    pub visit: String,
    pub crp: f64,
    pub il6: f64,
    pub hrv_proxy: f64,
}

pub struct ClinicalValidator {
    pub sampling_cadence_days: f64,
}

impl ClinicalValidator {
    pub fn new(cadence: f64) -> Self {
        Self { sampling_cadence_days: cadence }
    }

    /// Ingests a longitudinal trajectory and produces an execution trace for ZK proving.
    pub fn run_diagnostic_trace(&self, data_path: &str, target_id: &str) -> Result<(String, ExecutionTrace)> {
        let mut reader = ReaderBuilder::new()
            .has_headers(true)
            .from_path(data_path)?;

        let mut records: Vec<CalerieRecord> = Vec::new();
        for result in reader.deserialize() {
            let record: CalerieRecord = result?;
            if record.deidnum == target_id {
                records.push(record);
            }
        }

        if records.is_empty() {
            return Ok((format!("No data found for subject {}", target_id), ExecutionTrace::new()));
        }

        use crate::PhysiologicalHostController;
        let mut controller = PhysiologicalHostController::new(target_id.to_string(), DVector::zeros(6));
        let mut trace = ExecutionTrace::new();
        
        let mut p11_steps = Vec::new();
        let mut p23_steps = Vec::new();

        for (step_idx, record) in records.iter().enumerate() {
            let microstate = DVector::from_vec(vec![
                record.crp,
                record.il6,
                0.0,
                0.0,
                record.hrv_proxy,
                0.0,
            ]);

            let audit = controller.step(&microstate)?;
            
            let mut row = TraceRow::default();
            row.step = step_idx as u64;
            row.a = (record.crp * 1000.0) as u64; // Scaled CRP
            row.d = (record.il6 * 1000.0) as u64; // Scaled IL-6
            row.s = (record.hrv_proxy.abs() * 1000.0) as u64; // Scaled HRV
            
            if audit.sector_violations.contains(&11) {
                p11_steps.push(step_idx);
                row.witness_flag = 1;
                row.bit = 11; // Use 'bit' column to indicate which sector
            }
            if audit.sector_violations.contains(&2) || audit.sector_violations.contains(&3) {
                p23_steps.push(step_idx);
                row.witness_flag = 1;
                row.bit = 2; // Priority to lower sector ID
            }

            // Map controller metrics to trace columns
            row.q = (audit.composite_norm * 1000.0) as u64;
            row.r = (audit.lipschitz_estimate * 1000.0) as u64;

            trace.push(row);
        }

        let mut report = String::from("----- Track 2: Empirical Clinical Diagnostic (Trace Mode) -----\n");
        report.push_str(&format!("Subject ID: {}\n", target_id));
        report.push_str(&format!("Trajectory Length: {} steps\n", records.len()));

        if !p11_steps.is_empty() && !p23_steps.is_empty() {
            let first_p11 = p11_steps[0];
            let first_p23 = p23_steps[0];
            let lag = first_p23 as i32 - first_p11 as i32;

            report.push_str(&format!("Detected Neuroimmune Drift (P11): Step {}\n", first_p11));
            report.push_str(&format!("Detected Inflammatory Spike (P2/3): Step {}\n", first_p23));
            report.push_str(&format!("Empirical Lag Δτ: {} steps\n", lag));

            if lag >= 15 && lag <= 30 {
                report.push_str("VERDICT: Prediction VALIDATED. Measured lag matches the 22-step neuroimmune window.\n");
            } else {
                report.push_str("VERDICT: Prediction FALSIFIED. Empirical lag diverges from simulation bounds.\n");
            }
        } else {
            report.push_str("RESULT: Insufficient events to compute temporal lag.\n");
        }

        Ok((report, trace))
    }

    /// Ingests a longitudinal trajectory from a CSV and runs the diagnostic.
    /// Expects CALERIE-like format but with daily cadence for the 22-step lag.
    pub fn run_diagnostic(&self, data_path: &str, target_id: &str) -> Result<String> {
        let mut reader = ReaderBuilder::new()
            .has_headers(true)
            .from_path(data_path)?;

        let mut records: Vec<CalerieRecord> = Vec::new();
        for result in reader.deserialize() {
            let record: CalerieRecord = result?;
            if record.deidnum == target_id {
                records.push(record);
            }
        }

        if records.is_empty() {
            return Ok(format!("No data found for subject {}", target_id));
        }

        // Run the controller on the trajectory
        use crate::PhysiologicalHostController;
        let mut controller = PhysiologicalHostController::new(target_id.to_string(), DVector::zeros(6));
        
        let mut p11_steps = Vec::new();
        let mut p23_steps = Vec::new();

        for (step, record) in records.iter().enumerate() {
            // Map record to 6-D microstate
            // [CRP, IL-6, DAO, BP, HRV, Sleep]
            let microstate = DVector::from_vec(vec![
                record.crp,
                record.il6,
                0.0, // DAO proxy
                0.0, // BP proxy
                record.hrv_proxy,
                0.0, // Sleep proxy
            ]);

            let audit = controller.step(&microstate)?;
            
            if audit.sector_violations.contains(&11) {
                p11_steps.push(step);
            }
            if audit.sector_violations.contains(&2) || audit.sector_violations.contains(&3) {
                p23_steps.push(step);
            }
        }

        let mut report = String::from("----- Track 2: Empirical Clinical Diagnostic -----\n");
        report.push_str(&format!("Subject ID: {}\n", target_id));
        report.push_str(&format!("Trajectory Length: {} steps\n", records.len()));

        if !p11_steps.is_empty() && !p23_steps.is_empty() {
            let first_p11 = p11_steps[0];
            let first_p23 = p23_steps[0];
            let lag = first_p23 as i32 - first_p11 as i32;

            report.push_str(&format!("Detected Neuroimmune Drift (P11): Step {}\n", first_p11));
            report.push_str(&format!("Detected Inflammatory Spike (P2/3): Step {}\n", first_p23));
            report.push_str(&format!("Empirical Lag Δτ: {} steps\n", lag));

            if lag >= 15 && lag <= 30 {
                report.push_str("VERDICT: Prediction VALIDATED. Measured lag matches the 22-step neuroimmune window.\n");
            } else {
                report.push_str("VERDICT: Prediction FALSIFIED. Empirical lag diverges from simulation bounds.\n");
            }
        } else {
            report.push_str("RESULT: Insufficient events to compute temporal lag.\n");
        }

        Ok(report)
    }
}

pub fn generate_synthetic_calerie(path: &str) -> Result<()> {
    use std::fs::File;
    use std::io::Write;

    let mut file = File::create(path)?;
    writeln!(file, "deidnum,visit,crp,il6,hrv_proxy")?;

    // Subject 1: Validates the 22-step lag
    for step in 0..60 {
        let (crp, il6, hrv) = if step < 10 {
            (0.1, 0.05, 0.0) // Healthy
        } else if step < 32 {
            // Phase 1: HRV drift starts at step 10
            (0.1, 0.05, -2.0) // Stronger drift for faster detection
        } else {
            // Phase 2: Inflammatory spike starts at step 32 (10 + 22 = 32)
            (5.0, 3.0, -2.5) // Stronger spike
        };
        writeln!(file, "CAL-001,DAY_{},{},{},{}", step, crp, il6, hrv)?;
    }

    Ok(())
}

pub fn characterize_temporal_sensitivity() -> Result<String> {
    use std::fs::File;
    use std::io::Write;
    
    let mut report = String::from("----- Minimum Detectable Event Duration Characterization -----\n");
    report.push_str("Cadence: Daily (1 step = 1 day)\n");
    report.push_str("Filter: Meta-Ensemble Stability (Double-Confirmation Required)\n\n");
    report.push_str("Duration (Steps) | Detected? | Delay (Steps)\n");
    report.push_str("-----------------|-----------|--------------\n");

    let durations = vec![1, 2, 3, 5, 10];
    let data_path = "/tmp/sensitivity_test.csv";

    for d in durations {
        let mut file = File::create(data_path)?;
        writeln!(file, "deidnum,visit,crp,il6,hrv_proxy")?;
        
        // Generate trajectory with perturbation of length 'd'
        for step in 0..50 {
            let (crp, il6, hrv) = if step >= 10 && step < 10 + d {
                (0.1, 0.05, -2.0) // Perturbation
            } else {
                (0.1, 0.05, 0.0)  // Healthy
            };
            writeln!(file, "TEST_D{},DAY_{},{},{},{}", d, step, crp, il6, hrv)?;
        }

        let validator = ClinicalValidator::new(1.0);
        let mut controller = crate::PhysiologicalHostController::new(format!("TEST_D{}", d), DVector::zeros(6));
        
        let mut reader = ReaderBuilder::new().has_headers(true).from_path(data_path)?;
        let mut detected = false;
        let mut detection_step = 0;

        for (step, result) in reader.deserialize::<CalerieRecord>().enumerate() {
            let record = result?;
            let microstate = DVector::from_vec(vec![record.crp, record.il6, 0.0, 0.0, record.hrv_proxy, 0.0]);
            let audit = controller.step(&microstate)?;
            if audit.sector_violations.contains(&11) && !detected {
                detected = true;
                detection_step = step;
            }
        }

        let delay = if detected { (detection_step as i32 - 10).to_string() } else { "N/A".to_string() };
        report.push_str(&format!("{:16} | {:9} | {:12}\n", d, detected, delay));
    }

    Ok(report)
}

pub struct LogisticBaseline {
    pub weights: Vec<f64>, // [intercept, crp_t, crp_delta, il6_t, il6_delta]
    pub threshold: f64,
}

pub struct HRVEnhancedBaseline {
    pub weights: Vec<f64>, // [intercept, crp_t, crp_delta, il6_t, il6_delta, hrv_t, hrv_delta]
    pub threshold: f64,
}

impl HRVEnhancedBaseline {
    pub fn new() -> Self {
        Self {
            weights: vec![-5.0, 1.2, 0.5, 0.8, 0.3, -1.5, -0.5],
            threshold: 0.5,
        }
    }

    pub fn predict_scores(&self, crp: &[f64], il6: &[f64], hrv: &[f64]) -> Vec<f64> {
        let mut scores = vec![0.0; crp.len()];
        if crp.len() < 2 { return scores; }

        for t in 1..crp.len() {
            let z = self.weights[0] 
                + self.weights[1] * crp[t] 
                + self.weights[2] * (crp[t] - crp[t-1]) 
                + self.weights[3] * il6[t] 
                + self.weights[4] * (il6[t] - il6[t-1])
                + self.weights[5] * hrv[t]
                + self.weights[6] * (hrv[t] - hrv[t-1]);
            scores[t] = 1.0 / (1.0 + (-z).exp());
        }
        scores
    }
}

impl LogisticBaseline {
    pub fn new() -> Self {
        // Pre-calibrated weights for high-specificity detection
        Self {
            weights: vec![-5.0, 1.2, 0.5, 0.8, 0.3],
            threshold: 0.5,
        }
    }

    pub fn predict(&self, crp: &[f64], il6: &[f64]) -> Vec<bool> {
        let mut predictions = vec![false; crp.len()];
        if crp.len() < 2 { return predictions; }

        for t in 1..crp.len() {
            let crp_t = crp[t];
            let crp_delta = crp[t] - crp[t-1];
            let il6_t = il6[t];
            let il6_delta = il6[t] - il6[t-1];

            let z = self.weights[0] 
                + self.weights[1] * crp_t 
                + self.weights[2] * crp_delta 
                + self.weights[3] * il6_t 
                + self.weights[4] * il6_delta;
            
            let prob = 1.0 / (1.0 + (-z).exp());
            if prob > self.threshold {
                predictions[t] = true;
            }
        }
        predictions
    }

    /// Returns raw probability scores for AUROC calculation
    pub fn predict_scores(&self, crp: &[f64], il6: &[f64]) -> Vec<f64> {
        let mut scores = vec![0.0; crp.len()];
        if crp.len() < 2 { return scores; }

        for t in 1..crp.len() {
            let z = self.weights[0] 
                + self.weights[1] * crp[t] 
                + self.weights[2] * (crp[t] - crp[t-1]) 
                + self.weights[3] * il6[t] 
                + self.weights[4] * (il6[t] - il6[t-1]);
            scores[t] = 1.0 / (1.0 + (-z).exp());
        }
        scores
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EvaluationResult {
    pub sensitivity: f64,
    pub specificity: f64,
    pub auroc: f64,
    pub mean_lead_time: f64,
    pub auroc_95ci: (f64, f64),
}

pub fn compute_auroc(labels: &[bool], scores: &[f64]) -> f64 {
    if labels.is_empty() || labels.len() != scores.len() { return 0.0; }
    
    let mut combined: Vec<_> = scores.iter().zip(labels.iter()).collect();
    combined.sort_by(|a, b| b.0.partial_cmp(a.0).unwrap());

    let n_pos = labels.iter().filter(|&&l| l).count() as f64;
    let n_neg = labels.len() as f64 - n_pos;
    
    if n_pos == 0.0 || n_neg == 0.0 { return 0.5; }

    let mut auc = 0.0;
    let mut tp = 0.0;
    let mut fp = 0.0;
    let mut prev_fp = 0.0;

    for (_, &label) in combined {
        if label {
            tp += 1.0;
        } else {
            fp += 1.0;
            auc += (fp - prev_fp) * tp / n_pos;
            prev_fp = fp;
        }
    }
    auc / n_neg
}

pub fn compute_bootstrap_auroc_ci(labels: &[bool], scores: &[f64], n_resamples: usize) -> (f64, f64) {
    use rand::{Rng, SeedableRng};
    use rand_chacha::ChaCha8Rng;
    
    let mut rng = ChaCha8Rng::seed_from_u64(42);
    let mut aucs = Vec::new();
    
    for _ in 0..n_resamples {
        let mut resampled_labels = Vec::new();
        let mut resampled_scores = Vec::new();
        for _ in 0..labels.len() {
            let idx = rng.random_range(0..labels.len());
            resampled_labels.push(labels[idx]);
            resampled_scores.push(scores[idx]);
        }
        aucs.push(compute_auroc(&resampled_labels, &resampled_scores));
    }
    
    aucs.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let low = aucs[(n_resamples as f64 * 0.025) as usize];
    let high = aucs[(n_resamples as f64 * 0.975) as usize];
    (low, high)
}
