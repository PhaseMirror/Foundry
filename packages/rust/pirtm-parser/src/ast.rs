// crates/pirtm-parser/src/ast.rs

use std::fmt;

/// AST Statement types for EBNF grammar decoding
#[derive(Debug, Clone, PartialEq)]
pub enum Statement {
    TensorDeclaration { identifier: String, primes: Vec<String> },
    OperatorApplication { identifier: String, has_lambda: bool, prime_chain: Vec<String> },
    ContractivityAssertion { identifier: String, bound: f64 },
}

/// A cryptographic artifact proving mathematical soundness
#[derive(Debug, PartialEq, Clone)]
pub struct ContractivityReceipt {
    pub hash: String,
}

/// A fully verifiable AST atom implementing the 2-layer model.
pub struct OperatorAtom<F>
where
    F: FnOnce(u64) -> Result<ContractivityReceipt, String>,
{
    pub prime_index: u64,
    pub receipt: ContractivityReceipt,
    _marker: std::marker::PhantomData<F>,
}

impl<F> std::fmt::Debug for OperatorAtom<F>
where
    F: FnOnce(u64) -> Result<ContractivityReceipt, String>,
{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("OperatorAtom")
            .field("prime_index", &self.prime_index)
            .field("receipt", &self.receipt)
            .finish()
    }
}

impl<F> OperatorAtom<F>
where
    F: FnOnce(u64) -> Result<ContractivityReceipt, String>,
{
    pub fn new(prime_index: u64, proof_extractor: F) -> Result<Self, String> {
        let receipt = proof_extractor(prime_index)?;
        Ok(Self {
            prime_index,
            receipt,
            _marker: std::marker::PhantomData,
        })
    }

    pub fn receipt(&self) -> &ContractivityReceipt {
        &self.receipt
    }
}

#[derive(Debug, PartialEq, Clone)]
pub enum LogicalOp {
    And,
    Or,
}

/// Expressions in the language.
#[derive(Debug, PartialEq, Clone)]
pub enum Expr {
    /// Integer literal
    Literal(u64),
    FloatLit(f64),
    CharLit(char),
    StringLit(String),
    /// Identifier or qualified path (variable name / type constructor)
    Ident(String),
    /// Atom from the language (Ap(n) -> prime index n)
    Atom { prime: u64 },
    /// Binary operation
    Binary {
        op: BinOp,
        left: Box<Expr>,
        right: Box<Expr>,
    },
    /// Function call expression: name(args...)
    Call { name: String, args: Vec<Expr> },
    /// If expression with optional else branch
    If {
        cond: Box<Expr>,
        then_branch: Vec<Stmt>,
        else_branch: Option<Vec<Stmt>>,
    },
    /// Successor operation
    Successor(Box<Expr>),
    /// Stratum Boundary operation
    StratumBoundary(Box<Expr>),
    /// Prime Shift operation
    PrimeShift(Box<Expr>),
    /// Transcendental sine operation
    Sin(Box<Expr>),
    /// Transcendental cosine operation
    Cos(Box<Expr>),
    /// Transcendental logarithm operation
    Log(Box<Expr>),
    LogicalOp {
        op: LogicalOp,
        left: Box<Expr>,
        right: Box<Expr>,
    },
    Not(Box<Expr>),
    MethodCall {
        obj: Box<Expr>,
        method: String,
        args: Vec<Expr>,
    },
    Tuple(Vec<Expr>),
    /// Struct initialization: `StructName { field: val, ... }`
    StructInit {
        name: String,
        fields: Vec<(String, Box<Expr>)>,
    },
    /// Field access: `obj.field`
    FieldAccess {
        obj: Box<Expr>,
        field: String,
    },
    /// Pattern matching: `match expr { pat => body, ... }`
    Match {
        expr: Box<Expr>,
        arms: Vec<(String, Vec<Stmt>)>,
    },
    /// Try operator: `expr?`
    Try(Box<Expr>),
}

pub struct DomainConfig {
    pub max_multiplicity: Option<u64>,
    pub prime_boundary: Option<u64>,
}

pub trait L0Predicate {
    const DOMAIN_CONFIG: DomainConfig;
    fn operator_name() -> &'static str;
    fn tension_message() -> Option<&'static str>;
    fn check_invariants(expr: &Expr) -> Result<(), String>;
    fn extract_proof() -> Result<(), String>;
}

