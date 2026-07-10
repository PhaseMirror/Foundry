use crate::parser::Expr;
use crate::Rational;

#[derive(Debug, Clone)]
pub struct Evaluator {
    stack: Vec<Rational>,
}

impl Evaluator {
    pub fn new() -> Self {
        Self { stack: Vec::new() }
    }

    // Immutable batch evaluation: Returns new stack result without mutating self
    pub fn evaluate_batch(&self, exprs: Vec<Expr>) -> Result<Vec<Rational>, String> {
        let mut local_eval = self.clone();
        for expr in exprs {
            local_eval.eval_expr(expr)?;
        }
        Ok(local_eval.stack)
    }

    pub fn evaluate(&mut self, exprs: Vec<Expr>) -> Result<Vec<Rational>, String> {
        for expr in exprs {
            self.eval_expr(expr)?;
        }
        Ok(self.stack.clone())
    }

    fn eval_expr(&mut self, expr: Expr) -> Result<(), String> {
        match expr {
            Expr::Class(id) => {
                self.stack.push(Rational::new(id as i64, 1));
                Ok(())
            }
            Expr::Generator(name, _args) => {
                match name.as_str() {
                    "merge" => {
                        let a = self.stack.pop().ok_or("Stack underflow")?;
                        let b = self.stack.pop().ok_or("Stack underflow")?;
                        self.stack.push(Rational::new(a.num * b.den + b.num * a.den, a.den * b.den));
                        Ok(())
                    }
                    _ => Err(format!("Unsupported generator: {}", name)),
                }
            }
            Expr::Rotate => {
                // Example: Rotate might swap top two or similar logic. 
                // For this implementation, we can just treat it as a no-op or specific transformation.
                Ok(())
            }
            Expr::Triality | Expr::Twist => Ok(()),
        }
    }
}
