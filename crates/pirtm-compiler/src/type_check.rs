use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PirtmType {
    Stratum,
    Tensor(Vec<usize>),
    Transcendental { fn_name: String, arg: Box<PirtmType> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PirtmExpr {
    Const(i64),
    Var(String),
    Add(Box<PirtmExpr>, Box<PirtmExpr>),
    Sin(Box<PirtmExpr>),
    Cos(Box<PirtmExpr>),
    Log(Box<PirtmExpr>),
}

#[derive(Debug, thiserror::Error)]
pub enum TypeError {
    #[error("type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch { expected: PirtmType, actual: PirtmType },
    #[error("undefined variable: {name}")]
    UndefinedVar { name: String },
}

pub fn type_check(
    ctx: &[(String, PirtmType)],
    expr: &PirtmExpr,
) -> Result<PirtmType, TypeError> {
    match expr {
        PirtmExpr::Const(_) => Ok(PirtmType::Stratum),
        PirtmExpr::Var(name) => ctx.iter()
            .find(|(n, _)| n == name)
            .map(|(_, t)| t.clone())
            .ok_or_else(|| TypeError::UndefinedVar { name: name.clone() }),
        PirtmExpr::Add(e1, e2) => {
            let t1 = type_check(ctx, e1)?;
            let t2 = type_check(ctx, e2)?;
            if t1 == t2 { Ok(t1) } else {
                Err(TypeError::TypeMismatch { expected: t1, actual: t2 })
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
        let e = PirtmExpr::Add(
            Box::new(PirtmExpr::Const(1)),
            Box::new(PirtmExpr::Const(2)),
        );
        let ctx = vec![];
        let res = type_check(&ctx, &e);
        kani::assert(res.is_ok(), "Type checking of valid expression failed");
        kani::assert(res.unwrap() == PirtmType::Stratum, "Type mismatch for constant addition");
    }
}
