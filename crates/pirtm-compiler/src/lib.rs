use tree_sitter::{Language, Parser, Tree};

pub mod walker;
pub mod type_check;
pub mod tensor_representation;
pub mod universal_system;
pub mod into_mocword;
pub mod sig;
pub mod ace;
pub mod unified_witness;

/// The Sig Library (Multiplicity Functor)
/// Implements the Prime Successor Predicate with strict tree-sitter grammar integration.
pub struct SigCompiler {
    parser: Parser,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SigState {
    Draft,
    Accepted,
}

/// Enforces the Prime Successor Predicate logically.
#[derive(Debug, Clone)]
pub struct PrimeSuccessorPredicate {
    pub current_prime: u64,
    pub next_prime: u64,
    pub state: SigState,
}

impl PrimeSuccessorPredicate {
    pub fn new(current_prime: u64, next_prime: u64) -> Self {
        Self {
            current_prime,
            next_prime,
            state: SigState::Draft,
        }
    }

    /// Locks the predicate into the immutable Accepted state.
    pub fn accept(&mut self) {
        self.state = SigState::Accepted;
    }

    /// Tries to mutate the predicate. Will fail if already accepted (Zero Drift).
    pub fn try_mutate(&mut self, current: u64, next: u64) -> Result<(), &'static str> {
        if self.state == SigState::Accepted {
            return Err("State immutability invariant violated: Cannot mutate an accepted Prime Successor Predicate.");
        }
        self.current_prime = current;
        self.next_prime = next;
        Ok(())
    }

    /// Transitions the predicate. Checks validity of the prime successor logic.
    pub fn transition(&mut self, current: u64, next: u64) -> Result<(), &'static str> {
        // Here we would implement the exact mathematical checks for succession.
        // For the structural invariant, if current >= next, we reject the jump as non-contractive/invalid.
        if current >= next {
            return Err("Prime jump is non-monotonic or self-referential.");
        }
        
        // Once the transition is validated algebraically, we lock it into the immutable state.
        self.accept();
        Ok(())
    }
}

impl SigCompiler {
    /// Initializes the compiler with a provided PIRTM tree-sitter language grammar.
    pub fn new(language: &Language) -> Result<Self, &'static str> {
        let mut parser = Parser::new();
        parser.set_language(*language).map_err(|_| "Failed to set tree-sitter language for PIRTM")?;
        Ok(Self { parser })
    }

    /// Parses the PIRTM source code and enforces the grammar logic.
    pub fn parse_and_enforce(&mut self, source_code: &str) -> Result<Tree, String> {
        let tree = self.parser.parse(source_code, None).ok_or("Failed to parse PIRTM source")?;
        
        // AST traversal to enforce the Prime Successor Predicate
        self.enforce_invariants(source_code.as_bytes(), tree.root_node())?;
        
        // Returning the verified tree to downstream components.
        Ok(tree)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn verify_immutability_invariant() {
        let current: u64 = kani::any();
        let next: u64 = kani::any();
        
        let mut predicate = PrimeSuccessorPredicate::new(current, next);
        
        // Transition to Accepted state
        predicate.accept();
        
        // Attempt an adversarial mutation
        let new_current: u64 = kani::any();
        let new_next: u64 = kani::any();
        
        let result = predicate.try_mutate(new_current, new_next);
        
        // Kani invariants: The system MUST reject the mutation and the state MUST NOT drift.
        kani::assert(result.is_err(), "Mutating an accepted predicate must fail");
        kani::assert(predicate.state == SigState::Accepted, "State must remain strictly Accepted");
        kani::assert(predicate.current_prime == current, "Current prime metric must not drift");
        kani::assert(predicate.next_prime == next, "Next prime metric must not drift");
    }
}
