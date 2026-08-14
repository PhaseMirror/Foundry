use crate::ir::ast::Operator;

/// Parses .sigma.yaml or Justfile instructions into the un-normalized AST.
pub fn parse_workflow(_source: &str) -> anyhow::Result<Vec<Operator>> {
    // Scaffold: Return empty word. 
    // In production, this maps user commands to S, B, H generators.
    Ok(vec![])
}