pub struct SuccessorPredicate;
impl L0Predicate for SuccessorPredicate {
    const DOMAIN_CONFIG: DomainConfig = DomainConfig {
        max_multiplicity: None,
        prime_boundary: None,
    };
    fn operator_name() -> &'static str {
        "succ"
    }
    fn tension_message() -> Option<&'static str> {
        Some("Near-miss stratum or depth threshold approaching")
    }
    fn check_invariants(expr: &Expr) -> Result<(), String> {
        if let Expr::Literal(v) = expr {
            if *v > i64::MAX as u64 {
                return Err("Sedona Spine ERROR: Bounds check violation in successor".to_string());
            }
        }
        Ok(())
    }
    fn extract_proof() -> Result<(), String> {
        if std::env::var("CONTRACTIVITY_RECEIPT").is_err() {
            return Err(
                "Lean Proof Failure: No CONTRACTIVITY_RECEIPT for PIRTM convergence".to_string(),
            );
        }
        Ok(())
    }
}

pub struct StratumBoundaryPredicate;
impl L0Predicate for StratumBoundaryPredicate {
    const DOMAIN_CONFIG: DomainConfig = DomainConfig {
        max_multiplicity: None,
        prime_boundary: Some(0),
    };
    fn operator_name() -> &'static str {
        "stratum_boundary"
    }
    fn tension_message() -> Option<&'static str> {
        Some("Boundary tension detected")
    }
    fn check_invariants(expr: &Expr) -> Result<(), String> {
        if let Expr::Literal(v) = expr {
            if *v == 0 {
                return Err(
                    "Sedona Spine ERROR: Invalid boundary zero in StratumBoundary".to_string(),
                );
            }
        }
        Ok(())
    }
    fn extract_proof() -> Result<(), String> {
        if std::env::var("CONTRACTIVITY_RECEIPT").is_err() {
            return Err(
                "Lean Proof Failure: No CONTRACTIVITY_RECEIPT for stratum boundary invariance"
                    .to_string(),
            );
        }
        Ok(())
    }
}

pub struct PrimeShiftPredicate;
impl L0Predicate for PrimeShiftPredicate {
    const DOMAIN_CONFIG: DomainConfig = DomainConfig {
        max_multiplicity: Some(1024),
        prime_boundary: Some(1),
    };
    fn operator_name() -> &'static str {
        "prime_shift"
    }
    fn tension_message() -> Option<&'static str> {
        Some("Prime shift tension detected")
    }
    fn check_invariants(expr: &Expr) -> Result<(), String> {
        if let Expr::Literal(v) = expr {
            if *v <= 1 {
                return Err("Sedona Spine ERROR: Invalid prime shift base".to_string());
            }
        }
        Ok(())
    }
    fn extract_proof() -> Result<(), String> {
        if std::env::var("CONTRACTIVITY_RECEIPT").is_err() {
            return Err(
                "Lean Proof Failure: No CONTRACTIVITY_RECEIPT for prime shift invariance"
                    .to_string(),
            );
        }
        Ok(())
    }
}

impl Expr {
    fn emit_lever(operator: &str, tension: &str) {
        use std::fs::OpenOptions;
        use std::io::Write;

        let lever_json = format!(
            r#"{{
  "tension": "{}",
  "evidence": "pirtm-parser/src/ast.rs:generated",
  "owner": "Compiler Engineering",
  "metric": "Address tension in {}",
  "horizon": "7 days",
  "actions": ["Review operator constraints", "Refactor heuristic if applicable"]
}}"#,
            tension, operator
        );

        if let Ok(mut file) = OpenOptions::new()
            .create(true)
            .append(true)
            .open("phase_mirror_lever.json")
        {
            let _ = writeln!(file, "{}", lever_json);
        }
    }

    fn construct_with_l0<T: L0Predicate>(expr: Expr) -> Result<Expr, String> {
        T::check_invariants(&expr)?;

        if let Err(proof_err) = T::extract_proof() {
            Self::emit_lever(
                T::operator_name(),
                &format!("Lean Proof Failure: {}", proof_err),
            );
            return Err(format!("L0 Invariant Violation: {}", proof_err));
        }

        if let Some(tension) = T::tension_message() {
            Self::emit_lever(T::operator_name(), tension);
        }

        Ok(expr)
    }

    pub fn try_successor(expr: Expr) -> Result<Expr, String> {
        Ok(Expr::Successor(Box::new(Self::construct_with_l0::<
            SuccessorPredicate,
        >(expr)?)))
    }

    pub fn try_stratum_boundary(expr: Expr) -> Result<Expr, String> {
        Ok(Expr::StratumBoundary(Box::new(Self::construct_with_l0::<
            StratumBoundaryPredicate,
        >(expr)?)))
    }

    pub fn try_prime_shift(expr: Expr) -> Result<Expr, String> {
        Ok(Expr::PrimeShift(Box::new(Self::construct_with_l0::<
            PrimeShiftPredicate,
        >(expr)?)))
    }
}

