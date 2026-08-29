use recursive_foundations::recursive::*;

#[test]
fn test_fact() {
    assert_eq!(fact(0), 1);
    assert_eq!(fact(1), 1);
    assert_eq!(fact(5), 120);
    assert_eq!(fact(10), 3628800);
}

#[test]
fn test_fib() {
    assert_eq!(fib(0), 0);
    assert_eq!(fib(1), 1);
    assert_eq!(fib(2), 1);
    assert_eq!(fib(10), 55);
}

#[test]
fn test_gcd() {
    assert_eq!(gcd(12, 8), 4);
    assert_eq!(gcd(17, 13), 1);
    assert_eq!(gcd(100, 75), 25);
}

#[test]
fn test_add() {
    assert_eq!(add(0, 0), 0);
    assert_eq!(add(5, 3), 8);
    assert_eq!(add(100, 200), 300);
}

#[test]
fn test_mul() {
    assert_eq!(mul(0, 5), 0);
    assert_eq!(mul(5, 3), 15);
    assert_eq!(mul(10, 10), 100);
}

#[test]
fn test_list_operations() {
    let xs = List::cons(1, List::cons(2, List::cons(3, List::nil())));
    assert_eq!(length(&xs), 3);
    let rev = reverse(&xs);
    assert_eq!(length(&rev), 3);
    let rev_rev = reverse(&rev);
    assert_eq!(rev_rev, xs);
}

#[test]
fn test_tree_operations() {
    let t = Tree::node(1, Tree::node(2, Tree::leaf(), Tree::leaf()), Tree::node(3, Tree::leaf(), Tree::leaf()));
    assert_eq!(tree_size(&t), 3);
    let mir = mirror(&t);
    assert_eq!(tree_size(&mir), 3);
}

#[test]
fn test_even_odd() {
    assert!(even(0));
    assert!(!even(1));
    assert!(even(2));
    assert!(!even(3));
    assert!(odd(1));
    assert!(odd(3));
    assert!(!odd(2));
}

#[test]
fn test_ackermann() {
    assert_eq!(ackermann(0, 0), 1);
    assert_eq!(ackermann(1, 0), 2);
    assert_eq!(ackermann(0, 5), 6);
}
