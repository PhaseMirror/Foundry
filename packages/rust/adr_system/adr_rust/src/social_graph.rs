//! # Lifebushido Social Graph
//! Enforces exact triadic scaling bounds translated from Lean 4.

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum Tier {
    Triad,
    Circle,
    Cohort,
    Sphere,
    Village,
}

impl Tier {
    pub fn capacity(&self) -> usize {
        match self {
            Tier::Triad => 3,
            Tier::Circle => 9,
            Tier::Cohort => 27,
            Tier::Sphere => 81,
            Tier::Village => 243,
        }
    }
}

pub struct VerifiedGraph {
    pub tier: Tier,
    nodes: Vec<String>,
}

#[derive(Debug, PartialEq)]
pub enum GraphError {
    CapacityExceeded,
    TierNotFullForUpgrade,
}

impl VerifiedGraph {
    pub fn new(tier: Tier) -> Self {
        Self {
            tier,
            nodes: Vec::new(),
        }
    }

    /// Add a node, strictly enforcing the capacity constraints
    pub fn add_node(&mut self, node_id: String) -> Result<(), GraphError> {
        if self.nodes.len() >= self.tier.capacity() {
            return Err(GraphError::CapacityExceeded);
        }
        self.nodes.push(node_id);
        Ok(())
    }

    /// Upgrade to the next tier, verifying completeness first
    pub fn upgrade_to_circle(&mut self) -> Result<(), GraphError> {
        if self.tier != Tier::Triad {
            return Err(GraphError::TierNotFullForUpgrade); // simplified for this specific transition
        }
        if self.nodes.len() < 3 {
            return Err(GraphError::TierNotFullForUpgrade);
        }
        self.tier = Tier::Circle;
        Ok(())
    }
}