/// Ensemble declaration AST node
#[derive(Debug, PartialEq, Clone)]
pub struct EnsembleDecl {
    pub name: String,
    pub version: String,
    pub prime: u64,
}

impl EnsembleDecl {
    pub fn try_reproduce(
        name: String,
        version: String,
        prime: u64,
        parent_hash: &str,
        receipt: ContractivityReceipt,
    ) -> Result<Self, String> {
        let expected_hash = format!("{}_fused", parent_hash);
        
        if receipt.hash != expected_hash {
            return Err("HardwareState::fail_closed: MD-006 Genetic Fidelity violation - invalid ContractivityReceipt".to_string());
        }

        Ok(Self {
            name,
            version,
            prime,
        })
    }
}

/// Import statement AST node
#[derive(Debug, PartialEq, Clone)]
pub struct ImportStmt {
    pub path: String,
    pub alias: Option<String>,
    pub spectral_budget: Option<f64>,
}

/// Binary operators.
#[derive(Debug, PartialEq, Clone, Copy)]
pub enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
    Eq,
    Neq,
    Lt,
    Gt,
    Le,
    Ge,
}

/// Represents a Type in the AST
#[derive(Debug, PartialEq, Clone)]
pub enum Type {
    Simple(String),
    Generic(String, Vec<Type>),
    Function(Vec<Type>, Box<Type>),
    Tuple(Vec<Type>),
    Reference { is_mut: bool, inner: Box<Type> },
}

impl fmt::Display for Type {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Type::Simple(name) => write!(f, "{}", name),
            Type::Generic(name, params) => {
                let params_str = params.iter().map(|p| format!("{}", p)).collect::<Vec<_>>().join(", ");
                write!(f, "{}<{}>", name, params_str)
            }
            Type::Function(args, ret) => {
                let args_str = args.iter().map(|a| format!("{}", a)).collect::<Vec<_>>().join(", ");
                write!(f, "fn({}) -> {}", args_str, ret)
            }
            Type::Tuple(types) => {
                let types_str = types.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(", ");
                write!(f, "({})", types_str)
            }
            Type::Reference { is_mut, inner } => {
                if *is_mut {
                    write!(f, "&mut {}", inner)
                } else {
                    write!(f, "&{}", inner)
                }
            }
        }
    }
}

/// A statement in the language.
#[derive(Debug, PartialEq, Clone)]
pub enum Stmt {
    Ensemble(EnsembleDecl),
    Import(ImportStmt),
    Let { name: String, expr: Expr },
    LetMut { name: String, expr: Expr },
    Assign { name: String, expr: Expr },
    Return(Option<Expr>),
    Expr(Expr),
    Block(Vec<Stmt>),
    If {
        cond: Expr,
        then_branch: Vec<Stmt>,
        else_branch: Option<Vec<Stmt>>,
    },
    Loop {
        cond: Option<Expr>,
        body: Vec<Stmt>,
    },
    FnDef {
        name: String,
        generics: Vec<String>,
        params: Vec<(String, Type)>,
        return_type: Option<Type>,
        body: Vec<Stmt>,
    },
    StructDef {
        name: String,
        generics: Vec<String>,
        fields: Vec<(String, Type)>,
    },
    EnumDef {
        name: String,
        generics: Vec<String>,
        variants: Vec<(String, Option<Type>)>,
    },
    ImplDef {
        target: String,
        generics: Vec<String>,
        methods: Vec<Stmt>,
    },
    ExternFn {
        name: String,
        params: Vec<(String, Type)>,
        return_type: Option<Type>,
        abi: String,
    },
    Break,
    Continue,
}

/// A complete program: a list of statements.
#[derive(Debug, PartialEq, Clone)]
pub struct Program {
    pub stmts: Vec<Stmt>,
}

