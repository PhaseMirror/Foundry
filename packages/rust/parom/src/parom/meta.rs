use nalgebra::DVector;
use crate::vdj::Recombinant;

pub struct MetaEnsemble {
    pub lineages: Vec<Recombinant>,
    pub alpha: Vec<f64>, // Convex weights (sum = 1)
}

impl MetaEnsemble {
    pub fn new(lineages: Vec<Recombinant>) -> Self {
        let n = lineages.len();
        let alpha = if n > 0 {
            vec![1.0 / n as f64; n]
        } else {
            Vec::new()
        };
        Self { lineages, alpha }
    }

    /// Update the convex weights based on a state-dependent gating signal.
    /// In a full implementation, this would be a softmax over immune confidence scores.
    pub fn update_gate(&mut self, scores: &[f64]) {
        if scores.is_empty() { return; }
        
        // Simple Softmax
        let max_score = scores.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b));
        let exps: Vec<f64> = scores.iter().map(|s| (s - max_score).exp()).collect();
        let sum: f64 = exps.iter().sum();
        
        self.alpha = exps.iter().map(|e| e / sum).collect();
    }

    /// Global Meta-Ensemble Update (Certified Recursion)
    /// x_{t+1} = sum alpha_p * Pi_p(x_t)
    pub fn evolve(&self, x: &DVector<f64>) -> DVector<f64> {
        if self.lineages.is_empty() {
            return x.clone();
        }

        let mut composite_next = DVector::zeros(x.len());
        for (i, recombinant) in self.lineages.iter().enumerate() {
            let next_p = recombinant.parom.evolve(x);
            composite_next += next_p * self.alpha[i];
        }
        
        composite_next
    }

    /// Stability Guarantee: Global Lipschitz constant is bounded by max individual lambda.
    pub fn verify_global_stability(&self, trials: usize) -> bool {
        let mut max_l = 0.0;
        for recombinant in &self.lineages {
            let l = recombinant.parom.estimate_lipschitz(trials);
            if l > max_l {
                max_l = l;
            }
        }
        println!("Meta-Ensemble Global Lipschitz Bound: {:.4}", max_l);
        max_l < 1.0
    }
}
