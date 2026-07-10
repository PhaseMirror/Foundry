use thiserror::Error;

/// Core Type System implementation for PIRTM Phase B
/// Implements the `Sig` Multiplicity Functor binding

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Type {
    Unit,
    Bool,
    Int,
    Float,
    MultiplicityFunctor(Box<Type>),
    Function(Box<Type>, Box<Type>),
}

#[derive(Debug, Error)]
pub enum TypeError {
    #[error("Type mismatch: expected {expected:?}, found {found:?}")]
    Mismatch { expected: Type, found: Type },
    #[error("Multiplicity violation on type {0:?}")]
    MultiplicityViolation(Type),
}

/// The `Sig` Multiplicity Functor maps any type `T` into `Sig<T>`
/// representing an operation anchored over the multiplicity space `M`.
pub struct Sig;

impl Sig {
    /// Elevate a raw type into the multiplicity functor space.
    pub fn elevate(t: Type) -> Type {
        Type::MultiplicityFunctor(Box::new(t))
    }

    /// Extracs the underlying type if it's currently bounded by the Sig functor.
    pub fn extract(t: &Type) -> Result<Type, TypeError> {
        match t {
            Type::MultiplicityFunctor(inner) => Ok(*inner.clone()),
            _ => Err(TypeError::MultiplicityViolation(t.clone())),
        }
    }

    /// Verify signature compatibility under the Multiplicity bound.
    pub fn verify_compatibility(t1: &Type, t2: &Type) -> Result<(), TypeError> {
        match (t1, t2) {
            (Type::MultiplicityFunctor(inner1), Type::MultiplicityFunctor(inner2)) => {
                if inner1 == inner2 {
                    Ok(())
                } else {
                    Err(TypeError::Mismatch {
                        expected: *inner1.clone(),
                        found: *inner2.clone(),
                    })
                }
            }
            _ => Err(TypeError::MultiplicityViolation(t1.clone())),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sig_elevation() {
        let base_type = Type::Int;
        let sig_type = Sig::elevate(base_type.clone());
        assert_eq!(sig_type, Type::MultiplicityFunctor(Box::new(Type::Int)));
        
        let extracted = Sig::extract(&sig_type).unwrap();
        assert_eq!(extracted, base_type);
    }
    
    #[test]
    fn test_sig_compatibility() {
        let t1 = Sig::elevate(Type::Float);
        let t2 = Sig::elevate(Type::Float);
        let t3 = Sig::elevate(Type::Int);
        
        assert!(Sig::verify_compatibility(&t1, &t2).is_ok());
        assert!(Sig::verify_compatibility(&t1, &t3).is_err());
    }
}
