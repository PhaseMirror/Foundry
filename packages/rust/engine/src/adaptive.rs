use crate::types::StepInfo;

#[derive(Debug, Clone)]
pub struct AdaptiveMargin {
    pub epsilon: f64,
    pub min_epsilon: f64,
    pub max_epsilon: f64,
    pub step_size: f64,
    pub residual_target: f64,
    pub baseline: f64,
}

impl AdaptiveMargin {
    pub fn new(epsilon: f64) -> Self {
        Self {
            epsilon,
            min_epsilon: 0.01,
            max_epsilon: 0.25,
            step_size: 0.01,
            residual_target: 1e-5,
            baseline: epsilon,
        }
    }

    pub fn update(&mut self, info: &StepInfo) -> f64 {
        let target = 1.0 - self.epsilon;
        let margin = target - info.q;

        if info.q > target {
            self.epsilon = (self.epsilon + self.step_size).min(self.max_epsilon);
        } else if info.residual < self.residual_target && margin > 0.05 {
            let proposed = self.epsilon - self.step_size;
            self.epsilon = proposed.max(self.min_epsilon).max(self.baseline);
        }
        self.epsilon
    }
}
