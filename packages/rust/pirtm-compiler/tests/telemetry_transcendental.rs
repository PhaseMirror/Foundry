use pirtm_parser::ast::{Expr, BinOp};

// Mock definition of WardMonitor for tests
pub struct WardMonitor {
    pub current_drift: f64,
    pub max_drift: f64,
    pub threshold: f64,
}

impl WardMonitor {
    pub fn new() -> Self {
        Self {
            current_drift: 0.0,
            max_drift: 0.0,
            threshold: 0.85, // ANOMALY_GOV_THRESHOLD warning limit
        }
    }

    pub fn process_expression(&mut self, expr: &Expr) {
        match expr {
            Expr::Sin(_) | Expr::Cos(_) => {
                // Trigonometric functions introduce small oscillating drift
                self.current_drift += 0.0001; 
            }
            Expr::Log(_) => {
                // Logarithmic singularities could introduce higher tension
                self.current_drift += 0.005;
            }
            Expr::Binary { left, right, .. } => {
                self.process_expression(left);
                self.process_expression(right);
            }
            _ => {}
        }
        if self.current_drift > self.max_drift {
            self.max_drift = self.current_drift;
        }
    }
}

#[test]
fn test_transcendental_ops_respect_drift_thresholds() {
    let mut monitor = WardMonitor::new();
    
    // Construct a dense computation with transcendentals
    let expr1 = Expr::Sin(Box::new(Expr::Literal(10)));
    let expr2 = Expr::Cos(Box::new(Expr::Literal(5)));
    let log_expr = Expr::Log(Box::new(Expr::Literal(100)));
    
    let combined = Expr::Binary {
        op: BinOp::Add,
        left: Box::new(Expr::Binary {
            op: BinOp::Add,
            left: Box::new(expr1),
            right: Box::new(expr2),
        }),
        right: Box::new(log_expr),
    };
    
    // Run the monitor
    for _ in 0..100 { // Simulate 100 recursive tensor cycles
        monitor.process_expression(&combined);
    }
    
    // Ensure the drift hasn't tripped the ANOMALY_GOV_THRESHOLD
    assert!(monitor.max_drift < monitor.threshold, "Drift exceeded anomaly threshold! Max drift: {}", monitor.max_drift);
    assert!(monitor.max_drift > 0.0, "No drift registered, monitor is dead.");
}
