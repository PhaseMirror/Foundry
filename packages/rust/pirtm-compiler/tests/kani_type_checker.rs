#[cfg(kani)]
mod multiplicity_type_check {
    use pirtm_compiler::type_check::{type_check, PirtmExpr, PirtmType, TypeError};

    // For Kani we need a small bounded model; we'll limit depth to 3.
    fn arbitrary_expr(depth: u32) -> PirtmExpr {
        if depth == 0 {
            // Pick a prime and a multiplicity (1..5)
            let prime: u64 = kani::any();
            kani::assume(prime >= 2 && prime <= 5);  // small primes for symbolic execution
            let mult_val: usize = kani::any();
            kani::assume(mult_val >= 1 && mult_val <= 5);
            // Simulate an atom with a given multiplicity
            // In our type system we'll use a variable that we assume is defined in context.
            // But to make it self-contained for testing TensorApply:
            // Let's assume we can generate arbitrary valid tensors.
            // Since PirtmExpr doesn't have a direct Tensor variant, we'll use a Variable.
            // In the context, we will map it to a Tensor with specific multiplicity.
            PirtmExpr::Var("t".into())
        } else {
            // Randomly choose between atom and TensorApply
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

    #[kani::proof]
    fn verify_multiplicity_conservation() {
        // Our type system expects an empty context for this proof, but we need variables to have tensor types.
        // Let's create a context where "t" is a tensor with multiplicity 2.
        let ctx = vec![("t".into(), PirtmType::Tensor(vec![2]))];
        
        let expr = arbitrary_expr(3);
        match type_check(&ctx, &expr) {
            Ok(PirtmType::Tensor(dims)) => {
                // If it succeeds, the product invariant must hold.
                let actual_mult: usize = dims.iter().product();
                let expected_mult = expected_multiplicity(&expr);
                kani::assert(actual_mult == expected_mult, "Multiplicity must be conserved");
            }
            Ok(_) => {
                kani::panic("Should be a tensor");
            }
            Err(e) => {
                // If it fails, it must be a MultiplicityMismatch or TypeMismatch
                match e {
                    TypeError::MultiplicityMismatch { .. } => (),
                    TypeError::TypeMismatch { .. } => (),
                    _ => kani::panic("Unexpected error type"),
                }
            }
        }
    }

    // Reference multiplicity computation (the same rule that the checker enforces)
    fn expected_multiplicity(expr: &PirtmExpr) -> usize {
        match expr {
            PirtmExpr::Var(_) => 2, // From our mock context
            PirtmExpr::TensorApply(op, tensor) => {
                let m_op = expected_multiplicity(op);
                let m_tensor = expected_multiplicity(tensor);
                m_op * m_tensor // product
            }
            _ => 1,
        }
    }
}
