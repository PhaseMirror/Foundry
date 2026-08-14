use ndarray::Array1;

pub struct MetaEnsemble {
    pub ensembles: Vec<Array1<f64>>,
    pub mu: f64, // Binding Multiplicity
}

impl MetaEnsemble {
    pub fn new(ensembles: Vec<Array1<f64>>) -> Self {
        let mu = calculate_binding_multiplicity(&ensembles);
        MetaEnsemble { ensembles, mu }
    }

    /// Categorical Folding: Aggregate ensembles into a single meta-ensemble state.
    /// This constructs the meta-ensemble through a simplified colimit-like aggregation.
    /// Weighted Categorical Folding: Aggregate ensembles with specific weights.
    /// This reflects the 'Mixture Nonexpansiveness' property in the formal proofs.
    pub fn weighted_fold(&self, weights: &[f64]) -> Array1<f64> {
        if self.ensembles.is_empty() || weights.len() != self.ensembles.len() {
            return Array1::zeros(0);
        }
        
        let mut folded = Array1::zeros(self.ensembles[0].raw_dim());
        let weight_sum: f64 = weights.iter().sum();
        
        for (i, ensemble) in self.ensembles.iter().enumerate() {
            folded = folded + (ensemble * (weights[i] / weight_sum));
        }
        
        folded
    }
}

/// Binding Multiplicity (μ):
/// Quantifies the "points of contact" or overlaps between distinct structures.
fn calculate_binding_multiplicity(ensembles: &[Array1<f64>]) -> f64 {
    if ensembles.len() < 2 {
        return 1.0;
    }
    
    let mut total_overlap = 0.0;
    let mut pairs = 0;
    
    for i in 0..ensembles.len() {
        for j in i+1..ensembles.len() {
            let dot = ensembles[i].dot(&ensembles[j]);
            let norm_i = ensembles[i].dot(&ensembles[i]).sqrt();
            let norm_j = ensembles[j].dot(&ensembles[j]).sqrt();
            if norm_i > 0.0 && norm_j > 0.0 {
                total_overlap += dot / (norm_i * norm_j);
            }
            pairs += 1;
        }
    }
    
    if pairs == 0 { 1.0 } else { total_overlap / (pairs as f64) }
}
