#[cfg(test)]
mod compiler_tests {
    use crate::policy_compiler::{Validator, RuleSet, Rule, Condition, Operator};
    use std::collections::HashMap;

    #[test]
    fn test_policy_compiler() {
        let rules = RuleSet {
            rules: vec![
                Rule {
                    name: "DriftCheck".to_string(),
                    condition: Condition {
                        field: "drift".to_string(),
                        operator: Operator::Gt,
                        value: 0.17,
                    },
                    action: "COLLAPSE".to_string(),
                }
            ]
        };
        let validator = Validator::compile(rules);
        
        let mut context = HashMap::new();
        context.insert("drift".to_string(), 0.10);
        assert!(validator.validate(&context).is_ok());

        context.insert("drift".to_string(), 0.18);
        assert!(validator.validate(&context).is_err());
    }
}
