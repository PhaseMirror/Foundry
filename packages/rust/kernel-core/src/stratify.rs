use crate::parser::{Atom, RuleSet};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationIssue {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationResult {
    pub admissible: bool,
    pub levels: BTreeMap<String, i32>,
    pub issues: Vec<ValidationIssue>,
}

pub struct Validator;

impl Validator {
    pub fn validate(rule_set: &RuleSet) -> ValidationResult {
        let mut issues = Vec::new();
        let mut explicit = BTreeMap::new();
        let mut symbols = BTreeSet::new();

        for atom in &rule_set.atoms {
            match atom {
                Atom::Level { symbol, level } => {
                    if let Some(prev) = explicit.insert(symbol.clone(), *level) {
                        if prev != *level {
                            issues.push(ValidationIssue {
                                code: "LEVEL_CONFLICT".into(),
                                message: format!("symbol {symbol} has conflicting explicit levels {prev} and {level}"),
                            });
                        }
                    }
                    symbols.insert(symbol.clone());
                }
                Atom::Member { left, right } | Atom::Equal { left, right } => {
                    symbols.insert(left.clone());
                    symbols.insert(right.clone());
                }
                Atom::Call { from, to } => {
                    symbols.insert(from.clone());
                    symbols.insert(to.clone());
                }
            }
        }

        let mut levels: BTreeMap<String, i32> = symbols.into_iter().map(|s| (s, 0)).collect();
        for (k, v) in &explicit {
            levels.insert(k.clone(), *v);
        }

        let node_count = levels.len().max(1);
        for _ in 0..node_count {
            let mut changed = false;
            for atom in &rule_set.atoms {
                match atom {
                    Atom::Member { left, right } => {
                        if left == right {
                            issues.push(ValidationIssue {
                                code: "SELF_MEMBERSHIP".into(),
                                message: format!("member({left},{right}) collapses a level into itself"),
                            });
                        }
                        let left_level = *levels.get(left).unwrap_or(&0);
                        let target = left_level + 1;
                        let right_level = *levels.get(right).unwrap_or(&0);
                        if right_level < target {
                            levels.insert(right.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Equal { left, right } => {
                        let l = *levels.get(left).unwrap_or(&0);
                        let r = *levels.get(right).unwrap_or(&0);
                        let target = l.max(r);
                        if l != target {
                            levels.insert(left.clone(), target);
                            changed = true;
                        }
                        if r != target {
                            levels.insert(right.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Call { from, to } => {
                        if from == to {
                            issues.push(ValidationIssue {
                                code: "SELF_CALL".into(),
                                message: format!("call({from},{to}) is an immediate recursive cycle"),
                            });
                        }
                        let from_level = *levels.get(from).unwrap_or(&0);
                        let target = from_level + 1;
                        let to_level = *levels.get(to).unwrap_or(&0);
                        if to_level < target {
                            levels.insert(to.clone(), target);
                            changed = true;
                        }
                    }
                    Atom::Level { .. } => {}
                }
            }
            for (symbol, level) in &explicit {
                if levels.get(symbol).copied().unwrap_or_default() != *level {
                    issues.push(ValidationIssue {
                        code: "PINNED_LEVEL_VIOLATION".into(),
                        message: format!("derived constraints move {symbol} away from pinned level {level}"),
                    });
                }
            }
            if !changed {
                break;
            }
        }

        for atom in &rule_set.atoms {
            match atom {
                Atom::Member { left, right } => {
                    if levels.get(right).copied().unwrap_or_default()
                        != levels.get(left).copied().unwrap_or_default() + 1
                    {
                        issues.push(ValidationIssue {
                            code: "NON_STRATIFIED_MEMBER".into(),
                            message: format!("member({left},{right}) violates NF ascent"),
                        });
                    }
                }
                Atom::Equal { left, right } => {
                    if levels.get(right) != levels.get(left) {
                        issues.push(ValidationIssue {
                            code: "NON_STRATIFIED_EQUAL".into(),
                            message: format!("equal({left},{right}) violates same-level constraint"),
                        });
                    }
                }
                Atom::Call { from, to } => {
                    if levels.get(to).copied().unwrap_or_default()
                        <= levels.get(from).copied().unwrap_or_default()
                    {
                        issues.push(ValidationIssue {
                            code: "NON_ASCENDING_CALL".into(),
                            message: format!("call({from},{to}) does not strictly ascend"),
                        });
                    }
                }
                Atom::Level { .. } => {}
            }
        }

        issues.sort_by(|a, b| a.code.cmp(&b.code).then(a.message.cmp(&b.message)));
        issues.dedup_by(|a, b| a.code == b.code && a.message == b.message);

        ValidationResult {
            admissible: issues.is_empty(),
            levels,
            issues,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::RuleSet;

    #[test]
    fn validates_good_rules() {
        let rules = RuleSet::parse("level a 0\nmember a b\nmember b c\n").unwrap();
        let result = Validator::validate(&rules);
        assert!(result.admissible);
        assert_eq!(result.levels.get("b"), Some(&1));
        assert_eq!(result.levels.get("c"), Some(&2));
    }

    #[test]
    fn flags_bad_rules() {
        let rules = RuleSet::parse("level a 0\nmember a a\n").unwrap();
        let result = Validator::validate(&rules);
        assert!(!result.admissible);
        assert!(result.issues.iter().any(|i| i.code == "SELF_MEMBERSHIP"));
    }
}
