//! Modal Logic & Kripke Frames Module

/// Kripke Frame (W, R, V) with finite worlds.
#[derive(Debug, Clone)]
pub struct KripkeFrame {
    pub num_worlds: usize,
    pub accessibility: Vec<Vec<bool>>, // R[w][v] = true if w can access v
}

impl KripkeFrame {
    pub fn new(num_worlds: usize) -> Self {
        Self {
            num_worlds,
            accessibility: vec![vec![false; num_worlds]; num_worlds],
        }
    }

    pub fn set_accessible(&mut self, from: usize, to: usize) {
        if from < self.num_worlds && to < self.num_worlds {
            self.accessibility[from][to] = true;
        }
    }

    /// Box (Necessity): □ϕ is true at w iff ϕ is true at all reachable worlds v.
    pub fn box_op(&self, world: usize, valuation: &[bool]) -> bool {
        for v in 0..self.num_worlds {
            if self.accessibility[world][v] && !valuation.get(v).cloned().unwrap_or(false) {
                return false;
            }
        }
        true
    }

    /// Diamond (Possibility): ◇ϕ is true at w iff ϕ is true at at least one reachable world v.
    pub fn diamond_op(&self, world: usize, valuation: &[bool]) -> bool {
        for v in 0..self.num_worlds {
            if self.accessibility[world][v] && valuation.get(v).cloned().unwrap_or(false) {
                return true;
            }
        }
        false
    }
}
