use std::collections::VecDeque;

#[derive(Debug, Clone)]
pub struct RateLimiterParams {
    pub r: usize,
    pub n: usize,
    pub delta_target: f64,
    pub delta_0: f64,
}

impl Default for RateLimiterParams {
    fn default() -> Self {
        RateLimiterParams {
            r: 5,
            n: 50,
            delta_target: 0.01,
            delta_0: 1.0,
        }
    }
}

pub struct RateLimiter {
    params: RateLimiterParams,
    window: VecDeque<bool>,
}

impl RateLimiter {
    const GAMMA: f64 = 0.9;

    pub fn new(params: Option<RateLimiterParams>) -> Result<Self, String> {
        let p = params.unwrap_or_default();
        if p.n == 0 {
            return Err("RateLimiter requires n > 0".to_string());
        }
        if p.r >= p.n {
            return Err("RateLimiter requires r < n for bounded liveness".to_string());
        }
        if p.delta_target <= 0.0 || p.delta_0 <= 0.0 {
            return Err("RateLimiter requires delta_target > 0 and delta_0 > 0".to_string());
        }
        Ok(RateLimiter {
            params: p,
            window: VecDeque::with_capacity(50), // Default N
        })
    }

    pub fn allow_step(&self, _t: usize) -> bool {
        self.rollback_count() < self.params.r
    }

    pub fn record(&mut self, was_rollback: bool) {
        if self.window.len() == self.params.n {
            self.window.pop_front();
        }
        self.window.push_back(was_rollback);
    }

    pub fn rollback_count(&self) -> usize {
        self.window.iter().filter(|&&b| b).count()
    }

    pub fn rollback_rate(&self) -> f64 {
        let n = self.window.len();
        if n > 0 {
            self.rollback_count() as f64 / n as f64
        } else {
            0.0
        }
    }

    pub fn convergence_bound(&self) -> usize {
        let rho = self.params.r as f64 / self.params.n as f64;
        let gamma_eff = Self::GAMMA * (1.0 - rho);
        
        let numerator = (self.params.delta_0 / self.params.delta_target).ln();
        let denominator = (1.0 / gamma_eff).ln();
        let base = (numerator / denominator).ceil();
        let liveness = self.params.n as f64 / (self.params.n - self.params.r) as f64;
        (base * liveness).ceil() as usize
    }
}
