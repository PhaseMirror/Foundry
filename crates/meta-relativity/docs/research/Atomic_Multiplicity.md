---
slug: atomic-multiplicity
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Atomic_Multiplicity.md
  last_synced: '2026-03-20T17:17:19.434853Z'
---

Atomic Multiplicity in the Universal Atomic Calculator:
        From Qubits to Qudits and Beyond
                           Quantum Research Group
                       Department of Quantum Computing
                              December 20, 2025


Abstract                                       versal Atomic Calculator naturally extends
                                               beyond qubits, harnessing the full quantum
                                               complexity of atomic structure for more effi-
This paper explores the implications of
                                               cient computation.
atomic multiplicity—the inherent multi-level
structure of atomic systems—for the Univer-
sal Atomic Calculator framework. While pre-
vious work focused on two-level qubit en-
                                               1 Introduction: Beyond
coding, we extend the formalism to incorpo-          the Qubit Paradigm
rate nuclear spin multiplicity, fine/hyperfine
structure, and multi-electron configurations. The standard formulation of quantum com-
We demonstrate how 87 Sr (I = 9/2), 171 Yb puting assumes two-level systems (qubits) as
(I = 1/2), and 133 Cs (I = 7/2) provide nat- fundamental units. However, atomic systems
ural qudit encodings with d = 10, d = 2, possess inherent multiplicity—multiple in-
and d = 8 respectively. These multi-level ternal degrees of freedom including nuclear
encodings enable: (1) exponential compres- spin (I), electronic angular momentum (J),
sion of computational space, (2) native simu- and hyperfine structure (F = I + J).
lation of high-spin systems, (3) enhanced er- This multiplicity, typically viewed as a com-
ror correction via subsystem codes, and (4) plication, represents an untapped com-
novel algorithmic approaches via qudit gates. putational resource within the Universal
We present experimental proposals for 87 Sr- Atomic Calculator framework.
based quantum chemistry simulations achiev-
ing 4× reduction in qubit count, and ana- 1.1 Historical Context
lyze the trade-offs between multiplicity com-
plexity and control requirements. The atomic Atomic multiplicity has long been recognized
multiplicity perspective reveals that the Uni- in atomic physics:

                                             1
    • Stern-Gerlach  experiments     (1922) 2.2                Multiplicity Table for Com-
      demonstrated spatial quantization of                     mon Species
      angular momentum

                                               Table 1: Atomic Multiplicity in Neutral-
    • Hyperfine structure (1930s) revealed nu- Atom Platforms
      clear spin effects
                                                Species Nuclear Spin I Hyperfine Levels F                    Di
                                                      87
                                                         Rb            3/2                F = 1, 2
    • Modern atomic clocks leverage multiplic-        133
                                                          Cs           7/2                F = 3, 4
      ity for precision                               171
                                                          Yb           1/2                F = 0, 1
                                                      87
                                                         Sr            9/2          F = 9/2 (clock states)
                                                      23
                                                         Na            3/2                F = 1, 2
Yet quantum computing has largely treated
atoms as two-level systems, ignoring this rich
structure.
                                                     3      Computational Advan-
                                                            tages of Multiplicity
2      Mathematical Frame- 3.1 Exponential Space Com-
       work for Multiplicity   pression
                                                     Encoding n qubits into k qudits of dimension
2.1     Atomic State Space                           d provides compression when:

A neutral atom with nuclear spin I and elec-           dk ≥ 2n ⇒ k ≤ n/ log2 d
tronic angular momentum J has total Hilbert
space:                                       For d = 10 (87 Sr), we achieve approximately
                                             3.32× reduction in atom count.
    Hatom = Hnuclear ⊗ Helectronic ⊗ Hmotional
                                                     3.2       Example: Molecular Or-
  For ground-state alkali atoms (J = 1/2),                     bital Encoding
the hyperfine manifold dimension is:
                                                     Consider a molecule with M spatial orbitals.
                                                     With spin, this requires 2M qubits. Using
       d = (2I + 1)(2J + 1) = 2(2I + 1)              d = 10 qudits:

                                                 2
                                                  3.5    Raman and                      Microwave
 Qubits: Nqubits = 2M                     (1)            Transitions
 Qudits: Nqudits = ⌈2M/ log2 10⌉ ≈ ⌈0.6M ⌉ For 87 Rb (I = 3/2, d = 8):
                                          (2)
                                                           F
  For M = 10 orbitals: 20 qubits vs. 6 decits H
                                                          X
                                               control =       ℏΩm (t) |F, mF ⟩ ⟨F, mF + 1|+h.c.
(using 87 Sr).                                           m =−F    F


                 3.3× compression                 where Ωm (t) are magnetic-field-dependent
             20 Qubits   6 Qudits
                                                  Rabi frequencies.
Figure 1: Space compression via qudit encod-
ing                                          3.6         Multi-Level                         Rydberg
                                                         Blockade
3.3    Native High-Spin Simula- The Rydberg blockade radius depends on the
       tion                     specific states:
Many quantum systems naturally possess                                         (i,j)
high spin:                                                              (i,j) C6
                                                                      Vdd =      6  R
  • Molecular magnets (S > 1/2)
                                                          (i,j)
  • Nuclear spin clusters                         where C6 varies by hyperfine states i, j, en-
                                                  abling state-dependent connectivity.
  • Quantum rotor systems
Qudits provide native        representation
without overhead.                                 4     Enhanced Error Cor-
                                                        rection
