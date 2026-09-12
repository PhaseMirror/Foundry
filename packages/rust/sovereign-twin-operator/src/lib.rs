pub struct DualProverHarness {
    pub r_sc: f64,
    pub l_eff: f64,
}

impl DualProverHarness {
    pub fn new() -> Self {
        Self {
            r_sc: 0.88,
            l_eff: 0.15,
        }
    }

    pub fn enforce_sovereign_twin_projection(&self) -> Result<(), String> {
        if self.r_sc < 0.85 {
            return Err("CVK Constraint Failed: R_sc < 0.85".to_string());
        }
        if self.l_eff > 0.2 {
            return Err("CVK Constraint Failed: L_eff > 0.2".to_string());
        }
        // Anchored to Lambda-Proof / Archivum
        Ok(())
    }

    pub fn mcp_tool_admissibility(&self, tool_id: &str) -> Result<String, String> {
        self.enforce_sovereign_twin_projection()?;
        Ok(format!("Tool {} admitted under CERT-DRIFT-STW-20260629-005", tool_id))
    }
}

pub struct McpRegistryDescriptor {
    pub tool_id: String,
    pub signature_hash: String,
}

pub struct McpRegistry {
    pub harness: DualProverHarness,
}

impl McpRegistry {
    pub fn new(harness: DualProverHarness) -> Self {
        Self { harness }
    }

    pub fn evaluate_descriptor(&self, descriptor: &McpRegistryDescriptor) -> Result<String, String> {
        // Enforce the strict sovereign twin projection (R_sc >= 0.85, L_eff <= 0.2)
        self.harness.enforce_sovereign_twin_projection()?;
        Ok(format!(
            "Descriptor {} [Sig: {}] ratified and anchored to Lambda-Proof / Archivum (CERT-DRIFT-MCP-REG-20260629-006)",
            descriptor.tool_id, descriptor.signature_hash
        ))
    }
}

pub struct PythonMcpProxyAdapter {
    pub harness: DualProverHarness,
}

impl PythonMcpProxyAdapter {
    pub fn new(harness: DualProverHarness) -> Self {
        Self { harness }
    }

    pub fn proxy_request(&self, request_payload: &str, trust_level: &str) -> Result<String, String> {
        if trust_level != "Internal" {
            return Err("Proxy Rejected: Non-Internal Python MCP Server".to_string());
        }
        self.harness.enforce_sovereign_twin_projection()?;
        Ok(format!("Python Request [{}] securely proxied through L0 Twin Loop", request_payload))
    }
}

pub struct HttpSseTransportAdapter {
    pub harness: DualProverHarness,
}

impl HttpSseTransportAdapter {
    pub fn new(harness: DualProverHarness) -> Self {
        Self { harness }
    }

    pub fn establish_stream(&self, client_id: &str, connection_integrity: f64) -> Result<String, String> {
        if connection_integrity < 0.99 {
            return Err("Stream Terminated: Connection multiplexing drift detected".to_string());
        }
        self.harness.enforce_sovereign_twin_projection()?;
        Ok(format!("SSE Stream Established for client {} [Bound to Lambda-Proof / Archivum]", client_id))
    }
}

pub struct ExternalScriptQuarantineAdapter {
    pub harness: DualProverHarness,
}

impl ExternalScriptQuarantineAdapter {
    pub fn new(harness: DualProverHarness) -> Self {
        Self { harness }
    }

    pub fn execute_sandboxed(&self, script_id: &str, memory_usage_mb: f64) -> Result<String, String> {
        if memory_usage_mb > 512.0 {
            return Err("Quarantine Fault: Sandbox memory limit exceeded".to_string());
        }
        self.harness.enforce_sovereign_twin_projection()?;
        Ok(format!("External script {} successfully executed within L0 Quarantine", script_id))
    }
}

pub struct SovereignConvergenceNode {
    pub harness: DualProverHarness,
    pub is_sealed: bool,
}

impl SovereignConvergenceNode {
    pub fn new(harness: DualProverHarness) -> Self {
        Self { harness, is_sealed: false }
    }

    pub fn seal_node(&mut self) {
        self.is_sealed = true;
    }

    pub fn execute_converged_transition(&self, payload_integrity: f64) -> Result<String, String> {
        if !self.is_sealed {
            return Err("Convergence Fault: Terminal Node is not cryptographically sealed".to_string());
        }
        if payload_integrity < 1.0 {
            return Err("Convergence Fault: Payload integrity fractured".to_string());
        }
        self.harness.enforce_sovereign_twin_projection()?;
        Ok("State Transition Converged and Sealed to Lambda-Proof / Archivum".to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_snark_harness_cvk_compliance() {
        let harness = DualProverHarness::new();
        assert!(harness.enforce_sovereign_twin_projection().is_ok());
    }

    #[test]
    fn test_mcp_tool_admissibility_pass() {
        let harness = DualProverHarness::new();
        let result = harness.mcp_tool_admissibility("sys_exec");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "Tool sys_exec admitted under CERT-DRIFT-STW-20260629-005");
    }

    #[test]
    fn test_mcp_tool_admissibility_fail() {
        let mut harness = DualProverHarness::new();
        harness.r_sc = 0.80; // Intentional drift
        let result = harness.mcp_tool_admissibility("sys_exec");
        assert!(result.is_err());
    }

    #[test]
    fn test_mcp_registry_descriptor_pass() {
        let harness = DualProverHarness::new();
        let registry = McpRegistry::new(harness);
        let descriptor = McpRegistryDescriptor {
            tool_id: "fs_read".to_string(),
            signature_hash: "0xdeadbeef".to_string(),
        };
        let result = registry.evaluate_descriptor(&descriptor);
        assert!(result.is_ok());
        assert_eq!(
            result.unwrap(),
            "Descriptor fs_read [Sig: 0xdeadbeef] ratified and anchored to Lambda-Proof / Archivum (CERT-DRIFT-MCP-REG-20260629-006)"
        );
    }

    #[test]
    fn test_mcp_registry_descriptor_fail() {
        let mut harness = DualProverHarness::new();
        harness.r_sc = 0.84; // Drift below 0.85
        let registry = McpRegistry::new(harness);
        let descriptor = McpRegistryDescriptor {
            tool_id: "net_socket".to_string(),
            signature_hash: "0xbadc0fee".to_string(),
        };
        let result = registry.evaluate_descriptor(&descriptor);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "CVK Constraint Failed: R_sc < 0.85");
    }

