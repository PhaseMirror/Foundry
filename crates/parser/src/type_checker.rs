use pirtm_compiler::multiplicity_functor::{Sig, Type, TypeError};
use crate::ast::{Expression, Type as AstType};

pub struct TypeChecker;

impl TypeChecker {
    /// The exact parser hook into the Multiplicity Functor binding.
    /// Elevates an AST type and enforces compatibility across node evaluations.
    pub fn check_expression_binding(&self, expr: &Expression, expected_ast_type: &AstType) -> Result<(), TypeError> {
        let expected = self.map_ast_type(expected_ast_type);
        let actual = self.infer_type(expr)?;
        
        // Elevate both to Sig functor and verify bound compatibility
        let elevated_expected = Sig::elevate(expected);
        let elevated_actual = Sig::elevate(actual);
        
        Sig::verify_compatibility(&elevated_expected, &elevated_actual)
    }
    
    fn map_ast_type(&self, ast_type: &AstType) -> Type {
        // Mock mapping from AST to Compiler types
        match ast_type {
            AstType::Int => Type::Int,
            AstType::Float => Type::Float,
            AstType::Bool => Type::Bool,
            _ => Type::Unit,
        }
    }
    
    fn infer_type(&self, _expr: &Expression) -> Result<Type, TypeError> {
        // Stub inference fallback for expression nodes
        Ok(Type::Int)
    }
}
