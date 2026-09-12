"""Quantum circuit generation and OpenQASM export for Langlands operators."""

import math
from dataclasses import dataclass, field
from .core import PHI, dirichlet_char_4, dirichlet_euler_factor
from .cascade import PrismTensorState

@dataclass
class QuantumGate:
    name: str
    qubits: list[int]
    params: list[float] = field(default_factory=list)
    comment: str = ""

@dataclass
class QuantumLanglandsCircuit:
    num_qubits: int
    gates: list[QuantumGate] = field(default_factory=list)

    @classmethod
    def from_tensor_state(cls, st: PrismTensorState) -> "QuantumLanglandsCircuit":
        num_qubits = len(st.nodes)
        qc = cls(num_qubits)

        for q in range(num_qubits):
            qc.gates.append(QuantumGate("h", [q]))

        for q, node in enumerate(st.nodes):
            p = node.prime
            chi = dirichlet_char_4(p)
            l_fac = dirichlet_euler_factor(p, 1.0, chi)
            angle = (2.0 * math.pi * p * PHI * (st.time + 1) * l_fac) % (2.0 * math.pi)
            qc.gates.append(QuantumGate("rz", [q], [angle]))
            osc_angle = math.sin(2.0 * math.pi * p * PHI * (st.time + 1))
            qc.gates.append(QuantumGate("rx", [q], [osc_angle], f"L_phi(p={p})"))

        for i in range(num_qubits - 1):
            j = i + 1
            angle = (math.pi / st.nodes[i].prime) * st.lambda_m
            qc.gates.append(QuantumGate("cp", [i, j], [angle]))

        return qc

    def to_openqasm(self) -> str:
        lines = [
            "OPENQASM 2.0;",
            'include "qelib1.inc";',
            "",
            f"qreg q[{self.num_qubits}];",
            f"creg c[{self.num_qubits}];",
            "",
        ]

        for gate in self.gates:
            if gate.name == "h":
                lines.append(f"h q[{gate.qubits[0]}];")
            elif gate.name == "rz":
                lines.append(f"rz({gate.params[0]:.6f}) q[{gate.qubits[0]}];")
            elif gate.name == "rx":
                comment = f" // {gate.comment}" if gate.comment else ""
                lines.append(f"rx({gate.params[0]:.6f}) q[{gate.qubits[0]}];{comment}")
            elif gate.name == "cp":
                lines.append(f"cp({gate.params[0]:.6f}) q[{gate.qubits[0]}], q[{gate.qubits[1]}];")
            elif gate.name == "swap":
                lines.append(f"swap q[{gate.qubits[0]}], q[{gate.qubits[1]}];")

        lines.append("")
        lines.append("measure q -> c;")
        return "\n".join(lines) + "\n"
