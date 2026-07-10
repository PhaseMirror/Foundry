// prms/src/pipeline.rs  
use std::sync::mpsc::{sync_channel, SyncSender, Receiver};  
use std::thread::{spawn, JoinHandle};  
use crate::dae::{TwoOscillatorEngine, SimulationState, TelemetryFrame};  
use crate::petc::{BytecodeHeader, ProofWitnessVerificationSystem};  
use crate::zeta_ros::{LineageMetrics, ComplianceBudget, AuditEngine};  
use crate::contractor::{MultiplicityContractor, StabilityStatus};

pub struct PipelineConfig {  
    pub channel_capacity: usize,  
    pub dt: f64,  
    pub steps: usize,  
}

pub struct AuditFailurePayload {  
    pub step: usize,  
    pub timestamp: f64,  
    pub diagnostic_reason: &'static str,  
    pub composite_score: f64,  
}

pub struct OperationalPipeline {  
    config: PipelineConfig,  
    engine: TwoOscillatorEngine,  
    initial_state: SimulationState,  
}

impl OperationalPipeline {  
    pub fn new(config: PipelineConfig, engine: TwoOscillatorEngine, initial_state: SimulationState) -> Self {  
        Self { config, engine, initial_state }  
    }

    pub fn execute_monitored_run(  
        self,  
        header: BytecodeHeader,  
        alpha: f64,  
        prime_table: Vec<u64>,  
        budget: ComplianceBudget,  
        contractor: &MultiplicityContractor,  
        lineage_generator: impl Fn(usize, &TelemetryFrame) -> LineageMetrics + Send + 'static,  
    ) -> Result<Vec<TelemetryFrame>, AuditFailurePayload> {  
          
        let (tx, rx): (SyncSender<TelemetryFrame>, Receiver<TelemetryFrame>) = sync_channel(self.config.channel_capacity);  
        let engine_clone = self.engine;  
        let mut state_tracker = self.initial_state;  
        let total_steps = self.config.steps;  
        let step_size = self.config.dt;

        let simulation_worker: JoinHandle<u32> = spawn(move || {  
            let mut current_time = 0.0;  
            let mut transmitted_frames = 0;  
            for _step in 0..total_steps {  
                let frame = engine_clone.step(&state_tracker, step_size, current_time);  
                state_tracker.q1 = frame.q1;  
                state_tracker.p1 = frame.p1;  
                state_tracker.q2 = frame.q2;  
                state_tracker.p2 = frame.p2;  
                state_tracker.kappa = frame.kappa;  
                current_time = frame.t;

                if tx.send(frame).is_ok() {  
                    transmitted_frames += 1;  
                } else {  
                    break;  
                }  
            }  
            transmitted_frames  
        });

        let expected_hash = ProofWitnessVerificationSystem::compute_provenance_hash(&header, alpha, &prime_table);  
        let mut history_ledger = Vec::with_capacity(self.config.steps);  
        let mut processed_steps = 0;

        while let Ok(frame) = rx.recv() {  
            let runtime_hash = ProofWitnessVerificationSystem::compute_provenance_hash(&header, alpha, &prime_table);  
            let provenance_valid = runtime_hash == expected_hash;

            let current_lineage = lineage_generator(processed_steps, &frame);  
            let (_, _, _, composite_score) = AuditEngine::calculate_lineage_score(&current_lineage);

            // Trigger proactive look-ahead stability logging on Path B  
            match contractor.evaluate_stability(frame.cond_number, budget.max_allowed_cond) {  
                StabilityStatus::Warning => {  
                    println!("[STABILITY WARNING] Step {}: Condition number {} has breached 80% of compliance boundary.", processed_steps, frame.cond_number);  
                }  
                StabilityStatus::CriticalBoundaryViolation => {  
                    drop(rx);  
                    let _ = simulation_worker.join();  
                    return Err(AuditFailurePayload {  
                        step: processed_steps,  
                        timestamp: frame.t,  
                        diagnostic_reason: "FAIL-CLOSED: Look-ahead safety monitor caught a critical bifurcation event.",  
                        composite_score,  
                    });  
                }  
                StabilityStatus::Nominal => {}  
            }

            match AuditEngine::verify_step_lawfulness(&frame, &current_lineage, &budget, provenance_valid) {  
                Ok(_) => {  
                    history_ledger.push(frame);  
                    processed_steps += 1;  
                }  
                Err(failure_message) => {  
                    drop(rx);  
                    let _ = simulation_worker.join();  
                    return Err(AuditFailurePayload {  
                        step: processed_steps,  
                        timestamp: frame.t,  
                        diagnostic_reason: failure_message,  
                        composite_score,  
                    });  
                }  
            }  
        }

        let _ = simulation_worker.join();  
        Ok(history_ledger)  
    }  
}
