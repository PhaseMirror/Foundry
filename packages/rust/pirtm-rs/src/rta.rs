// src/rta.rs
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone)]
pub struct State {
    pub active_primes: HashSet<u64>,
    pub joint_words: HashMap<(u64, u64), f64>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            active_primes: HashSet::new(),
            joint_words: HashMap::new(),
        }
    }
}

impl State {
    pub fn new() -> Self { Self::default() }
    pub fn fit(&mut self, _learning_rate: f64, _tolerance: f64) {}
    pub fn arta_defect(&self) -> f64 { 0.0 }
}

pub struct RtaMetric;
