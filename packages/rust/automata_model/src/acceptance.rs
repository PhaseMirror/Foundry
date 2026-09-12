use crate::State;
use std::collections::{HashSet, HashMap};

pub trait AcceptanceCondition<S: State> {
    fn accepts_finite(&self, trace: &[S]) -> bool;
}

pub trait OmegaAcceptanceCondition<S: State> {
    fn accepts_lasso(&self, prefix: &[S], cycle: &[S]) -> bool;
}

#[derive(Debug, Clone)]
pub struct LassoRun<S: State> {
    pub prefix: Vec<S>,
    pub cycle: Vec<S>,
}

pub struct StateSetAcceptance<S: State> {
    pub accepting_states: HashSet<S>,
}

impl<S: State> AcceptanceCondition<S> for StateSetAcceptance<S> {
    fn accepts_finite(&self, trace: &[S]) -> bool {
        if let Some(last) = trace.last() {
            self.accepting_states.contains(last)
        } else {
            false
        }
    }
}

pub struct BuchiAcceptance<S: State> {
    pub accepting_states: HashSet<S>,
}

impl<S: State> OmegaAcceptanceCondition<S> for BuchiAcceptance<S> {
    fn accepts_lasso(&self, _prefix: &[S], cycle: &[S]) -> bool {
        cycle.iter().any(|s| self.accepting_states.contains(s))
    }
}

pub struct ParityAcceptance<S: State> {
    pub priorities: HashMap<S, u32>,
    pub mode: ParityMode,
}

pub enum ParityMode {
    Even,
    Odd,
}

impl<S: State> OmegaAcceptanceCondition<S> for ParityAcceptance<S> {
    fn accepts_lasso(&self, _prefix: &[S], cycle: &[S]) -> bool {
        let min_priority = cycle.iter()
            .filter_map(|s| self.priorities.get(s))
            .min();

        if let Some(&p) = min_priority {
            match self.mode {
                ParityMode::Even => p % 2 == 0,
                ParityMode::Odd => p % 2 != 0,
            }
        } else {
            false
        }
    }
}
