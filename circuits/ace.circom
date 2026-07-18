pragma circom 2.0.0;

template TestCircuit() {
    signal input a;
    signal output b;
    b <== a + 1;
}

component main = TestCircuit();
