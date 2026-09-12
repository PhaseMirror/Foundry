use crate::nfa::NFA;
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone)]
struct Fragment {
    start: usize,
    end: usize,
}

struct StateFactory {
    next: usize,
}

impl StateFactory {
    fn new() -> Self {
        StateFactory { next: 0 }
    }

    fn new_state(&mut self) -> usize {
        let state = self.next;
        self.next += 1;
        state
    }
}

const CONCAT: char = '.';
const OPERATORS: [char; 5] = ['|', CONCAT, '*', '+', '?'];

fn precedence(op: char) -> i32 {
    match op {
        '|' => 1,
        CONCAT => 2,
        '*' | '+' | '?' => 3,
        _ => 0,
    }
}

pub fn regex_to_nfa(pattern: &str) -> NFA<usize, char> {
    let pattern = if pattern.is_empty() { "ε" } else { pattern };
    let tokens = tokenize(pattern);
    let explicit = insert_concat(tokens);
    let postfix = to_postfix(explicit);
    postfix_to_nfa(postfix)
}

fn tokenize(pattern: &str) -> Vec<char> {
    let mut tokens = Vec::new();
    let mut chars = pattern.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '\\' {
            if let Some(next) = chars.next() {
                tokens.push(next);
            }
        } else {
            tokens.push(ch);
        }
    }
    tokens
}

fn is_operand(token: char) -> bool {
    !OPERATORS.contains(&token) && token != '(' && token != ')'
}

fn insert_concat(tokens: Vec<char>) -> Vec<char> {
    if tokens.is_empty() {
        return Vec::new();
    }
    let mut out = Vec::new();
    for i in 0..tokens.len() {
        let token = tokens[i];
        out.push(token);
        if i == tokens.len() - 1 {
            continue;
        }
        let next = tokens[i + 1];
        let left_allows = is_operand(token) || token == ')' || token == '*' || token == '+' || token == '?';
        let right_allows = is_operand(next) || next == '(';
        if left_allows && right_allows {
            out.push(CONCAT);
        }
    }
    out
}

fn to_postfix(tokens: Vec<char>) -> Vec<char> {
    let mut output = Vec::new();
    let mut stack = Vec::new();
    for token in tokens {
        if is_operand(token) {
            output.push(token);
        } else if token == '(' {
            stack.push(token);
        } else if token == ')' {
            while let Some(&top) = stack.last() {
                if top == '(' { break; }
                output.push(stack.pop().unwrap());
            }
            stack.pop();
        } else {
            while let Some(&top) = stack.last() {
                if top == '(' { break; }
                if precedence(top) >= precedence(token) {
                    output.push(stack.pop().unwrap());
                } else {
                    break;
                }
            }
            stack.push(token);
        }
    }
    while let Some(op) = stack.pop() {
        output.push(op);
    }
    output
}

fn add_edge(transitions: &mut HashMap<(usize, Option<char>), HashSet<usize>>, src: usize, sym: Option<char>, dst: usize) {
    transitions.entry((src, sym)).or_insert_with(HashSet::new).insert(dst);
}

fn postfix_to_nfa(postfix: Vec<char>) -> NFA<usize, char> {
    let mut stack: Vec<Fragment> = Vec::new();
    let mut transitions = HashMap::new();
    let mut alphabet = HashSet::new();
    let mut states = HashSet::new();
    let mut factory = StateFactory::new();

    for token in postfix {
        if is_operand(token) {
            let start = factory.new_state();
            let end = factory.new_state();
            states.insert(start);
            states.insert(end);
            if token == 'ε' {
                add_edge(&mut transitions, start, None, end);
            } else {
                alphabet.insert(token);
                add_edge(&mut transitions, start, Some(token), end);
            }
            stack.push(Fragment { start, end });
        } else if token == '*' || token == '+' || token == '?' {
            let frag = stack.pop().unwrap();
            let start = factory.new_state();
            let end = factory.new_state();
            states.insert(start);
            states.insert(end);
            if token == '*' {
                add_edge(&mut transitions, start, None, frag.start);
                add_edge(&mut transitions, start, None, end);
                add_edge(&mut transitions, frag.end, None, frag.start);
                add_edge(&mut transitions, frag.end, None, end);
            } else if token == '+' {
                add_edge(&mut transitions, start, None, frag.start);
                add_edge(&mut transitions, frag.end, None, frag.start);
                add_edge(&mut transitions, frag.end, None, end);
            } else { // '?'
                add_edge(&mut transitions, start, None, frag.start);
                add_edge(&mut transitions, start, None, end);
                add_edge(&mut transitions, frag.end, None, end);
            }
            stack.push(Fragment { start, end });
        } else if token == CONCAT {
            let right = stack.pop().unwrap();
            let left = stack.pop().unwrap();
            add_edge(&mut transitions, left.end, None, right.start);
            stack.push(Fragment { start: left.start, end: right.end });
        } else if token == '|' {
            let right = stack.pop().unwrap();
            let left = stack.pop().unwrap();
            let start = factory.new_state();
            let end = factory.new_state();
            states.insert(start);
            states.insert(end);
            add_edge(&mut transitions, start, None, left.start);
            add_edge(&mut transitions, start, None, right.start);
            add_edge(&mut transitions, left.end, None, end);
            add_edge(&mut transitions, right.end, None, end);
            stack.push(Fragment { start, end });
        }
    }

    let final_frag = stack.pop().unwrap();
    NFA {
        states,
        alphabet,
        transition: transitions,
        start_state: final_frag.start,
        accept_states: [final_frag.end].iter().cloned().collect(),
    }
}
