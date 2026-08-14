use crate::spectral::SpectralGovernor;
use crate::types::PirtmModulus;

pub struct MlirEmitter {
    pub epsilon: f64,
    pub confidence: f64,
    pub op_norm_t: f64,
    pub modulus: PirtmModulus,
}

pub const UNRESOLVED_COUPLING: &str = "#pirtm.unresolved_coupling";

impl MlirEmitter {
    pub fn new(modulus: PirtmModulus, epsilon: f64) -> Self {
        Self {
            modulus,
            epsilon,
            confidence: 0.9999,
            op_norm_t: 1.0,
        }
    }

    pub fn emit_module(&self, name: &str, identity_commitment: &str, body: &str) -> String {
        let mod_val = self.modulus.value();
        format!(
            r#"module @{} {{
  pirtm.module {{ 
    prime_index = {} : i64, 
    epsilon = {:.4} : f64, 
    op_norm_T = {:.4} : f64, 
    identity_commitment = "{}" 
  }} {{
{}
  }}
}}"#,
            name, mod_val, self.epsilon, self.op_norm_t, identity_commitment, body
        )
    }

    pub fn emit_proof(&self, proof_hash: &str) -> String {
        let mod_val = self.modulus.value();
        format!(
            "  pirtm.proof {{ prime_index = {} : i64, epsilon = {:.4} : f64, op_norm_T = {:.4} : f64, proof_hash = \"{}\" }}",
            mod_val, self.epsilon, self.op_norm_t, proof_hash
        )
    }

    pub fn emit_recurrence(&self) -> String {
        r#"    func.func @pirtm_recurrence(
      %X_t: tensor<?xf64>,
      %Xi_t: tensor<?x?xf64>,
      %Lambda_t: tensor<?x?xf64>,
      %G_t: tensor<?xf64>
    ) -> tensor<?xf64> {
      %T_X_t = "pirtm.sigmoid"(%X_t) : (tensor<?xf64>) -> tensor<?xf64>
      %term1 = "linalg.matvec"(%Xi_t, %X_t) : (tensor<?x?xf64>, tensor<?xf64>) -> tensor<?xf64>
      %term2 = "linalg.matvec"(%Lambda_t, %T_X_t) : (tensor<?x?xf64>, tensor<?xf64>) -> tensor<?xf64>
      %Y_t = "linalg.add"(%term1, %term2) : (tensor<?xf64>, tensor<?xf64>) -> tensor<?xf64>
      %Y_plus_G = "linalg.add"(%Y_t, %G_t) : (tensor<?xf64>, tensor<?xf64>) -> tensor<?xf64>
      %X_next = "pirtm.clip"(%Y_plus_G) { bound_low = -1.0 : f64, bound_high = 1.0 : f64 } : (tensor<?xf64>) -> tensor<?xf64>
      return %X_next : tensor<?xf64>
    }"#.to_string()
    }

    pub fn emit_merge(&self, lhs_mod: u64, rhs_mod: u64) -> Result<String, String> {
        let gcd = num_integer::gcd(lhs_mod, rhs_mod);
        if gcd != 1 {
            return Err(format!(
                "Cannot merge: {} and {} are not coprime (gcd = {})",
                lhs_mod, rhs_mod, gcd
            ));
        }
        let merged_mod = lhs_mod * rhs_mod;

        crate::types::SquarefreeComposite::new(merged_mod)?;

        let lhs_type = if num_prime::nt_funcs::is_prime(&lhs_mod, None).probably() {
            format!("!pirtm.tensor<mod={}>", lhs_mod)
        } else {
            crate::types::SquarefreeComposite::new(lhs_mod)?;
            format!("!pirtm.ctensor<mod={}>", lhs_mod)
        };

        let rhs_type = if num_prime::nt_funcs::is_prime(&rhs_mod, None).probably() {
            format!("!pirtm.tensor<mod={}>", rhs_mod)
        } else {
            crate::types::SquarefreeComposite::new(rhs_mod)?;
            format!("!pirtm.ctensor<mod={}>", rhs_mod)
        };

        Ok(format!(
            "    %merged = \"pirtm.merge\"(%lhs, %rhs) : ({}, {}) -> !pirtm.ctensor<mod={}>",
            lhs_type, rhs_type, merged_mod
        ))
    }

    pub fn emit_session_graph(
        &self,
        prime_index: u64,
        gain_matrix_attr: &str,
        spectral_radius: Option<f64>,
    ) -> Result<String, String> {
        let radius_str = match spectral_radius {
            Some(r) => format!("{:.4}", r),
            None => "1.0000".to_string(),
        };
        let margin_str = match spectral_radius {
            Some(r) => format!("{:.4}", (1.0 - r).max(0.0)),
            None => "0.0000".to_string(),
        };

        Ok(format!(
            "  pirtm.session_graph {{ prime_index = {} : i64, gain_matrix = {}, spectral_radius = {} : f64, stability_margin = {} : f64 }}",
            prime_index, gain_matrix_attr, radius_str, margin_str
        ))
    }

    pub fn emit_session_graph_with_matrix(
        &self,
        prime_index: u64,
        gain_matrix: &[Vec<f64>],
        tier: usize,
    ) -> Result<String, String> {
        let metrics = SpectralGovernor::evaluate_stability(gain_matrix, tier)
            .map_err(|e| format!("Spectral analysis failed: {}", e))?;

        let gain_attr = format!("#pirtm.resolved_coupling(dim={})", gain_matrix.len());
        let radius_str = format!("{:.4}", metrics.spectral_radius);
        let margin_str = format!("{:.4}", metrics.contraction_margin);
        let convergence_rate_str = format!("{:.4}", metrics.convergence_rate);
        let effective_iters_str = format!("{}", metrics.effective_iterations);

        Ok(format!(
            "  pirtm.session_graph {{ prime_index = {} : i64, gain_matrix = {}, spectral_radius = {} : f64, stability_margin = {} : f64, convergence_rate = {} : f64, effective_iterations = {} : i32, tier = {} : i32 }}",
            prime_index, gain_attr, radius_str, margin_str, convergence_rate_str, effective_iters_str, tier
        ))
    }
}
