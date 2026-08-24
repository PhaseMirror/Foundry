use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Debug)]
pub enum Operator {
    Eq,
    Gt,
    Lt,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Condition {
    pub field: String,
    pub operator: Operator,
    pub value: f64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Rule {
    pub name: String,
    pub condition: Condition,
    pub action: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RuleSet {
    pub rules: Vec<Rule>,
}

pub struct Validator {
    pub rules: Vec<Rule>,
}

impl Validator {
    pub fn compile(rule_set: RuleSet) -> Self {
        Self { rules: rule_set.rules }
    }

    pub fn validate(&self, context: &HashMap<String, f64>) -> Result<(), String> {
        for rule in &self.rules {
            if let Some(&actual) = context.get(&rule.condition.field) {
                let met = match rule.condition.operator {
                    Operator::Eq => actual == rule.condition.value,
                    Operator::Gt => actual > rule.condition.value,
                    Operator::Lt => actual < rule.condition.value,
                };
                if met {
                    return Err(format!("Rule '{}' violated: Action {}", rule.name, rule.action));
                }
            }
        }
        Ok(())
    }
}
