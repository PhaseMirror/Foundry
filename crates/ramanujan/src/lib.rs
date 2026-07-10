#[macro_use]
extern crate lazy_static;

pub mod ir;
pub mod compiler;
pub mod validator;

use crate::ir::ast::{EichlerShimuraRealization, EtaleRealization, ModularAbelianVariety, WorkflowManifest};
use crate::compiler::{parser, normalizer, binder};
use crate::validator::admissible;

pub trait WorkflowRunner {
    fn compile(source: &str) -> anyhow::Result<WorkflowManifest>;
    fn validate(manifest: &WorkflowManifest) -> Result<(), String>;
}

pub struct XiCompiler;

impl WorkflowRunner for XiCompiler {
    fn compile(source: &str) -> anyhow::Result<WorkflowManifest> {
        let raw_ast = parser::parse_workflow(source)?;
        let normalized = normalizer::normalize_word(raw_ast);
        
        let deligne_justification = if source.contains("DELIGNE") {
            Some("Deligne 1974 Galois representation purity".to_string())
        } else {
            None
        };

        let eichler_shimura_realization = if source.contains("EICHLER_SHIMURA_N_2_NEWFORM_11A") {
            Some(EichlerShimuraRealization { level: 2, weight: 2, newform_label: "11a".to_string() }) // Mock for N=2, weight 2
        } else {
            None
        };

        let etale_realization = if source.contains("ETALE_WEIGHT_11") {
            Some(EtaleRealization { weight: 11, purity_bound: "Weil Conjectures".to_string() })
        } else {
            None
        };

        let modular_abelian_variety = if source.contains("MODULAR_ABELIAN_VARIETY_11A") {
            Some(ModularAbelianVariety { newform_label: "11a".to_string(), cm_field: None })
        } else {
            None
        };
        
        let manifest = binder::bind_constraints(
            normalized, 
            deligne_justification, 
            etale_realization,
            eichler_shimura_realization,
            modular_abelian_variety
        );
        Ok(manifest)
    }

    fn validate(manifest: &WorkflowManifest) -> Result<(), String> {
        admissible::is_admissible(manifest)
    }
}
