use tree_sitter::{Node, TreeCursor};
use crate::{PrimeSuccessorPredicate, SigCompiler};

impl SigCompiler {
    /// Walks the AST to rigorously enforce PIRTM routing logic as specified by the ADR.
    pub fn enforce_invariants(&mut self, source: &[u8], root_node: Node) -> Result<(), String> {
        let mut cursor = root_node.walk();
        
        for child in root_node.children(&mut cursor) {
            match child.kind() {
                "tensor_declaration" => self.route_axiomatic_registration(child, source)?,
                "operator_application" => self.route_multiplicity_functor(child, source)?,
                "contractivity_assertion" => self.route_spectral_lock(child, source)?,
                _ => {} // Ignore whitespace or unknown statements in this pass
            }
        }
        
        Ok(())
    }

    fn route_axiomatic_registration(&self, node: Node, source: &[u8]) -> Result<(), String> {
        // Route 1: Axiomatic Registration
        // Registers the tensor and extracts prime_axes
        let target_node = node.child_by_field_name("name").ok_or("Missing tensor name")?;
        let _target_name = target_node.utf8_text(source).map_err(|_| "Invalid UTF-8")?;
        
        // In a full implementation, we'd add this to the compiler's symbol table
        Ok(())
    }

    fn route_multiplicity_functor(&self, node: Node, source: &[u8]) -> Result<(), String> {
        // Route 2: Multiplicity Functor Pipeline
        let target_node = node.child_by_field_name("target").ok_or("Missing operator target")?;
        let _target_name = target_node.utf8_text(source).map_err(|_| "Invalid UTF-8")?;
        
        // Check for scaling factor
        let lambda = node.child_by_field_name("scaling_factor");
        if lambda.is_none() {
            // Strictly speaking, we should warn or error. We'll return an error for strict mode.
            return Err("Warning: Missing \\Lambda_m scaling factor. Unscaled operators risk divergence.".to_string());
        }

        // Iterate over prime_chain
        let chain_node = node.child_by_field_name("prime_chain").ok_or("Missing prime chain")?;
        
        let mut cursor = chain_node.walk();
        let mut primes = Vec::new();
        
        for child in chain_node.children(&mut cursor) {
            if child.kind() == "prime_literal" {
                let p_text = child.utf8_text(source).map_err(|_| "Invalid UTF-8")?;
                // Strip 'p_' and parse
                let p_val: u64 = p_text.trim_start_matches("p_").parse().map_err(|_| "Failed to parse prime literal")?;
                primes.push(p_val);
            }
        }

        if primes.len() >= 2 {
            // The Critical Hand-off: Enforcing Prime Successor transitions
            for window in primes.windows(2) {
                let current = window[0];
                let next = window[1];
                
                let mut predicate = PrimeSuccessorPredicate::new(current, next);
                
                if let Err(e) = predicate.transition(current, next) {
                    // SIG_GOV_KILL trigger
                    return Err(format!("SIG_GOV_KILL: Unlawful Non-Contractive Prime Jump detected between p_{} and p_{}. Trace: {}", current, next, e));
                }
            }
        }
        
        Ok(())
    }

    fn route_spectral_lock(&self, node: Node, source: &[u8]) -> Result<(), String> {
        // Route 3: Spectral Lock
        let target_node = node.child_by_field_name("target").ok_or("Missing assertion target")?;
        let _target_name = target_node.utf8_text(source).map_err(|_| "Invalid UTF-8")?;
        
        let bound_node = node.child_by_field_name("bound").ok_or("Missing bound")?;
        let bound_text = bound_node.utf8_text(source).map_err(|_| "Invalid UTF-8")?;
        let bound_val: f64 = bound_text.parse().map_err(|_| "Failed to parse float bound")?;
        
        if bound_val >= 1.0 {
            return Err("Spectral Lock Failure: L_Phi must be < 1.0".to_string());
        }
        
        Ok(())
    }
}
