#[cfg(kani)]
mod kani_proofs {
    use crate::recursive::*;

    #[kani::proof]
    fn kani_fact_positive() {
        let n: u64 = kani::any();
        kani::assume(n <= 20);
        let result = fact(n);
        kani::assert(result >= 1, "factorial is always >= 1");
    }

    #[kani::proof]
    fn kani_fib_non_negative() {
        let n: u64 = kani::any();
        kani::assume(n <= 30);
        let result = fib(n);
        kani::assert(result >= 0, "fibonacci is always >= 0");
    }

    #[kani::proof]
    fn kani_gcd_divides_a() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a > 0);
        kani::assume(b > 0);
        let g = gcd(a, b);
        kani::assert(a % g == 0, "gcd divides a");
    }

    #[kani::proof]
    fn kani_gcd_divides_b() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a > 0);
        kani::assume(b > 0);
        let g = gcd(a, b);
        kani::assert(b % g == 0, "gcd divides b");
    }

    #[kani::proof]
    fn kani_even_odd_exclusive() {
        let n: u64 = kani::any();
        kani::assume(n <= 100);
        let e = even(n);
        let o = odd(n);
        kani::assert(!(e && o), "even and odd are mutually exclusive");
    }

    #[kani::proof]
    fn kani_list_length_non_negative() {
        let len: u64 = kani::any();
        kani::assume(len <= 10);
        let mut list = List::nil();
        for i in 0..len {
            list = List::cons(i, list);
        }
        let result = length(&list);
        kani::assert(result == len, "list length matches construction");
    }

    #[kani::proof]
    fn kani_reverse_involution() {
        let len: u64 = kani::any();
        kani::assume(len <= 5);
        let mut list = List::nil();
        for i in 0..len {
            list = List::cons(i, list);
        }
        let rev = reverse(&list);
        let rev_rev = reverse(&rev);
        kani::assert(rev_rev == list, "reverse is an involution");
    }

    #[kani::proof]
    fn kani_add_commutative() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a <= 1000);
        kani::assume(b <= 1000);
        kani::assert(add(a, b) == add(b, a), "addition is commutative");
    }

    #[kani::proof]
    fn kani_mul_commutative() {
        let a: u64 = kani::any();
        let b: u64 = kani::any();
        kani::assume(a <= 100);
        kani::assume(b <= 100);
        kani::assert(mul(a, b) == mul(b, a), "multiplication is commutative");
    }
}
