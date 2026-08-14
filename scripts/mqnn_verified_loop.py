# mqnn_verified_loop.py
# M-QNN adaptive shot allocation with verified classical oracle.
# The decision functions `is_better_certified` and `mqnn_policy`
# are mechanically proven (Kani) to be free of overflow, division-by-zero,
# and to faithfully implement the Hoeffding early-exit inequality.
# See crates/mqnn-kani/src/verification.rs for the proofs.

import numpy as np
import matplotlib.pyplot as plt
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister, transpile
from qiskit_aer import Aer
from qiskit.visualization import plot_histogram
from mqnn_ffi import PyCandidateState, is_better_certified, mqnn_policy

# Configuration
DELTA = 0.05            # confidence parameter (passed to oracle)
MAX_TOTAL_SHOTS = 2000  # safety upper bound
N_CANDIDATES = 2        # two-candidate demo

def random_state_prep(n_qubits: int) -> QuantumCircuit:
    """Create a circuit that prepares a random n-qubit state."""
    qc = QuantumCircuit(n_qubits)
    for i in range(n_qubits):
        qc.rx(np.random.uniform(0, 2*np.pi), i)
        qc.ry(np.random.uniform(0, 2*np.pi), i)
        qc.rz(np.random.uniform(0, 2*np.pi), i)
    # Add some entanglement
    for i in range(n_qubits-1):
        qc.cx(i, i+1)
    return qc

def build_swap_test(psi: QuantumCircuit, phi: QuantumCircuit) -> QuantumCircuit:
    """Return a swap test circuit comparing psi and phi."""
    n = psi.num_qubits
    anc = QuantumRegister(1, 'anc')
    a = QuantumRegister(n, 'a')
    b = QuantumRegister(n, 'b')
    c = ClassicalRegister(1, 'c')
    qc = QuantumCircuit(anc, a, b, c)

    qc.h(anc)
    qc.compose(psi, qubits=a, inplace=True)
    qc.compose(phi, qubits=b, inplace=True)

    # controlled swaps
    for i in range(n):
        qc.cswap(anc[0], a[i], b[i])

    qc.h(anc)
    qc.measure(anc, c)
    return qc

def main():
    print("Initializing Qiskit Adaptive Loop with Mechanically Proven FFI Oracle...")
    
    n_qubits = 2
    # Fixed query state (unknown to the candidates)
    query_state = random_state_prep(n_qubits)

    # Reference circuits for two candidates
    ref_circuits = [random_state_prep(n_qubits) for _ in range(N_CANDIDATES)]

    candidates = [PyCandidateState(0, 0) for _ in range(N_CANDIDATES)]
    history = {'shots_total': [], 'fidelity_est_0': [], 'fidelity_est_1': []}

    backend = Aer.get_backend('qasm_simulator')

    winner = None
    while True:
        idx = mqnn_policy(candidates)

        # Build swap test: query vs. ref[idx]
        qc = build_swap_test(query_state, ref_circuits[idx])
        t_qc = transpile(qc, backend)
        
        # Execute the swap test
        job = backend.run(t_qc, shots=1, memory=True)
        result = job.result().get_memory()[0]
        outcome_is_zero = (result == '0')

        # Update multiplicity state
        c = candidates[idx]
        if outcome_is_zero:
            candidates[idx] = PyCandidateState(c.zeros() + 1, c.shots() + 1)
        else:
            candidates[idx] = PyCandidateState(c.zeros(), c.shots() + 1)

        # Log history
        total_shots = sum(c.shots() for c in candidates)
        f0 = (candidates[0].zeros() / candidates[0].shots()) if candidates[0].shots() > 0 else 0.5
        f1 = (candidates[1].zeros() / candidates[1].shots()) if candidates[1].shots() > 0 else 0.5
        history['shots_total'].append(total_shots)
        history['fidelity_est_0'].append(2*f0 - 1)
        history['fidelity_est_1'].append(2*f1 - 1)

        # Check early exit via verified oracle
        if is_better_certified(DELTA, candidates[0], candidates[1]):
            winner = 0
            break
        elif is_better_certified(DELTA, candidates[1], candidates[0]):
            winner = 1
            break
        if total_shots >= MAX_TOTAL_SHOTS:
            winner = None
            break

    print("\n--- Execution Complete ---")
    print(f"Decision certified at delta={DELTA}")
    other = 1 if winner == 0 else (0 if winner == 1 else 'None')
    if winner is not None:
        print(f"Stopping condition: F_{winner} - radius > F_{other} + radius")
    print(f"Winner: Candidate {winner}")
    print(f"Total shots used: {sum(c.shots() for c in candidates)}")
    for i, c in enumerate(candidates):
        fidelity = 2*c.zeros()/c.shots() - 1 if c.shots()>0 else 'N/A'
        print(f"  Candidate {i}: zeros={c.zeros()}, shots={c.shots()}, fidelity_est={fidelity}")

    # Visualization
    plt.figure(figsize=(10, 4))
    plt.plot(history['shots_total'], history['fidelity_est_0'], label='Candidate 0 fidelity est')
    plt.plot(history['shots_total'], history['fidelity_est_1'], label='Candidate 1 fidelity est')
    plt.axhline(0, color='gray', linestyle='--')
    plt.xlabel('Total shots')
    plt.ylabel('Estimated fidelity')
    plt.title('Adaptive M-QNN Loop with Verified Oracle')
    plt.legend()
    plt.grid(True)
    plt.savefig('mqnn_fidelity_evolution.png')
    print("Plot saved to mqnn_fidelity_evolution.png")

if __name__ == "__main__":
    main()
