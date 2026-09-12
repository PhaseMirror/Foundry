use crate::types::StepInfo;

use std::collections::VecDeque;

pub struct CSLGate {
    pub min_residual: f64,
    pub max_q: f64,
}

impl CSLGate {
    pub fn new(max_q: f64) -> Self {
        Self {
            min_residual: 1e-9,
            max_q,
        }
    }

    pub fn check(&self, info: &StepInfo) -> bool {
        // CSL Gate check: must be contractive and moving
        info.q <= self.max_q && info.residual > self.min_residual
    }
}

pub struct RateLimiter {
    pub window_size: usize,
    pub max_growth: f64,
    history: VecDeque<f64>,
}

impl RateLimiter {
    pub fn new(window_size: usize, max_growth: f64) -> Self {
        Self {
            window_size,
            max_growth,
            history: VecDeque::with_capacity(window_size),
        }
    }

    pub fn push(&mut self, norm: f64) -> bool {
        if self.history.len() >= self.window_size {
            self.history.pop_front();
        }

        let ok = if let Some(&prev) = self.history.back() {
            if prev > 0.0 {
                (norm / prev) <= self.max_growth
            } else {
                norm <= self.max_growth
            }
        } else {
            true
        };

        self.history.push_back(norm);
        ok
    }
}

pub struct ProtectedEngine<E> {
    _engine: std::marker::PhantomData<E>,
    pub gate: CSLGate,
    pub rate_limiter: RateLimiter,
}

impl<E> ProtectedEngine<E> {
    pub fn new(_engine: E, max_q: f64) -> Self {
        Self {
            _engine: std::marker::PhantomData,
            gate: CSLGate::new(max_q),
            rate_limiter: RateLimiter::new(10, 1.1), // 10% max growth per step
        }
    }
}
