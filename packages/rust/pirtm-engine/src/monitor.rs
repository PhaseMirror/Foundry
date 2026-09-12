use std::sync::atomic::{AtomicU64, Ordering};

use pirtm_monitor::{ManifoldStateProvider, ManifoldState};
use std::time::SystemTime;

/// Runtime state provider that reads from global metric counters.
#[derive(Default)]
pub struct RuntimeStateProvider {
    rho: AtomicU64,
    delta: AtomicU64,
    lambda_l: AtomicU64,
}

impl RuntimeStateProvider {
    pub fn update(&self, rho: f64, delta: f64, lambda_l: f64) {
        self.rho.store(rho.to_bits(), Ordering::Relaxed);
        self.delta.store(delta.to_bits(), Ordering::Relaxed);
        self.lambda_l.store(lambda_l.to_bits(), Ordering::Relaxed);
    }
}

impl ManifoldStateProvider for RuntimeStateProvider {
    fn fetch_state(&self) -> Result<ManifoldState, String> {
        let timestamp = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        Ok(ManifoldState {
            rho: f64::from_bits(self.rho.load(Ordering::Relaxed)),
            delta: f64::from_bits(self.delta.load(Ordering::Relaxed)),
            lambda_l_product: f64::from_bits(self.lambda_l.load(Ordering::Relaxed)),
            timestamp,
        })
    }
}
