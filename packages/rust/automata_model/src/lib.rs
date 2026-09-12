use std::collections::{HashMap, HashSet, BTreeSet, VecDeque};
use serde::{Deserialize, Serialize};
use std::hash::Hash;

pub trait State: Hash + Eq + Clone + std::fmt::Debug {}
impl<T: Hash + Eq + Clone + std::fmt::Debug> State for T {}

pub trait Symbol: Hash + Eq + Clone + std::fmt::Debug {}
impl<T: Hash + Eq + Clone + std::fmt::Debug> Symbol for T {}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(bound(serialize = "S: Serialize, Sym: Serialize", deserialize = "S: Deserialize<'de>, Sym: Deserialize<'de>"))]
pub struct DFA<S: State, Sym: Symbol> {
    pub states: HashSet<S>,
    pub alphabet: HashSet<Sym>,
    pub transition: HashMap<(S, Sym), S>,
    pub start_state: S,
    pub accept_states: HashSet<S>,
}

impl<S: State, Sym: Symbol> DFA<S, Sym> {
    pub fn new(
        states: HashSet<S>,
        alphabet: HashSet<Sym>,
        transition: HashMap<(S, Sym), S>,
        start_state: S,
        accept_states: HashSet<S>,
    ) -> Result<Self, String> {
        let dfa = DFA {
            states,
            alphabet,
            transition,
            start_state,
            accept_states,
        };
        dfa.validate()?;
        Ok(dfa)
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
        for state in &self.states {
            for symbol in &self.alphabet {
                if !self.transition.contains_key(&(state.clone(), symbol.clone())) {
                    return Err(format!("DFA missing transition for ({:?}, {:?})", state, symbol));
                }
            }
        }
        for ((state, symbol), target) in &self.transition {
            if !self.states.contains(state) {
                return Err(format!("Transition state {:?} must be in states", state));
            }
            if !self.alphabet.contains(symbol) {
                return Err(format!("Transition symbol {:?} must be in alphabet", symbol));
            }
            if !self.states.contains(target) {
                return Err(format!("Transition target {:?} must be in states", target));
            }
        }
        Ok(())
    }

    pub fn run(&self, word: &[Sym]) -> S {
        let mut current = self.start_state.clone();
        for symbol in word {
            current = self.transition[&(current, symbol.clone())].clone();
        }
        current
    }

    pub fn run_trace(&self, word: &[Sym]) -> Vec<S> {
        let mut current = self.start_state.clone();
        let mut trace = vec![current.clone()];
        for symbol in word {
            current = self.transition[&(current, symbol.clone())].clone();
            trace.push(current.clone());
        }
        trace
    }

    pub fn accepts(&self, word: &[Sym]) -> bool {
        let final_state = self.run(word);
        self.accept_states.contains(&final_state)
    }