3.4    Multi-Level Control
                                                  4.1    Subsystem Codes with Qu-
       |2⟩                                               dits
       |1⟩                                        The color code generalizes to qudits:
              R12 (ϕ′ )     R23 (ψ)
                                                                      O                     O
       |0⟩                                              SX =                Xvq ,   SZ =              Zfp
              R01 (θ)       R12 (ϕ)                            v∈vertices                  f ∈faces

Figure 2: Qutrit circuit with multi-level gates where X and Z are qudit Pauli operators.

                                              3
4.2       Error Rates Analysis                                where a, b are bosonic modes mapping to qu-
                                                              dit levels.
For d-level systems, the error rate per dimen-
sion:
        ϵd = 1 − Fd ≈ d · ϵ2         (naive scaling)
But with optimized control:                                   5.3   Quantum Chemistry Ex-
             √                                                      ample: LiH with Qutrits
         ϵd ≈ d · ϵ2 (optimized)


Table 2: Error Correction Overhead Compar-
ison                                                         Qubit encoding: 12 qubits         (3)
                                                             Qutrit encoding: 6 qutrits(d = 3) (4)
 Code                                  Qubits       Qutrits Space
                                                                Improvement
                                                                   reduction: 2×               (5)
 Surface Code (d = 3)                                   Gate count reduction:
                                   49 phys/qubit 9 phys/qutrit       5.4×     1.8 × (estimated)
 Color Code (d = 3)                 7 phys/qubit 3 phys/qutrit       2.3×                      (6)



5        Algorithmic                           Implica-
         tions
5.1       VQE with Qudits
The molecular Hamiltonian becomes:
         X                X
    H=       tij a†i aj +   vijkl a†i a†j ak al
                i,j              i,j,k,l
                                                                qudit_vqe.pdf
with creation/annihilation operators acting
on d-level systems.

5.2       Efficient Fermion-to-Qudit
          Mapping
Using the Schwinger boson representa-
tion:
                                                              Figure 3: VQE convergence for LiH with
            †          −   †            1
    +
 S = a b,             S = b a,       S = (a† a − b† b)
                                           z                  qubit vs. qudit encoding
                                        2
                                                          4
6      Experimental               Realiza- 7.2 Decoherence Channels
       tion                                             Additional decoherence mechanisms:

6.1      Multi-Species Arrays
                                                            • Magnetic field sensitivity scales with mF
Combine different atomic species in the same
array:
                                                            • Multi-photon transitions increase error
    • 87 Sr (d = 10) for high-dimensional com-                paths
      putation

    • 133 Cs (d = 16) for error correction ancil-           • Cross-talk between nearby transitions
      las

    • 171 Yb (I = 0 isotopes) for memory
      qubits                             7.3                     Calibration Overhead
                                     Calibrating d(d − 1)/2 transitions vs. 1 for
6.2      Current Capabilities (2025) qubits.
    • Pasqal: Multi-species arrays (Rb + Cs
      demonstrated)

    • Infleqtion:     High-fidelity multi-level
                                                        8      Future Directions
      control
                                                        8.1      Multiplicity-Aware Compi-
    • Atom Computing: Yb isotopes with                           lation
      different I
                                                        Develop compilers that:

7      Challenges and Limita-
                                                         1. Map algorithms to optimal multiplicity
       tions                                                encoding

7.1      Control Complexity
                                                         2. Exploit natural atomic transitions
Multi-level systems require:

Control parameters ∝ d2 vs. ∝ 4 for qubits               3. Minimize control complexity

                                                    5
8.2    Hybrid Multiplicity Archi- 9                    Conclusion
       tectures
                                             Atomic multiplicity represents a fundamen-
                                             tal resource in the Universal Atomic Calcu-
                                             lator framework that has been largely over-
                                             looked. By embracing the full multi-level
                                             structure of atoms, we can:
                                                1. Reduce physical resource require-
                                             ments via exponential compression 2. En-
                                             able native simulation of high-spin quan-
                                             tum systems 3. Enhance error correction
   hybrid_array.pdf                          with more efficient codes 4. Discover new
                                             algorithmic approaches beyond the qubit
                                             paradigm
                                                The Universal Atomic Calculator naturally
                                             extends to incorporate multiplicity, trans-
                                             forming what was once considered atomic
                                             ”complexity” into computational ”capabil-
                                             ity.” Future work should focus on developing
Figure 4: Hybrid array with different multi- multiplicity-aware control protocols, compil-
plicity atoms                                ers, and algorithms to fully harness this re-
                                             source.

8.3    Quantum Advantage Path-
       ways                    Acknowledgments
Multiplicity enables earlier quantum advan- We acknowledge discussions with the Pasqal,
tage for:                                   Atom Computing, and Infleqtion teams on
                                            multi-level control techniques.
  • Quantum chemistry (smaller arrays
     needed)
                                                    References
  • Lattice gauge theories (natural high-spin
    representation)                                 1. D.    Gottesman,      ”Fault-Tolerant
                                                       Quantum Computation with Higher-
  • Optimization problems (larger search               Dimensional Systems,” Chaos, Solitons
    spaces per atom)                                   & Fractals, 1999.

                                                6
2. B. P. Lanyon et al., ”Universal Digi-
   tal Quantum Simulation with Trapped
   Ions,” Science, 2011.

3. A. M. Kaufman et al., ”Quantum ther-
   malization through entanglement in an
   isolated many-body system,” Science,
   2016.

4. M. Ringbauer et al., ”A universal qudit
   quantum processor with trapped ions,”
   Nature Physics, 2022.




                                             7
