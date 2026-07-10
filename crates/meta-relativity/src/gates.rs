//! Implementation of the five validation gates for CEQG-RG-Langevin.
//! 
//! Strictly conforms to MetaRelativityFormalized/Gates.lean

use anyhow::{Result, anyhow};

/// A validation gate for the CEQG-RG-Langevin framework.
pub trait ValidationGate {
    fn name(&self) -> &str;
    fn validate(&self) -> Result<()>;
}

/// Gate 1: Micro-Macro Derivation
pub struct Gate1 {
    pub f_nl: f64,
    pub coupling_strength: f64,
}

impl ValidationGate for Gate1 {
    fn name(&self) -> &str { "Gate 1: Micro-Macro Derivation" }
    fn validate(&self) -> Result<()> {
        if self.f_nl != 0.0 {
            return Err(anyhow!("Gate 1 requires exactly f_nl = 0"));
        }
        if self.coupling_strength > 0.1 {
            return Err(anyhow!("Coupling strength must be <= 0.1"));
        }
        Ok(())
    }
}

/// Gate 2: RG-Prior Justification
pub struct Gate2 {
    pub theta_1: f64,
}

impl ValidationGate for Gate2 {
    fn name(&self) -> &str { "Gate 2: RG-Prior Justification" }
    fn validate(&self) -> Result<()> {
        if (self.theta_1 - 2.0).abs() / 2.0 >= 0.20 {
            return Err(anyhow!("Gate 2 invalid: deviation >= 0.20"));
        }
        Ok(())
    }
}

/// Gate 3: Correlated Smoking Gun
pub struct Gate3 {
    pub c: f64,
    pub n_ng: f64,
    pub s_8: f64,
    pub g_nl_0: f64,
}

impl Gate3 {
    pub fn a(&self) -> f64 {
        1.0 / (self.c * self.n_ng)
    }

    pub fn predict_gnl(&self, delta_s_8: f64) -> f64 {
        self.g_nl_0 * (self.a() * (delta_s_8 / self.s_8)).exp()
    }
}

impl ValidationGate for Gate3 {
    fn name(&self) -> &str { "Gate 3: Correlated Smoking Gun" }
    fn validate(&self) -> Result<()> {
        let a = self.a();
        if a < 200.0 || a > 500.0 {
            return Err(anyhow!("Gate 3 invalid: a = {} not in [200, 500]", a));
        }
        Ok(())
    }
}

/// Gate 4: Truncation Hierarchy
pub struct Gate4 {
    pub beta_lambda_8: f64,
    pub beta_lambda_6: f64,
    pub delta_c_ratio: f64,
}

impl ValidationGate for Gate4 {
    fn name(&self) -> &str { "Gate 4: Truncation Hierarchy" }
    fn validate(&self) -> Result<()> {
        if (self.beta_lambda_8 / self.beta_lambda_6).abs() >= 0.03 {
            return Err(anyhow!("Gate 4 invalid: |beta_lambda_8 / beta_lambda_6| >= 0.03"));
        }
        if self.delta_c_ratio >= 0.04 {
            return Err(anyhow!("Gate 4 invalid: delta_c_ratio >= 0.04"));
        }
        Ok(())
    }
}

/// Gate 5: Complete Causal Chain
pub struct Gate5 {
    pub g1: Gate1,
    pub g2: Gate2,
    pub g3: Gate3,
    pub g4: Gate4,
}

impl ValidationGate for Gate5 {
    fn name(&self) -> &str { "Gate 5: Complete Causal Chain" }
    fn validate(&self) -> Result<()> {
        self.g1.validate()?;
        self.g2.validate()?;
        self.g3.validate()?;
        self.g4.validate()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gate1() {
        let gate = Gate1 { f_nl: 0.0, coupling_strength: 0.05 };
        assert!(gate.validate().is_ok());
    }

    #[test]
    fn test_gate2() {
        let gate = Gate2 { theta_1: 1.8 };
        assert!(gate.validate().is_ok());
    }

    #[test]
    fn test_gate3() {
        let gate = Gate3 { c: 0.2, n_ng: 0.01, s_8: 1.0, g_nl_0: 1.0 };
        assert!(gate.validate().is_ok());
    }

    #[test]
    fn test_gate4() {
        let gate = Gate4 { beta_lambda_8: 0.001, beta_lambda_6: 0.1, delta_c_ratio: 0.02 };
        assert!(gate.validate().is_ok());
    }
}
