use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PirtmType {
    Stratum,
    Tensor(Vec<usize>),
    Transcendental {
        fn_name: String,
        arg: Box<PirtmType>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PirtmExpr {
    Const(i64),
    Var(String),
    Add(Box<PirtmExpr>, Box<PirtmExpr>),
    Sin(Box<PirtmExpr>),
    Cos(Box<PirtmExpr>),
    Log(Box<PirtmExpr>),
    TensorApply(Box<PirtmExpr>, Box<PirtmExpr>), // Operator applied to Tensor
}

#[derive(Debug, thiserror::Error)]
pub enum TypeError {
    #[error("type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch {
        expected: PirtmType,
        actual: PirtmType,
    },
    #[error("undefined variable: {name}")]
    UndefinedVar { name: String },
    #[error("multiplicity mismatch: operator multiplicity {op_mult} * input multiplicity {in_mult} != output")]
    MultiplicityMismatch {
        op_mult: usize,
        in_mult: usize,
    },
}

pub fn type_check(ctx: &[(String, PirtmType)], expr: &PirtmExpr) -> Result<PirtmType, TypeError> {
    match expr {
        PirtmExpr::Const(_) => Ok(PirtmType::Stratum),
        PirtmExpr::Var(name) => ctx
            .iter()
            .find(|(n, _)| n == name)
            .map(|(_, t)| t.clone())
            .ok_or_else(|| TypeError::UndefinedVar { name: name.clone() }),
        PirtmExpr::Add(e1, e2) => {
            let t1 = type_check(ctx, e1)?;
            let t2 = type_check(ctx, e2)?;
            if t1 == t2 {
                Ok(t1)
            } else {
                Err(TypeError::TypeMismatch {
                    expected: t1,
                    actual: t2,
                })
            }
        }
        PirtmExpr::TensorApply(op, input) => {
            let t_op = type_check(ctx, op)?;
            let t_input = type_check(ctx, input)?;
            match (t_op, t_input) {
                (PirtmType::Tensor(op_dims), PirtmType::Tensor(in_dims)) => {
                    let op_mult: usize = op_dims.iter().product();
                    let in_mult: usize = in_dims.iter().product();
                    // Multiplicity conservation: M(S_new) = M(Ap) * M(S_old)
                    let new_mult = op_mult * in_mult;
                    // For now, we return a new Tensor type whose sole dimension represents the new multiplicity.
                    Ok(PirtmType::Tensor(vec![new_mult]))
                }
                (actual, _) => Err(TypeError::TypeMismatch {
                    expected: PirtmType::Tensor(vec![]),
                    actual,
                }),
            }
        }
        PirtmExpr::Sin(e) | PirtmExpr::Cos(e) | PirtmExpr::Log(e) => {
            type_check(ctx, e)?;
            Ok(PirtmType::Transcendental {
                fn_name: match expr {
                    PirtmExpr::Sin(_) => "sin".into(),
                    PirtmExpr::Cos(_) => "cos".into(),
                    PirtmExpr::Log(_) => "log".into(),
                    _ => unreachable!(),
                },
                arg: Box::new(PirtmType::Stratum),
            })
        }
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    // A symbolic verifier to prove parser/type checker invariants would go here.
    #[kani::proof]
    fn verify_type_check_soundness() {
        let e = PirtmExpr::Add(Box::new(PirtmExpr::Const(1)), Box::new(PirtmExpr::Const(2)));
        let ctx = vec![];
        let res = type_check(&ctx, &e);
        kani::assert(res.is_ok(), "Type checking of valid expression failed");
        kani::assert(
            res.unwrap() == PirtmType::Stratum,
            "Type mismatch for constant addition",
        );
    }

    fn arbitrary_expr(depth: u32) -> PirtmExpr {
        if depth == 0 {
            let mult_val: usize = kani::any();
            kani::assume(mult_val >= 1 && mult_val <= 5);
            PirtmExpr::Var("t".into())
        } else {
            let is_apply: bool = kani::any();
            if is_apply {
                let left = arbitrary_expr(depth - 1);
                let right = arbitrary_expr(depth - 1);
                PirtmExpr::TensorApply(Box::new(left), Box::new(right))
            } else {
                arbitrary_expr(0)
            }
        }
    }

    fn expected_multiplicity(expr: &PirtmExpr) -> usize {
        match expr {
            PirtmExpr::Var(_) => 2,
            PirtmExpr::TensorApply(op, tensor) => {
                let m_op = expected_multiplicity(op);
                let m_tensor = expected_multiplicity(tensor);
                m_op * m_tensor
            }
            _ => 1,
        }
    }

    #[kani::proof]
    fn verify_multiplicity_conservation() {
        let ctx = vec![("t".into(), PirtmType::Tensor(vec![2]))];
        let expr = arbitrary_expr(3);
        match type_check(&ctx, &expr) {
            Ok(PirtmType::Tensor(dims)) => {
                let actual_mult: usize = dims.iter().product();
                let expected_mult = expected_multiplicity(&expr);
                kani::assert(actual_mult == expected_mult, "Multiplicity must be conserved");
            }
            Ok(_) => kani::panic("Should be a tensor"),
            Err(e) => {
                match e {
                    TypeError::MultiplicityMismatch { .. } => (),
                    TypeError::TypeMismatch { .. } => (),
                    _ => kani::panic("Unexpected error type"),
                }
            }
        }
    }
}
