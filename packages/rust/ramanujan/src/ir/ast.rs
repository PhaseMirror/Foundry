use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum OperatorType {
    S,
    B,
    H,
    #[serde(rename = "H_INV")]
    HInv,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Operator {
    pub op_type: OperatorType,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub indices: Option<Vec<i32>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sign: Option<i8>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ap_coefficient: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RamanujanBound {
    pub satisfied: bool,
    pub eigenvalue_bound: f64,
    pub support_size: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EichlerShimuraRealization {
    pub level: u32,
    pub weight: u32, // Strictly 2
    pub newform_label: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EtaleRealization {
    pub weight: u32,
    pub purity_bound: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModularAbelianVariety {
    pub newform_label: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cm_field: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Constraints {
    pub sparsity_bound: u32,
    pub ramanujan_bound: RamanujanBound,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deligne_justification: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub etale_realization: Option<EtaleRealization>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eichler_shimura_realization: Option<EichlerShimuraRealization>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub modular_abelian_variety: Option<ModularAbelianVariety>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowManifest {
    pub version: String,
    pub word: Vec<Operator>,
    pub constraints: Constraints,
}
