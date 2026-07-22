use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct ContractBinding {
    pub name: String,
    pub lean_symbol: String,
    pub rust_symbol: String,
    pub properties: Vec<String>,
    pub proof_status: ProofStatus,
}

#[derive(Debug, Clone, PartialEq)]
pub enum ProofStatus {
    Complete,
    InProgress,
    Conjecture,
    Unproven,
}

#[derive(Debug, Clone)]
pub struct TheoremBinding {
    pub name: String,
    pub lean_theorem: String,
    pub rust_harness: Option<String>,
    pub status: ProofStatus,
}

pub struct ContractRegistry {
    contracts: HashMap<String, ContractBinding>,
    theorems: Vec<TheoremBinding>,
}

impl ContractRegistry {
    pub fn new() -> Self {
        Self {
            contracts: HashMap::new(),
            theorems: Vec::new(),
        }
    }

    pub fn register_component(&mut self, binding: ContractBinding) {
        self.contracts.insert(binding.name.clone(), binding);
    }

    pub fn register_theorem(&mut self, theorem: TheoremBinding) {
        self.theorems.push(theorem);
    }

    pub fn get_component(&self, name: &str) -> Option<&ContractBinding> {
        self.contracts.get(name)
    }

    pub fn theorems_by_status(&self, status: &ProofStatus) -> Vec<&TheoremBinding> {
        self.theorems.iter().filter(|t| &t.status == status).collect()
    }

    pub fn all_proven(&self) -> bool {
        self.theorems.iter().all(|t| t.status == ProofStatus::Complete)
    }

    pub fn coverage_report(&self) -> String {
        let total = self.theorems.len();
        let proven = self.theorems.iter().filter(|t| t.status == ProofStatus::Complete).count();
        let in_progress = self.theorems.iter().filter(|t| t.status == ProofStatus::InProgress).count();
        let conjecture = self.theorems.iter().filter(|t| t.status == ProofStatus::Conjecture).count();

        format!(
            "Theorem Coverage: {}/{} proven, {} in progress, {} conjectures",
            proven, total, in_progress, conjecture
        )
    }
}

impl Default for ContractRegistry {
    fn default() -> Self {
        Self::new()
    }
}

pub fn load_contracts() -> ContractRegistry {
    let mut reg = ContractRegistry::new();

    reg.register_component(ContractBinding {
        name: "PartialSystem".into(),
        lean_symbol: "PartialUC".into(),
        rust_symbol: "PartialSystem".into(),
        properties: vec![
            "compose_p: X × X ⇀ X".into(),
            "closure_p: X ⇀ X".into(),
        ],
        proof_status: ProofStatus::Complete,
    });

    reg.register_component(ContractBinding {
        name: "UniversalClosure".into(),
        lean_symbol: "UC".into(),
        rust_symbol: "UnionFind".into(),
        properties: vec![
            "compose: X × X → X".into(),
            "closure: X → X".into(),
        ],
        proof_status: ProofStatus::Complete,
    });

    reg.register_component(ContractBinding {
        name: "Completion".into(),
        lean_symbol: "Completion.completion".into(),
        rust_symbol: "complete".into(),
        properties: vec![
            "C ⊣ U".into(),
            "monotone_defect: μ(closure(x)) ≤ μ(x)".into(),
        ],
        proof_status: ProofStatus::InProgress,
    });

    reg.register_theorem(TheoremBinding {
        name: "Adjunction".into(),
        lean_theorem: "completion_adjunction".into(),
        rust_harness: Some("verify_composition_preserved".into()),
        status: ProofStatus::InProgress,
    });

    reg.register_theorem(TheoremBinding {
        name: "NNO_Representation".into(),
        lean_theorem: "free_one_generator_is_nno".into(),
        rust_harness: None,
        status: ProofStatus::Conjecture,
    });

    reg.register_theorem(TheoremBinding {
        name: "CompositionalDefect".into(),
        lean_theorem: "compositional_defect".into(),
        rust_harness: Some("verify_associator_bounded".into()),
        status: ProofStatus::InProgress,
    });

    reg.register_theorem(TheoremBinding {
        name: "MorphismSoundness".into(),
        lean_theorem: "morphism_soundness_image".into(),
        rust_harness: None,
        status: ProofStatus::InProgress,
    });

    reg
}
