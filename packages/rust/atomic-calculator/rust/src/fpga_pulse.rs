//! FPGA Pulse Calibration Layer
//!
//! Handles real-time hardware pulse orchestration for the QCFI loop.
//! Bound to Infleqtion (^133Cs, d=16) backend to allocate F=7/2 auxiliary manifolds.

use crate::ma_vqe_compiler::QuditGate;
use crate::hsec::HsecProtocol;
use crate::qcfi::adjust_dimension;
use crate::bounds::SCALE;

/// Represents a physical microwave pulse dispatched to the FPGA controller.
#[derive(Debug, Clone, PartialEq)]
pub struct MicrowavePulse {
    pub frequency_mhz: f64,
    pub duration_ns: u64,
    pub phase_rad: f64,
    pub target_qudit: usize,
}

/// Maximum concurrent QaaS sessions supported by the hardware envelope.
pub const MAX_CONCURRENT_SESSIONS: usize = 100;
/// Maximum aggregate FPGA utilization threshold.
pub const MAX_AGGREGATE_UTILIZATION: f64 = 0.90;
/// Minimum required ratio of native d=16 sessions.
pub const MIN_NATIVE_D16_RATIO: f64 = 0.80;

/// Represents the FPGA Edge Node orchestrator with multiplexing capability.
pub struct FpgaOrchestrator {
    pub max_dimension: u64,
    /// Tracks independent dimensions for up to 100 concurrent QCFI loops
    pub concurrent_dimensions: std::collections::HashMap<usize, u64>,
    /// Tracks pulse execution load per session
    pub session_loads: std::collections::HashMap<usize, f64>,
}

impl Default for FpgaOrchestrator {
    fn default() -> Self {
        Self {
            max_dimension: 16, // ^133Cs
            concurrent_dimensions: std::collections::HashMap::new(),
            session_loads: std::collections::HashMap::new(),
        }
    }
}

impl FpgaOrchestrator {
    /// Initializes a new session for a concurrent request under strict concurrency bounds
    pub fn init_session(&mut self, session_id: usize) -> Result<(), &'static str> {
        if self.concurrent_dimensions.len() >= MAX_CONCURRENT_SESSIONS {
            return Err("Concurrency limit reached: Maximum 100 concurrent sessions allowed.");
        }
        if self.aggregate_utilization() >= MAX_AGGREGATE_UTILIZATION {
            return Err("FPGA overload: Aggregate utilization exceeds 90% threshold.");
        }
        self.concurrent_dimensions.insert(session_id, self.max_dimension);
        self.session_loads.insert(session_id, 0.008); // Baseline allocation (~0.8% per session)
        Ok(())
    }

    /// Terminates a session and reclaims resources
    pub fn close_session(&mut self, session_id: usize) {
        self.concurrent_dimensions.remove(&session_id);
        self.session_loads.remove(&session_id);
    }

    /// Computes the ratio of sessions operating at native d=16
    pub fn native_d16_ratio(&self) -> f64 {
        if self.concurrent_dimensions.is_empty() {
            return 1.0;
        }
        let d16_count = self.concurrent_dimensions.values().filter(|&&d| d == 16).count();
        d16_count as f64 / self.concurrent_dimensions.len() as f64
    }

    /// Computes the aggregate FPGA core utilization across all active multiplexed sessions
    pub fn aggregate_utilization(&self) -> f64 {
        self.session_loads.values().sum::<f64>().min(1.0)
    }

    /// Multiplexed load balancer: adjusts session dimension to protect aggregate thermal window
    pub fn balance_load(&mut self) {
        if self.aggregate_utilization() > 0.85 && self.native_d16_ratio() > MIN_NATIVE_D16_RATIO {
            // Pre-emptively downscale the lowest-priority active session from d=16 to d=8 to avoid breach
            let candidate = self.concurrent_dimensions.iter()
                .filter(|(_, &d)| d == 16)
                .map(|(&id, _)| id)
                .max();
            if let Some(sess_id) = candidate {
                self.concurrent_dimensions.insert(sess_id, 8);
                if let Some(load) = self.session_loads.get_mut(&sess_id) {
                    *load *= 0.6; // 40% reduction in pulse workload
                }
            }
        }
    }

    /// Dispatches a logical MA-VQE circuit into physical microwave pulses on the FPGA.
    pub fn dispatch_circuit(&mut self, circuit: &[QuditGate]) -> Vec<MicrowavePulse> {
        let mut pulses = Vec::new();
        
        for gate in circuit {
            match gate {
                QuditGate::Z(idx) => {
                    pulses.push(MicrowavePulse {
                        frequency_mhz: 0.0, // Virtual Z
                        duration_ns: 0,
                        phase_rad: std::f64::consts::PI,
                        target_qudit: *idx,
                    });
                }
                QuditGate::Rx(theta, idx) => {
                    pulses.push(MicrowavePulse {
                        frequency_mhz: 4500.0, // ^133Cs microwave transition placeholder
                        duration_ns: (theta * 100.0) as u64, // Scaled duration
                        phase_rad: 0.0,
                        target_qudit: *idx,
                    });
                }
            }
        }
        
        pulses
    }

    /// Real-time QCFI Feedback Loop
    /// Binds hardware errors to the Thermodynamic Window per session
    pub fn run_qcfi_feedback_loop(&mut self, session_id: usize, hardware_error_rate: f64) {
        let eps_scaled = (hardware_error_rate * (SCALE as f64)) as u64;
        if let Some(current_dim) = self.concurrent_dimensions.get(&session_id).copied() {
            let new_dim = adjust_dimension(eps_scaled, current_dim, self.max_dimension);
            self.concurrent_dimensions.insert(session_id, new_dim);
        }
    }
    
    /// HSEC Native Calibration on F=7/2
    pub fn calibrate_hsec_manifold(&self, s_rho_measured: f64) -> Result<(), &'static str> {
        let s_rho_scaled = (s_rho_measured * (SCALE as f64)) as u64;
        if HsecProtocol::can_error_correct(s_rho_scaled) {
            Ok(())
        } else {
            Err("HSEC Calibration Failed: Entropy threshold exceeded.")
        }
    }
}
