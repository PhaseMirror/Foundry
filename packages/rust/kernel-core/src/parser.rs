use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum Atom {
    Level { symbol: String, level: i32 },
    Member { left: String, right: String },
    Equal { left: String, right: String },
    Call { from: String, to: String },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleSet {
    pub atoms: Vec<Atom>,
}

impl RuleSet {
    pub fn parse(input: &str) -> Result<Self> {
        let mut atoms = Vec::new();
        for (idx, raw) in input.lines().enumerate() {
            let line = raw.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let parts: Vec<&str> = line.split_whitespace().collect();
            let atom = match parts.as_slice() {
                ["level", symbol, level] => Atom::Level {
                    symbol: (*symbol).to_string(),
                    level: level.parse().map_err(|_| anyhow!("invalid level at line {}", idx + 1))?,
                },
                ["member", left, right] => Atom::Member {
                    left: (*left).to_string(),
                    right: (*right).to_string(),
                },
                ["equal", left, right] => Atom::Equal {
                    left: (*left).to_string(),
                    right: (*right).to_string(),
                },
                ["call", from, to] => Atom::Call {
                    from: (*from).to_string(),
                    to: (*to).to_string(),
                },
                _ => return Err(anyhow!("unrecognized syntax at line {}: {}", idx + 1, line)),
            };
            atoms.push(atom);
        }
        Ok(Self { atoms })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_rules() {
        let input = "level x 0\nmember x y\nequal y y\ncall f g\n";
        let set = RuleSet::parse(input).unwrap();
        assert_eq!(set.atoms.len(), 4);
    }
}