    pub fn minimize(&self) -> DFA<u32, Sym> 
    where S: Ord {
        let reachable = self.reachable_states();
        let finals: HashSet<S> = reachable.intersection(&self.accept_states).cloned().collect();
        let non_finals: HashSet<S> = reachable.difference(&self.accept_states).cloned().collect();

        let mut partitions: Vec<BTreeSet<S>> = Vec::new();
        if !finals.is_empty() {
            partitions.push(finals.into_iter().collect());
        }
        if !non_finals.is_empty() {
            partitions.push(non_finals.into_iter().collect());
        }

        let mut worklist: VecDeque<BTreeSet<S>> = partitions.iter().cloned().collect();

        while let Some(splitter) = worklist.pop_front() {
            for symbol in &self.alphabet {
                let preimage: HashSet<S> = reachable.iter()
                    .filter(|&state| splitter.contains(&self.transition[&(state.clone(), symbol.clone())]))
                    .cloned()
                    .collect();

                if preimage.is_empty() {
                    continue;
                }

                let mut next_partitions = Vec::new();
                for block in partitions {
                    let block_set: HashSet<S> = block.iter().cloned().collect();
                    let left: HashSet<S> = block_set.intersection(&preimage).cloned().collect();
                    let right: HashSet<S> = block_set.difference(&preimage).cloned().collect();

                    if !left.is_empty() && !right.is_empty() {
                        let left_block: BTreeSet<S> = left.into_iter().collect();
                        let right_block: BTreeSet<S> = right.into_iter().collect();
                        next_partitions.push(left_block.clone());
                        next_partitions.push(right_block.clone());

                        if worklist.contains(&block) {
                            // Replace block in worklist
                            let idx = worklist.iter().position(|x| x == &block).unwrap();
                            worklist.remove(idx);
                            worklist.push_back(left_block);
                            worklist.push_back(right_block);
                        } else {
                            if left_block.len() <= right_block.len() {
                                worklist.push_back(left_block);
                            } else {
                                worklist.push_back(right_block);
                            }
                        }
                    } else {
                        next_partitions.push(block);
                    }
                }
                partitions = next_partitions;
            }
        }

        let mut state_to_id = HashMap::new();
        let mut id_to_block = HashMap::new();
        
        // Canonicalize IDs via BFS from start state
        let mut queue = VecDeque::new();
        let start_block = partitions.iter().find(|p| p.contains(&self.start_state)).unwrap();
        
        state_to_id.insert(start_block.clone(), 0u32);
        id_to_block.insert(0u32, start_block.clone());
        queue.push_back(0u32);
        
        let mut next_id = 1u32;
        let mut dfa_transition = HashMap::new();
        let mut dfa_states = HashSet::new();
        dfa_states.insert(0);

        while let Some(id) = queue.pop_front() {
            let representative = id_to_block[&id].iter().next().unwrap().clone();
            
            for symbol in &self.alphabet {
                let target = &self.transition[&(representative.clone(), symbol.clone())];
                let target_block = partitions.iter().find(|p| p.contains(target)).unwrap();
                
                let target_id = if let Some(&tid) = state_to_id.get(target_block) {
                    tid
                } else {
                    let tid = next_id;
                    next_id += 1;
                    state_to_id.insert(target_block.clone(), tid);
                    id_to_block.insert(tid, target_block.clone());
                    dfa_states.insert(tid);
                    queue.push_back(tid);
                    tid
                };
                dfa_transition.insert((id, symbol.clone()), target_id);
            }
        }

        let mut dfa_accept_states = HashSet::new();
        for (id, block) in id_to_block {
            if block.iter().any(|s| self.accept_states.contains(s)) {
                dfa_accept_states.insert(id);
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

    fn reachable_states(&self) -> HashSet<S> {
        let mut visited = HashSet::new();
        let mut stack = vec![self.start_state.clone()];
        while let Some(state) = stack.pop() {
            if visited.insert(state.clone()) {
                for symbol in &self.alphabet {
                    stack.push(self.transition[&(state.clone(), symbol.clone())].clone());
                }
            }
        }
        visited
    }

    pub fn omega_lasso(&self, prefix_word: &[Sym], cycle_word: &[Sym]) -> Result<acceptance::LassoRun<S>, String> {
        if cycle_word.is_empty() {
            return Err("Cycle word cannot be empty".to_string());
        }

        let prefix_trace = self.run_trace(prefix_word);
        let mut current = prefix_trace.last().unwrap().clone();

        let mut seen_boundaries = HashMap::new();
        seen_boundaries.insert(current.clone(), 0);

        let mut iteration_traces = Vec::new();

        loop {
            let mut iter_trace = vec![current.clone()];
            for symbol in cycle_word {
                current = self.transition[&(current, symbol.clone())].clone();
                iter_trace.push(current.clone());
            }

            iteration_traces.push(iter_trace);
            let boundary_index = iteration_traces.len();

            if let Some(&repeat_start_iter) = seen_boundaries.get(&current) {
                let mut lasso_prefix = prefix_trace;
                for i in 0..repeat_start_iter {
                    lasso_prefix.extend(iteration_traces[i].iter().skip(1).cloned());
                }

                let mut lasso_cycle = vec![iteration_traces[repeat_start_iter][0].clone()];
                for i in repeat_start_iter..boundary_index {
                    lasso_cycle.extend(iteration_traces[i].iter().skip(1).cloned());
                }

                return Ok(acceptance::LassoRun {
                    prefix: lasso_prefix,
                    cycle: lasso_cycle,
                });
            }

            seen_boundaries.insert(current.clone(), boundary_index);
        }
    }
}

pub mod nfa;
pub mod regex;
pub mod acceptance;

#[cfg(test)]
mod tests {
    use super::*;
    use crate::regex::regex_to_nfa;

    #[test]
    fn test_dfa_basic() {
        let mut states = HashSet::new();
        states.insert("q0".to_string());
        states.insert("q1".to_string());

        let mut alphabet = HashSet::new();
        alphabet.insert('a');
        alphabet.insert('b');

        let mut transition = HashMap::new();
        transition.insert(("q0".to_string(), 'a'), "q1".to_string());
        transition.insert(("q0".to_string(), 'b'), "q0".to_string());
        transition.insert(("q1".to_string(), 'a'), "q1".to_string());
        transition.insert(("q1".to_string(), 'b'), "q0".to_string());

        let start_state = "q0".to_string();
        let mut accept_states = HashSet::new();
        accept_states.insert("q1".to_string());

        let dfa = DFA::new(states, alphabet, transition, start_state, accept_states).unwrap();

        assert!(dfa.accepts(&['a']));
        assert!(dfa.accepts(&['b', 'a']));
        assert!(!dfa.accepts(&['a', 'b']));
    }

    #[test]
    fn test_regex_to_nfa() {
        let nfa = regex_to_nfa("a|b*");
        assert!(nfa.accepts(&['a']));
        assert!(nfa.accepts(&['b', 'b', 'b']));
        assert!(nfa.accepts(&[])); // b* matches empty
        assert!(!nfa.accepts(&['c']));
    }

    #[test]
    fn test_nfa_to_dfa() {
        let nfa = regex_to_nfa("a(b|c)*");
        let dfa = nfa.to_dfa();
        assert!(dfa.accepts(&['a', 'b', 'c', 'b']));
        assert!(!dfa.accepts(&['b']));
    }

    #[test]
    fn test_dfa_minimization() {
        let nfa = regex_to_nfa("a|a");
        let dfa = nfa.to_dfa();
        let minimized = dfa.minimize();
        // "a|a" should minimize to a very small DFA
        assert!(minimized.states.len() <= dfa.states.len());
        assert!(minimized.accepts(&['a']));
    }
}
