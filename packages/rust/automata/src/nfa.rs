use std::collections::{HashMap, HashSet, VecDeque, BTreeSet};
use serde::{Deserialize, Serialize};
use crate::{State, Symbol, DFA};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(bound(serialize = "S: Serialize, Sym: Serialize", deserialize = "S: Deserialize<'de>, Sym: Deserialize<'de>"))]
pub struct NFA<S: State, Sym: Symbol> {
    pub states: HashSet<S>,
    pub alphabet: HashSet<Sym>,
    pub transition: HashMap<(S, Option<Sym>), HashSet<S>>,
    pub start_state: S,
    pub accept_states: HashSet<S>,
}

impl<S: State, Sym: Symbol> NFA<S, Sym> 
where
    S: Ord,
    Sym: Ord,
{
    pub fn new(
        states: HashSet<S>,
        alphabet: HashSet<Sym>,
        transition: HashMap<(S, Option<Sym>), HashSet<S>>,
        start_state: S,
        accept_states: HashSet<S>,
    ) -> Result<Self, String> {
        let nfa = NFA {
            states,
            alphabet,
            transition,
            start_state,
            accept_states,
        };
        nfa.validate()?;
        Ok(nfa)
    }

    pub fn validate(&self) -> Result<(), String> {
        if !self.states.contains(&self.start_state) {
            return Err("start_state must be in states".to_string());
        }
        for state in &self.accept_states {
            if !self.states.contains(state) {
                return Err("accept_states must be a subset of states".to_string());
            }
        }
        for ((state, symbol), targets) in &self.transition {
            if !self.states.contains(state) {
                return Err(format!("Transition state {:?} must be in states", state));
            }
            if let Some(sym) = symbol {
                if !self.alphabet.contains(sym) {
                    return Err(format!("Transition symbol {:?} must be in alphabet", sym));
                }
            }
            for target in targets {
                if !self.states.contains(target) {
                    return Err(format!("Transition target {:?} must be in states", target));
                }
            }
        }
        Ok(())
    }

    pub fn epsilon_closure(&self, states: &HashSet<S>) -> HashSet<S> {
        let mut closure = states.clone();
        let mut stack: Vec<S> = states.iter().cloned().collect();

        while let Some(state) = stack.pop() {
            if let Some(targets) = self.transition.get(&(state, None)) {
                for target in targets {
                    if !closure.contains(target) {
                        closure.insert(target.clone());
                        stack.push(target.clone());
                    }
                }
            }
        }
        closure
    }

    pub fn step(&self, current_states: &HashSet<S>, symbol: &Sym) -> HashSet<S> {
        let current_closure = self.epsilon_closure(current_states);
        let mut next_states = HashSet::new();

        for state in current_closure {
            if let Some(targets) = self.transition.get(&(state, Some(symbol.clone()))) {
                next_states.extend(targets.iter().cloned());
            }
        }

        self.epsilon_closure(&next_states)
    }

    pub fn run(&self, word: &[Sym]) -> HashSet<S> {
        let mut current_states = self.epsilon_closure(&[self.start_state.clone()].iter().cloned().collect());
        for symbol in word {
            current_states = self.step(&current_states, symbol);
            if current_states.is_empty() {
                break;
            }
        }
        current_states
    }

    pub fn accepts(&self, word: &[Sym]) -> bool {
        let final_states = self.run(word);
        !final_states.is_disjoint(&self.accept_states)
    }

    pub fn to_dfa(&self) -> DFA<u32, Sym> {
        let start_closure = self.epsilon_closure(&[self.start_state.clone()].iter().cloned().collect());
        let start_subset: BTreeSet<S> = start_closure.into_iter().collect();
        
        let mut subset_to_id = HashMap::new();
        let mut id_to_subset = HashMap::new();
        let mut next_id = 0;

        subset_to_id.insert(start_subset.clone(), next_id);
        id_to_subset.insert(next_id, start_subset.clone());
        next_id += 1;

        let mut dfa_states = HashSet::new();
        let mut dfa_accept_states = HashSet::new();
        let mut dfa_transition = HashMap::new();
        
        let mut queue = VecDeque::new();
        queue.push_back(0);
        dfa_states.insert(0);

        while let Some(id) = queue.pop_front() {
            let subset = &id_to_subset[&id];
            
            let subset_hashset: HashSet<S> = subset.iter().cloned().collect();
            if !subset_hashset.is_disjoint(&self.accept_states) {
                dfa_accept_states.insert(id);
            }

            for symbol in &self.alphabet {
                let next_states = self.step(&subset_hashset, symbol);
                let next_subset: BTreeSet<S> = next_states.into_iter().collect();

                let next_id = if let Some(&existing_id) = subset_to_id.get(&next_subset) {
                    existing_id
                } else {
                    let new_id = next_id;
                    next_id += 1;
                    subset_to_id.insert(next_subset.clone(), new_id);
                    id_to_subset.insert(new_id, next_subset);
                    dfa_states.insert(new_id);
                    queue.push_back(new_id);
                    new_id
                };

                dfa_transition.insert((id, symbol.clone()), next_id);
            }
        }

        DFA {
            states: dfa_states,
            alphabet: self.alphabet.clone(),
            transition: dfa_transition,
            start_state: 0,
            accept_states: dfa_accept_states,
        }
    }
}