impl fmt::Display for Expr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Expr::Literal(v) => write!(f, "{}", v),
            Expr::FloatLit(v) => write!(f, "{}", v),
            Expr::CharLit(v) => write!(f, "'{}'", v),
            Expr::StringLit(v) => write!(f, "\"{}\"", v),
            Expr::Ident(name) => write!(f, "{}", name),
            Expr::Atom { prime } => write!(f, "Ap({})", prime),
            Expr::Binary { op, left, right } => {
                let op_str = match op {
                    BinOp::Add => "+",
                    BinOp::Sub => "-",
                    BinOp::Mul => "*",
                    BinOp::Div => "/",
                    BinOp::Eq => "==",
                    BinOp::Neq => "!=",
                    BinOp::Lt => "<",
                    BinOp::Gt => ">",
                    BinOp::Le => "<=",
                    BinOp::Ge => ">=",
                };
                write!(f, "({} {} {})", left, op_str, right)
            }
            Expr::Call { name, args } => {
                let args_str = args
                    .iter()
                    .map(|a| format!("{}", a))
                    .collect::<Vec<_>>()
                    .join(", ");
                write!(f, "{}({})", name, args_str)
            }
            Expr::If {
                cond,
                then_branch,
                else_branch,
            } => {
                let then_str = then_branch
                    .iter()
                    .map(|s| format!("{}", s))
                    .collect::<Vec<_>>()
                    .join("; ");
                let else_str = if let Some(else_branch) = else_branch {
                    format!(
                        " else {{ {} }}",
                        else_branch
                            .iter()
                            .map(|s| format!("{}", s))
                            .collect::<Vec<_>>()
                            .join("; ")
                    )
                } else {
                    "".to_string()
                };
                write!(f, "if ({}) {{ {} }}{}", cond, then_str, else_str)
            }
            Expr::LogicalOp { op, left, right } => write!(f, "({:?} {:?} {:?})", left, op, right),
            Expr::Not(e) => write!(f, "!{}", e),
            Expr::MethodCall { obj, method, args } => {
                let args_str = args.iter().map(|a| format!("{}", a)).collect::<Vec<_>>().join(", ");
                write!(f, "{}.{}({})", obj, method, args_str)
            }
            Expr::Tuple(elems) => {
                let elems_str = elems.iter().map(|e| format!("{}", e)).collect::<Vec<_>>().join(", ");
                write!(f, "({})", elems_str)
            }
            Expr::Successor(inner) => write!(f, "succ({})", inner),
            Expr::StratumBoundary(inner) => write!(f, "stratum_boundary({})", inner),
            Expr::PrimeShift(inner) => write!(f, "prime_shift({})", inner),
            Expr::Sin(e) => write!(f, "sin({})", e),
            Expr::Cos(e) => write!(f, "cos({})", e),
            Expr::Log(e) => write!(f, "log({})", e),
            Expr::StructInit { name, fields } => {
                let fields_str = fields.iter().map(|(n, v)| format!("{}: {}", n, v)).collect::<Vec<_>>().join(", ");
                write!(f, "{} {{ {} }}", name, fields_str)
            }
            Expr::FieldAccess { obj, field } => write!(f, "{}.{}", obj, field),
            Expr::Match { expr, arms } => {
                let arms_str = arms.iter().map(|(p, b)| {
                    let b_str = b.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join("; ");
                    format!("{} => {{ {} }}", p, b_str)
                }).collect::<Vec<_>>().join(", ");
                write!(f, "match {} {{ {} }}", expr, arms_str)
            }
            Expr::Try(inner) => write!(f, "{}?", inner),
        }
    }
}

