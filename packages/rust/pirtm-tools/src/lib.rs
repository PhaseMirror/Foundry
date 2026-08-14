use pirtm_parser::ast::{Program, Expr, Stmt};

/// Traverses the AST to compute realistic Norm Factor (NF) parameters.
/// Returns (c, r1, r2, r3) based on the operator word structure.
pub fn eval_nf_ast(expr: &Expr) -> (f64, f64, f64, f64) {
    match expr {
        Expr::Atom { prime } => {
            // Unlawful bounds mapped mathematically
            if *prime == 1 {
                (1.5, 0.9, 0.9, 0.9) // Expansive
            } else {
                let p_f = *prime as f64;
                // c shrinks as prime increases, R factors vary
                (1.0 / p_f, 1.0 + (p_f * 0.1), 1.0 + (p_f * 0.15), 1.0 + (p_f * 0.2))
            }
        },
        Expr::Literal(_) => (0.0, 1.0, 1.0, 1.0), // Constants don't expand the operator
        Expr::Ident(_) => (0.1, 1.0, 1.0, 1.0),
        Expr::Binary { op: _, left, right } => {
            let (c1, r1a, r2a, r3a) = eval_nf_ast(left);
            let (c2, r1b, r2b, r3b) = eval_nf_ast(right);
            // Composition of operators
            (c1 + c2, r1a * r1b, r2a * r2b, r3a * r3b)
        },
        Expr::Successor(inner) => {
            let (c, r1, r2, r3) = eval_nf_ast(inner);
            (c * 1.1, r1 * 1.05, r2 * 1.05, r3 * 1.05)
        },
        Expr::PrimeShift(inner) => {
            let (c, r1, r2, r3) = eval_nf_ast(inner);
            (c * 0.9, r1 * 1.1, r2 * 1.1, r3 * 1.1)
        },
        Expr::StratumBoundary(inner) => {
            let (c, r1, r2, r3) = eval_nf_ast(inner);
            (c * 0.5, r1 * 1.2, r2 * 1.2, r3 * 1.2)
        },
        Expr::Call { name: _, args } => {
            let mut total_c = 0.1;
            let (mut r1, mut r2, mut r3) = (1.1, 1.1, 1.1);
            for arg in args {
                let (ac, ar1, ar2, ar3) = eval_nf_ast(arg);
                total_c += ac;
                r1 *= ar1; r2 *= ar2; r3 *= ar3;
            }
            (total_c, r1, r2, r3)
        },
        Expr::If { cond, then_branch: _, else_branch: _ } => eval_nf_ast(cond),
    }
}

pub fn eval_nf_program(program: &Program) -> (f64, f64, f64, f64) {
    let mut max_c = 0.0;
    let (mut total_r1, mut total_r2, mut total_r3) = (1.0, 1.0, 1.0);

    for stmt in &program.stmts {
        match stmt {
            Stmt::Expr(e) | Stmt::Let { name: _, expr: e } => {
                let (c, r1, r2, r3) = eval_nf_ast(e);
                if c > max_c { max_c = c; }
                total_r1 *= r1;
                total_r2 *= r2;
                total_r3 *= r3;
            },
            _ => {}
        }
    }
    
    // Default fallback if empty
    if program.stmts.is_empty() {
        (0.0, 1.0, 1.0, 1.0)
    } else {
        (max_c, total_r1, total_r2, total_r3)
    }
}

/// Calculates the System Resonance Rsc = (R1 * R2 * R3)^(1/3)
pub fn calc_resonance(r1: f64, r2: f64, r3: f64) -> f64 {
    (r1 * r2 * r3).powf(1.0 / 3.0)
}
