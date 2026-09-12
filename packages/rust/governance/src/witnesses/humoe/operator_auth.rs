use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HOXRole {
    Reviewer,
    Supervisor,
    ComplianceOfficer,
    SystemAdmin,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HOXOperator {
    pub operator_id: String,
    pub role: HOXRole,
}

impl HOXOperator {
    pub fn new(operator_id: &str, role: HOXRole) -> Self {
        Self {
            operator_id: operator_id.to_string(),
            role,
        }
    }

    pub fn can_act_on(&self, action: &str, escalation: bool) -> bool {
        match self.role {
            HOXRole::Reviewer => {
                let allowed_actions = ["approve", "modify", "reject", "defer"];
                allowed_actions.contains(&action) && !escalation
            }
            HOXRole::Supervisor => true,
            HOXRole::ComplianceOfficer => action == "inspect",
            HOXRole::SystemAdmin => action == "configure",
        }
    }
}

pub struct OperatorRegistry {
    operators: HashMap<String, HOXOperator>,
}

impl OperatorRegistry {
    pub fn new() -> Self {
        let mut operators = HashMap::new();
        operators.insert("operator-42".to_string(), HOXOperator::new("operator-42", HOXRole::Reviewer));
        operators.insert("supervisor-1".to_string(), HOXOperator::new("supervisor-1", HOXRole::Supervisor));
        operators.insert("compliance-7".to_string(), HOXOperator::new("compliance-7", HOXRole::ComplianceOfficer));
        operators.insert("admin-99".to_string(), HOXOperator::new("admin-99", HOXRole::SystemAdmin));
        Self { operators }
    }

    pub fn get_operator(&self, operator_id: &str) -> Option<&HOXOperator> {
        self.operators.get(operator_id)
    }
}
