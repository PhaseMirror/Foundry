"""Multi-Agent Recursive Cognition Layer (MARCL) and Ethical Alignment Protocol (EAP)."""

import math
from dataclasses import dataclass
from .core import LAMBDA_M
from .stabilization import SemanticVector, DynamicOperator, project_lambda_m, semantic_evolution_step

@dataclass
class AgentState:
    id: int
    psi: SemanticVector
    regret: float
    resilience: float

    @classmethod
    def new(cls, id: int, dim: int = 4) -> "AgentState":
        return cls(id, SemanticVector.equilibrium(dim), 0.0, 1.0)

    @staticmethod
    def compute_resilience(regret: float, gamma: float = 2.0) -> float:
        return max(0.01, min(1.0, math.exp(-gamma * regret)))

    def compute_discrepancy(self, bound: float = 0.65) -> float:
        proj = project_lambda_m(self.psi, bound)
        return self.psi.dist_sq(proj)

@dataclass
class MARCLCluster:
    time: int
    agents: list[AgentState]
    trust_matrix: list[list[float]]
    regret_tensor: list[list[float]]
    godelian_ledger: list[list[float]]

    @classmethod
    def new_4agents(cls) -> "MARCLCluster":
        agents = [AgentState.new(i, 4) for i in range(4)]
        trust_mat = [[1.0 if i == j else 0.5 for j in range(4)] for i in range(4)]
        regret_mat = [[0.0 for _ in range(4)] for _ in range(4)]
        ledger_mat = [[0.0 for _ in range(4)] for _ in range(4)]
        return cls(0, agents, trust_mat, regret_mat, ledger_mat)

    def inject_shock(self, agent_id: int, shock_vector: SemanticVector) -> None:
        if 0 <= agent_id < len(self.agents):
            self.agents[agent_id].psi = shock_vector
            self.agents[agent_id].regret = 0.8
            self.agents[agent_id].resilience = AgentState.compute_resilience(0.8)

    def compute_peer_correction(self, i: int) -> SemanticVector:
        curr = self.agents[i]
        dim = len(curr.psi.components)
        corrected = list(curr.psi.components)
        for k in range(dim):
            peer_sum = 0.0
            for j in range(len(self.agents)):
                if i != j:
                    peer = self.agents[j]
                    mu = self.trust_matrix[i][j]
                    peer_sum += mu * (peer.psi.components[k] - curr.psi.components[k])
            corrected[k] += 0.1 * peer_sum
        return SemanticVector(corrected)

    def step(self) -> "MARCLCluster":
        next_time = self.time + 1
        n = len(self.agents)
        eq = SemanticVector.equilibrium(4)
        id_op = DynamicOperator.identity(4)

        updated_agents = []
        for i in range(n):
            peer_corr = self.compute_peer_correction(i)
            local_evol = semantic_evolution_step(peer_corr, id_op, eq, LAMBDA_M)
            disc = local_evol.dist_sq(project_lambda_m(local_evol, 0.65))

            new_regret = min(1.0, self.agents[i].regret + 0.15) if disc > 0.02 else max(0.0, self.agents[i].regret - 0.10)
            new_resilience = AgentState.compute_resilience(new_regret)
            updated_agents.append(AgentState(i, local_evol, new_regret, new_resilience))

        next_trust = [list(row) for row in self.trust_matrix]
        for i in range(n):
            for j in range(n):
                if i != j:
                    disc_j = self.agents[j].compute_discrepancy()
                    if disc_j > 0.02:
                        next_trust[i][j] = max(0.05, self.trust_matrix[i][j] - 0.12)
                    else:
                        boost = 0.08 * updated_agents[j].resilience
                        next_trust[i][j] = min(0.85, self.trust_matrix[i][j] + boost)

        next_regret_tensor = [[0.0] * n for _ in range(n)]
        for i in range(n):
            for j in range(n):
                if i != j:
                    disc_j = updated_agents[j].compute_discrepancy()
                    next_regret_tensor[i][j] = 1.0 if disc_j > 0.02 else -1.0

        next_ledger = [list(row) for row in self.godelian_ledger]
        for i in range(n):
            for j in range(n):
                mu = next_trust[i][j]
                rho = updated_agents[j].resilience
                gamma = next_regret_tensor[i][j]
                flow = mu * rho * (-gamma) * 0.1
                next_ledger[i][j] += flow

        return MARCLCluster(next_time, updated_agents, next_trust, next_regret_tensor, next_ledger)

    def iterate(self, steps: int) -> "MARCLCluster":
        curr = self
        for _ in range(steps):
            curr = curr.step()
        return curr