impl fmt::Display for Stmt {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Stmt::Ensemble(e) => write!(f, "ensemble {} v{} prime={}", e.name, e.version, e.prime),
            Stmt::Import(i) => {
                let alias_part = if let Some(alias) = &i.alias {
                    format!(" as {}", alias)
                } else {
                    String::new()
                };
                let budget_part = if let Some(budget) = i.spectral_budget {
                    format!(" with spectral_budget = {}", budget)
                } else {
                    String::new()
                };
                write!(f, "use {}{}{};", i.path, alias_part, budget_part)
            }
            Stmt::Let { name, expr } => write!(f, "let {} = {};", name, expr),
            Stmt::LetMut { name, expr } => write!(f, "let mut {} = {};", name, expr),
            Stmt::Assign { name, expr } => write!(f, "{} = {};", name, expr),
            Stmt::Return(e) => {
                if let Some(e) = e { write!(f, "return {};", e) } else { write!(f, "return;") }
            },
            Stmt::Expr(e) => write!(f, "{}", e),
            Stmt::Block(stmts) => {
                let inner = stmts
                    .iter()
                    .map(|s| format!("{}", s))
                    .collect::<Vec<_>>()
                    .join("; ");
                write!(f, "{{ {} }}", inner)
            }
            Stmt::If { cond, then_branch, else_branch } => {
                let then_str = then_branch.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join("; ");
                let else_str = if let Some(else_branch) = else_branch {
                    format!(" else {{ {} }}", else_branch.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join("; "))
                } else {
                    String::new()
                };
                write!(f, "if {} {{ {} }}{}", cond, then_str, else_str)
            }
            Stmt::Loop { cond, body } => {
                let body_str = body.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join("; ");
                if let Some(cond) = cond {
                    write!(f, "while {} {{ {} }}", cond, body_str)
                } else {
                    write!(f, "loop {{ {} }}", body_str)
                }
            }
            Stmt::FnDef { name, generics, params, return_type, body } => {
                let gen_str = if generics.is_empty() { String::new() } else { format!("<{}>", generics.join(", ")) };
                let params_str = params.iter().map(|(n, t)| format!("{}: {}", n, t)).collect::<Vec<_>>().join(", ");
                let ret_str = if let Some(rt) = return_type { format!(" -> {}", rt) } else { String::new() };
                let body_str = body.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join("; ");
                write!(f, "fn {}{}({}){} {{ {} }}", name, gen_str, params_str, ret_str, body_str)
            }
            Stmt::StructDef { name, generics, fields } => {
                let gen_str = if generics.is_empty() { String::new() } else { format!("<{}>", generics.join(", ")) };
                let fields_str = fields.iter().map(|(n, t)| format!("{}: {}", n, t)).collect::<Vec<_>>().join(", ");
                write!(f, "struct {}{} {{ {} }}", name, gen_str, fields_str)
            }
            Stmt::EnumDef { name, generics, variants } => {
                let gen_str = if generics.is_empty() { String::new() } else { format!("<{}>", generics.join(", ")) };
                let vars_str = variants.iter().map(|(n, t)| {
                    if let Some(typ) = t { format!("{}({})", n, typ) } else { format!("{}", n) }
                }).collect::<Vec<_>>().join(", ");
                write!(f, "enum {}{} {{ {} }}", name, gen_str, vars_str)
            }
            Stmt::ImplDef { target, generics, methods } => {
                let gen_str = if generics.is_empty() { String::new() } else { format!("<{}>", generics.join(", ")) };
                let methods_str = methods.iter().map(|m| format!("{}", m)).collect::<Vec<_>>().join(" ");
                write!(f, "impl {}{} {{ {} }}", target, gen_str, methods_str)
            }
            Stmt::ExternFn { name, params, return_type, abi } => {
                let p: Vec<String> = params.iter().map(|(n, t)| format!("{}: {}", n, t)).collect();
                let rt = return_type.as_ref().map_or(String::new(), |t| format!(" -> {}", t));
                write!(f, "extern \"{}\" fn {}({}){};", abi, name, p.join(", "), rt)
            }
            Stmt::Break => write!(f, "break;"),
            Stmt::Continue => write!(f, "continue;"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mock_lean_proof_extraction(prime: u64) -> Result<ContractivityReceipt, String> {
        if prime == 1 {
            return Err("Lean 4 proof rejection: prime_index 1 violates invariants".to_string());
        }
        Ok(ContractivityReceipt {
            hash: format!("hash_for_{}", prime),
        })
    }

    #[test]
    fn test_operator_atom_valid() {
        let op = OperatorAtom::new(2, mock_lean_proof_extraction);
        assert!(op.is_ok());
        assert_eq!(op.unwrap().receipt.hash, "hash_for_2");
    }

    #[test]
    fn test_operator_atom_invalid() {
        let op = OperatorAtom::new(1, mock_lean_proof_extraction);
        assert!(op.is_err());
        assert_eq!(
            op.unwrap_err(),
            "Lean 4 proof rejection: prime_index 1 violates invariants"
        );
    }

    #[test]
    fn test_try_stratum_boundary_zero_fails_hard_check() {
        let expr = Expr::Literal(0);
        let result = Expr::try_stratum_boundary(expr);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Invalid boundary zero"));
    }

    #[test]
    fn test_try_prime_shift_invalid_base_fails_hard_check() {
        let expr = Expr::Literal(1);
        let result = Expr::try_prime_shift(expr);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Invalid prime shift base"));
    }
}