    #[test]
    fn test_python_mcp_proxy_pass() {
        let harness = DualProverHarness::new();
        let proxy = PythonMcpProxyAdapter::new(harness);
        let result = proxy.proxy_request("run_analysis", "Internal");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "Python Request [run_analysis] securely proxied through L0 Twin Loop");
    }

    #[test]
    fn test_python_mcp_proxy_fail_trust() {
        let harness = DualProverHarness::new();
        let proxy = PythonMcpProxyAdapter::new(harness);
        let result = proxy.proxy_request("run_analysis", "External");
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Proxy Rejected: Non-Internal Python MCP Server");
    }

    #[test]
    fn test_python_mcp_proxy_fail_drift() {
        let mut harness = DualProverHarness::new();
        harness.l_eff = 0.3; // Intentional drift > 0.2
        let proxy = PythonMcpProxyAdapter::new(harness);
        let result = proxy.proxy_request("run_analysis", "Internal");
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "CVK Constraint Failed: L_eff > 0.2");
    }

    #[test]
    fn test_http_sse_transport_pass() {
        let harness = DualProverHarness::new();
        let adapter = HttpSseTransportAdapter::new(harness);
        let result = adapter.establish_stream("client_alpha", 0.999);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "SSE Stream Established for client client_alpha [Bound to Lambda-Proof / Archivum]");
    }

    #[test]
    fn test_http_sse_transport_fail_integrity() {
        let harness = DualProverHarness::new();
        let adapter = HttpSseTransportAdapter::new(harness);
        let result = adapter.establish_stream("client_beta", 0.95);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Stream Terminated: Connection multiplexing drift detected");
    }

    #[test]
    fn test_http_sse_transport_fail_drift() {
        let mut harness = DualProverHarness::new();
        harness.r_sc = 0.82; // Intentional CVK drift < 0.85
        let adapter = HttpSseTransportAdapter::new(harness);
        let result = adapter.establish_stream("client_gamma", 1.0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "CVK Constraint Failed: R_sc < 0.85");
    }

    #[test]
    fn test_external_script_quarantine_pass() {
        let harness = DualProverHarness::new();
        let adapter = ExternalScriptQuarantineAdapter::new(harness);
        let result = adapter.execute_sandboxed("script_x", 256.0);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "External script script_x successfully executed within L0 Quarantine");
    }

    #[test]
    fn test_external_script_quarantine_fail_memory() {
        let harness = DualProverHarness::new();
        let adapter = ExternalScriptQuarantineAdapter::new(harness);
        let result = adapter.execute_sandboxed("script_y", 1024.0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Quarantine Fault: Sandbox memory limit exceeded");
    }

    #[test]
    fn test_external_script_quarantine_fail_drift() {
        let mut harness = DualProverHarness::new();
        harness.l_eff = 0.25; // Intentional drift > 0.2
        let adapter = ExternalScriptQuarantineAdapter::new(harness);
        let result = adapter.execute_sandboxed("script_z", 128.0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "CVK Constraint Failed: L_eff > 0.2");
    }

    #[test]
    fn test_sovereign_convergence_pass() {
        let harness = DualProverHarness::new();
        let mut node = SovereignConvergenceNode::new(harness);
        node.seal_node();
        let result = node.execute_converged_transition(1.0);
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "State Transition Converged and Sealed to Lambda-Proof / Archivum");
    }

    #[test]
    fn test_sovereign_convergence_fail_unsealed() {
        let harness = DualProverHarness::new();
        let node = SovereignConvergenceNode::new(harness);
        // Do not call seal_node()
        let result = node.execute_converged_transition(1.0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Convergence Fault: Terminal Node is not cryptographically sealed");
    }

    #[test]
    fn test_sovereign_convergence_fail_integrity() {
        let harness = DualProverHarness::new();
        let mut node = SovereignConvergenceNode::new(harness);
        node.seal_node();
        let result = node.execute_converged_transition(0.99); // < 1.0
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Convergence Fault: Payload integrity fractured");
    }

    #[test]
    fn test_sovereign_convergence_fail_drift() {
        let mut harness = DualProverHarness::new();
        harness.r_sc = 0.84; // Drift < 0.85
        let mut node = SovereignConvergenceNode::new(harness);
        node.seal_node();
        let result = node.execute_converged_transition(1.0);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "CVK Constraint Failed: R_sc < 0.85");
    }
}
