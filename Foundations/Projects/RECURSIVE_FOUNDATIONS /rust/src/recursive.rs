use crate::error::RecursiveError;
use crate::Result;

/// Natural number type with zero and successor.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Nat {
    Zero,
    Succ(u64),
}

impl Nat {
    pub fn zero() -> Self { Nat::Zero }
    pub fn one() -> Self { Nat::Succ(0) }
    pub fn succ(n: u64) -> Self { Nat::Succ(n) }
    pub fn pred(&self) -> u64 {
        match self {
            Nat::Zero => 0,
            Nat::Succ(n) => *n,
        }
    }
}

/// Addition of natural numbers.
pub fn add(n: u64, m: u64) -> u64 {
    n + m
}

/// Multiplication of natural numbers.
pub fn mul(n: u64, m: u64) -> u64 {
    n * m
}

/// Factorial function.
pub fn fact(n: u64) -> u64 {
    match n {
        0 => 1,
        _ => mul(n, fact(n - 1)),
    }
}

/// Fibonacci function.
pub fn fib(n: u64) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => add(fib(n - 1), fib(n - 2)),
    }
}

/// Greatest common divisor via Euclidean algorithm.
pub fn gcd(a: u64, b: u64) -> u64 {
    match b {
        0 => a,
        _ => gcd(b, a % b),
    }
}

/// List type.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum List<T> {
    Nil,
    Cons(T, Box<List<T>>),
}

impl<T> List<T> {
    pub fn nil() -> Self { List::Nil }
    pub fn cons(x: T, xs: List<T>) -> Self { List::Cons(x, Box::new(xs)) }
    pub fn is_nil(&self) -> bool { matches!(self, List::Nil) }
}

/// Append two lists.
pub fn append<T: Clone>(xs: &List<T>, ys: &List<T>) -> List<T> {
    match xs {
        List::Nil => ys.clone(),
        List::Cons(x, xs_tail) => List::Cons(x.clone(), Box::new(append(xs_tail, ys))),
    }
}

/// Reverse a list.
pub fn reverse<T: Clone>(xs: &List<T>) -> List<T> {
    match xs {
        List::Nil => List::Nil,
        List::Cons(x, xs_tail) => append(&reverse(xs_tail), &List::Cons(x.clone(), Box::new(List::Nil))),
    }
}

/// Length of a list.
pub fn length<T>(xs: &List<T>) -> u64 {
    match xs {
        List::Nil => 0,
        List::Cons(_, xs_tail) => 1 + length(xs_tail),
    }
}

/// Binary tree type.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Tree<T> {
    Leaf,
    Node(T, Box<Tree<T>>, Box<Tree<T>>),
}

impl<T> Tree<T> {
    pub fn leaf() -> Self { Tree::Leaf }
    pub fn node(x: T, l: Tree<T>, r: Tree<T>) -> Self { Tree::Node(x, Box::new(l), Box::new(r)) }
}

/// Size of a tree (number of nodes).
pub fn tree_size<T>(t: &Tree<T>) -> u64 {
    match t {
        Tree::Leaf => 0,
        Tree::Node(_, l, r) => 1 + add(tree_size(l), tree_size(r)),
    }
}

/// Mirror a binary tree.
pub fn mirror<T: Clone>(t: &Tree<T>) -> Tree<T> {
    match t {
        Tree::Leaf => Tree::Leaf,
        Tree::Node(x, l, r) => Tree::Node(x.clone(), Box::new(mirror(r)), Box::new(mirror(l))),
    }
}

/// Even predicate.
pub fn even(n: u64) -> bool {
    match n {
        0 => true,
        _ => !even(n - 1),
    }
}

/// Odd predicate.
pub fn odd(n: u64) -> bool {
    match n {
        0 => false,
        _ => !odd(n - 1),
    }
}

/// Fixed point combinator (Y combinator) for Rust.
pub fn y<A, B>(f: &dyn Fn(&dyn Fn(A) -> B, A) -> B, x: A) -> B {
    f(&move |x| y(f, x), x)
}

/// Ackermann function using well-founded recursion.
pub fn ackermann(m: u64, n: u64) -> u64 {
    match m {
        0 => n + 1,
        _ => {
            let mut result = 1;
            for _ in 0..m {
                result = ackermann(m - 1, if n == 0 { 1 } else { result });
            }
            result
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fact() {
        assert_eq!(fact(0), 1);
        assert_eq!(fact(1), 1);
        assert_eq!(fact(5), 120);
    }

    #[test]
    fn test_fib() {
        assert_eq!(fib(0), 0);
        assert_eq!(fib(1), 1);
        assert_eq!(fib(10), 55);
    }

    #[test]
    fn test_gcd() {
        assert_eq!(gcd(12, 8), 4);
        assert_eq!(gcd(17, 13), 1);
    }

    #[test]
    fn test_list() {
        let xs = List::cons(1, List::cons(2, List::cons(3, List::nil())));
        assert_eq!(length(&xs), 3);
        let rev = reverse(&xs);
        assert_eq!(length(&rev), 3);
    }

    #[test]
    fn test_even_odd() {
        assert!(even(0));
        assert!(!even(1));
        assert!(even(2));
        assert!(!odd(0));
        assert!(odd(1));
        assert!(!odd(2));
    }
}
