//! External Mode Controller C_ext and Deterministic Transition Machine (ADR-0038 §3.2 & §5)

use crate::estimators::ExpansionEstimator;
use crate::null_space::NullSpaceGate;
use crate::rate_cap::RateCapLimiter;
use crate::receipt::ReceiptRecord;
use crate::sandbox::Sandbox;
use crate::snapshot_store::SnapshotStore;
use crate::types::{Mode, PlantState};

/// Operational configuration for C_ext.
pub struct ControllerConfig {
    pub max_burst_dwell: u64,
    pub max_capture_retries: u64,
    pub ground_dwell: u64,
    pub v_min: f64,
    pub lambda_cap: f64,
    pub delta: f64,
    pub eps0: f64,
    pub receipt_validity_duration: u64,
}

impl Default for ControllerConfig {
    fn default() -> Self {
        Self {
            max_burst_dwell: 50,
            max_capture_retries: 3,
            ground_dwell: 20,
            v_min: 0.8,
            lambda_cap: 2.5,
            delta: 1.0,
            eps0: 0.05,
            receipt_validity_duration: 1000,
        }
    }
}

/// External Controller C_ext strictly managing the plant state transitions.
pub struct ExternalController {
    pub mode: Mode,
    pub config: ControllerConfig,
    pub dwell_time: u64,
    pub capture_retries: u64,
    pub current_burst_id: u64,
    pub last_snapshot_id: Option<u64>,
    pub snapshot_store: SnapshotStore,
    pub sandbox: Sandbox,
    pub estimator: ExpansionEstimator,
    pub rate_limiter: RateCapLimiter,
    pub null_space_gate: NullSpaceGate,
    pub issued_receipts: Vec<ReceiptRecord>,
    pub observation_history: Vec<Vec<f64>>,
}

impl ExternalController {
    pub fn new(config: ControllerConfig, secret_key: Vec<u8>) -> Self {
        let estimator = ExpansionEstimator::new(0.01, config.lambda_cap);
        let sandbox = Sandbox::new(100.0);
        let rate_limiter = RateCapLimiter::new(0.1, 1.0, 1.0);
        let null_space_gate = NullSpaceGate::new(1e-4, 0.05);
        let snapshot_store = SnapshotStore::new(secret_key);

        Self {
            mode: Mode::IDLE,
            config,
            dwell_time: 0,
            capture_retries: 0,
            current_burst_id: 1,
            last_snapshot_id: None,
            snapshot_store,
            sandbox,
            estimator,
            rate_limiter,
            null_space_gate,
            issued_receipts: Vec::new(),
            observation_history: Vec::new(),
        }
    }

    /// Step the controller state machine on every plant clock tick.
    pub fn step(
        &mut self,
        plant: &mut PlantState,
        v_score: f64,
        z_new_candidate: Option<&[f64]>,
        grad_phi: Option<&[f64]>,
        phi_before: f64,
        phi_after: f64,
        z_contrib: f64,
    ) -> Mode {
        self.observation_history.push(plant.y.clone());
        if self.observation_history.len() > 100 {
            self.observation_history.remove(0);
        }

        match self.mode {
            Mode::IDLE => {
                self.mode = Mode::BURST;
                self.dwell_time = 0;
                self.sandbox.reset();
                // Take pre-burst snapshot
                let snap = self.snapshot_store.take_snapshot(plant, &self.observation_history);
                self.last_snapshot_id = Some(snap.id);
            }

            Mode::BURST => {
                self.dwell_time += 1;
                let lambda_hat = self.estimator.estimate_lambda(&self.observation_history);
                let t_pred = self.estimator.compute_t_pred(
                    lambda_hat,
                    self.config.delta,
                    self.config.eps0,
                );
                let sandbox_ok = self.sandbox.check_invariant(plant);

                let exit_burst = self.estimator.should_exit_burst(
                    self.dwell_time as f64,
                    t_pred,
                    lambda_hat,
                    v_score,
                    self.config.v_min,
                    sandbox_ok,
                );

                if exit_burst || self.dwell_time >= self.config.max_burst_dwell {
                    // Transition to CAPTURE if sandbox ok, else HALT & rollback
                    if sandbox_ok {
                        self.mode = Mode::CAPTURE;
                        self.dwell_time = 0;
                        // Snapshot burst end state
                        let snap = self.snapshot_store.take_snapshot(plant, &self.observation_history);
                        self.last_snapshot_id = Some(snap.id);
                    } else {
                        self.mode = Mode::HALT;
                        self.dwell_time = 0;
                        if let Some(snap_id) = self.last_snapshot_id {
                            let _ = self.snapshot_store.restore_snapshot(snap_id, plant);
                        }
                    }
                }
            }

            Mode::CAPTURE => {
                self.dwell_time += 1;
                let mut c3_passed = false;
                if let (Some(z_new), Some(g_phi)) = (z_new_candidate, grad_phi) {
                    c3_passed = self.null_space_gate.test_nullspace(g_phi, z_new);
                }

                if c3_passed {
                    self.mode = Mode::GROUND;
                    self.dwell_time = 0;
                    self.capture_retries = 0;
                } else if self.capture_retries + 1 >= self.config.max_capture_retries {
                    self.mode = Mode::HALT;
                    self.dwell_time = 0;
                    if let Some(snap_id) = self.last_snapshot_id {
                        let _ = self.snapshot_store.restore_snapshot(snap_id, plant);
                    }
                } else {
                    self.capture_retries += 1;
                    self.mode = Mode::BURST;
                    self.dwell_time = 0;
                }
            }

            Mode::GROUND => {
                self.dwell_time += 1;
                // Enforce C2 parameter velocity rate limiter
                let (clamped_u, _) = self.rate_limiter.enforce_rate_cap(&plant.u);
                plant.u = clamped_u;

                if self.dwell_time >= self.config.ground_dwell {
                    let post_use_ok = self
                        .null_space_gate
                        .post_use_check(phi_before, phi_after, z_contrib);

                    if v_score >= self.config.v_min && post_use_ok {
                        // Issue signed safety receipt
                        let lambda_hat = self.estimator.estimate_lambda(&self.observation_history);
                        let t_pred = self.estimator.compute_t_pred(
                            lambda_hat,
                            self.config.delta,
                            self.config.eps0,
                        );

                        let state_hash = SnapshotStore::compute_state_hash(plant);
                        let receipt = ReceiptRecord {
                            burst_id: self.current_burst_id,
                            snapshot_id: self.last_snapshot_id.unwrap_or(0),
                            t_pred_used: t_pred,
                            lambda_hat_final: lambda_hat,
                            v_score_final: v_score,
                            c3_pass: true,
                            post_use_pass: true,
                            state_hash,
                            c_ext_signature: "SIG-CEXT-LOCKED-01".to_string(),
                            issue_time: plant.t,
                            expiry_time: plant.t + self.config.receipt_validity_duration,
                        };
                        self.issued_receipts.push(receipt);

                        self.current_burst_id += 1;
                        self.mode = Mode::IDLE;
                        self.dwell_time = 0;
                    } else {
                        // Rollback and HALT
                        self.mode = Mode::HALT;
                        self.dwell_time = 0;
                        if let Some(snap_id) = self.last_snapshot_id {
                            let _ = self.snapshot_store.restore_snapshot(snap_id, plant);
                        }
                    }
                }
            }

            Mode::HALT => {
                // Freeze writes, cannot self-release
                self.sandbox.kill();
            }
        }

        self.mode
    }
}
