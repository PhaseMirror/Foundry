import unittest
from langlands_prism import (
    LAMBDA_M,
    PHI,
    first_n_primes,
    dirichlet_char_4,
    dirichlet_euler_factor,
    PrismTensorState,
    GaloisAction,
    PrimePermute,
    apply_galois_action,
    compute_langlands_dual_tensor,
    entanglement_fidelity,
    gravitational_wave_modulation,
    SemanticVector,
    simulate_shock_recovery,
    MARCLCluster,
    ETHICAL_THRESHOLD,
    compute_ethical_metric,
    firewall_gate,
    ProvenanceLedger,
    QuantumLanglandsCircuit,
)

class TestLanglandsPrism(unittest.TestCase):
    def test_primes_and_dirichlet(self):
        p5 = first_n_primes(5)
        self.assertEqual(p5, [2, 3, 5, 7, 11])
        self.assertEqual(dirichlet_char_4(1), 1)
        self.assertEqual(dirichlet_char_4(2), 0)
        self.assertEqual(dirichlet_char_4(3), -1)
        self.assertEqual(dirichlet_char_4(5), 1)

        ef_5 = dirichlet_euler_factor(5, 1.0, 1)
        self.assertAlmostEqual(ef_5, 1.25, places=5)

    def test_tensor_cascade(self):
        primes = [2, 3, 5, 7, 11]
        st = PrismTensorState.new_with_primes(primes, LAMBDA_M)
        self.assertEqual(len(st.nodes), 5)
        self.assertEqual(st.time, 0)

        st1 = st.step()
        self.assertEqual(st1.time, 1)
        self.assertTrue(st1.is_stable)
        self.assertLessEqual(st1.coherence, 1.0)

    def test_galois_duality(self):
        primes = [2, 3, 5, 7, 11]
        st = PrismTensorState.new_with_primes(primes, LAMBDA_M)
        perm = apply_galois_action(st, PrimePermute(0, 1))
        self.assertEqual(perm.nodes[0].prime, 3)
        self.assertEqual(perm.nodes[1].prime, 2)

        dual = compute_langlands_dual_tensor(st)
        self.assertEqual(len(dual.nodes), 5)
        fid = entanglement_fidelity(st, dual)
        self.assertGreaterEqual(fid, 0.0)
        self.assertLessEqual(fid, 1.0)

    def test_shock_recovery(self):
        shock = SemanticVector([0.95, 0.95, 0.95, 0.95])
        target = SemanticVector.equilibrium(4)
        traj = simulate_shock_recovery(shock, target, 12)
        d_init = traj[0][1]
        d_final = traj[-1][1]
        self.assertLess(d_final, d_init)
        self.assertLess(d_final, 0.02)

    def test_marcl_cluster(self):
        cluster = MARCLCluster.new_4agents()
        shock = SemanticVector([0.95, 0.95, 0.95, 0.95])
        cluster.inject_shock(3, shock)

        init_trust = cluster.trust_matrix[0][3]
        step1 = cluster.step()
        shock_trust = step1.trust_matrix[0][3]
        self.assertLess(shock_trust, init_trust)

        recovered = step1.iterate(10)
        self.assertGreater(recovered.trust_matrix[0][3], shock_trust)

    def test_firewall_and_provenance(self):
        primes = [2, 3, 5, 7, 11]
        st = PrismTensorState.new_with_primes(primes, LAMBDA_M)
        safe_st, triggered = firewall_gate(st)
        self.assertFalse(triggered)
        self.assertLessEqual(compute_ethical_metric(safe_st), ETHICAL_THRESHOLD)

        ledger = ProvenanceLedger()
        ledger.record_state(st)
        ledger.record_state(st.step())
        self.assertEqual(len(ledger.blocks), 2)
        self.assertTrue(ledger.verify_chain_integrity())

    def test_quantum_circuit(self):
        primes = [2, 3, 5]
        st = PrismTensorState.new_with_primes(primes, LAMBDA_M)
        qc = QuantumLanglandsCircuit.from_tensor_state(st)
        self.assertEqual(qc.num_qubits, 3)
        qasm = qc.to_openqasm()
        self.assertIn("OPENQASM 2.0;", qasm)
        self.assertIn("qreg q[3];", qasm)

if __name__ == "__main__":
    unittest.main()
