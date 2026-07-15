# ADR-005: Multiplicity Stablecoin (MSC) Valuation Equation

## Status
**Planned**

## Context
A major shortcoming in traditional tokenomics is the disconnect between the token's speculative price and the actual health, structural coherence, or utility of the underlying ecosystem. Multiplicity Social Physics introduces the **Multiplicity Stablecoin (MSC)** to bridge this gap. 

For the MSC to function correctly, its value must be intrinsically mathematically linked to the structural viability of the network—specifically, the sovereignty index ($S$) and the systemic coherence/centralization variables ($C$). If the network thrives and maintains embodied health, the token value structurally climbs from the baseline ($1) to its multiplicity ($2) and saturation ($3) targets. If this logic is left to arbitrary smart contracts or external oracles without formally verified guarantees, the economic incentive structure can decouple from the social physics axioms.

## Decision
We will hardcode the valuation convergence theorem ($V_{MSC} = 1 + S + C$) into the **Sedona Spine** as the sole oracle and mathematical source of truth.

1. **Valuation as Kernel State:** The target valuation calculation will be executed directly inside the Rust engine, deriving its inputs from the validated Lifebushido graph and the Embodied Stress/Capacity metrics ($\mathcal{E}$).
2. **Phase Mirror Mint/Burn:** The algorithm governing the minting and burning of tokens (which drives $V_{MSC}$ towards $V_{target}$) will be dictated by Phase Mirror governance rules formally verified in Lean 4.
3. **No External Oracles for Health:** Network health variables ($S$ and $C$) are endogenous calculations verified by the Rust engine, not external price feeds.

## Formal Proof Obligations

To guarantee economic stability, we must mathematically prove that the valuation dynamics converge to the intended target value, corresponding to **Theorem 10: Valuation Convergence** from `MSP_2.md`.

### 1. Proof of Valuation Convergence
We must prove that given the mint/burn rates ($\kappa_{mint}$ and $\kappa_{burn}$), the differential equation governing the token's value strictly converges to $V_{target}$ over time.

**Lean 4 Formalization Sketch:**
```lean
import ADR.Core

namespace ADR.CryptoEconomic

/-- Define the target valuation based on Sovereignty and Coherence variables -/
def V_target (S C : ℝ) : ℝ := 1 + S + C

/-- Error between current MSC value and target value -/
def valuation_error (V_MSC V_target : ℝ → ℝ) (t : ℝ) : ℝ := 
  V_MSC t - V_target t

/-- Theorem: Given positive minting and burning rates, the valuation error converges to zero -/
@[proof]
theorem msc_valuation_convergence
  (V_MSC V_targ : ℝ → ℝ)
  (κ_mint κ_burn : ℝ)
  (h_mint : κ_mint > 0)
  (h_burn : κ_burn > 0)
  (dynamics : ∀ t, d(valuation_error V_MSC V_targ t)/dt = -(κ_mint + κ_burn) * valuation_error V_MSC V_targ t) :
  ∀ ε > 0, ∃ T : ℝ, ∀ t > T, |V_MSC t - V_targ t| < ε := by
  -- Proof that the error strictly decays exponentially, ensuring that
  -- the Phase Mirror governance successfully stabilizes the token.
  sorry
```

## Consequences

### Positive
- **Aligned Incentives**: The economic value of the network is perfectly isomorphic to the embodied health and structural integrity of its participants.
- **Predictable Tokenomics**: Because the valuation converges mathematically via Theorem 10, the token avoids arbitrary speculative bubbles or unwarranted collapses.
- **Verified Oracles**: By keeping the structural parameters strictly within the Rust kernel and proving their behaviour in Lean 4, we eliminate smart contract vulnerabilities related to oracle manipulation.

### Negative
- **On-chain vs. Off-chain Bridging**: Since the Rust kernel computes the true valuation, pushing this securely to an actual blockchain smart contract (e.g., Ethereum or a rollup) introduces a complex bridging mechanism.
- **Complex Dependency**: The valuation is now directly dependent on user metrics (Embodied Check-Ins). If user participation drops, the data stream for computing $S$ and $C$ becomes sparse, potentially stalling the valuation updates.

## Implementation Steps
1. Formalize the `V_target` definitions and the `msc_valuation_convergence` theorem in Lean 4 (`ADR/CryptoEconomic.lean`).
2. Implement the mathematical equivalents in the Sedona Spine (`src/economics.rs`), consuming metrics from the `social_graph.rs` modules.
3. Write test harnesses verifying that if $S$ or $C$ changes due to graph topology changes (e.g., adding a Triad), the engine immediately recalculates the correct target trajectory.
4. Design the cryptographic signature process so the Rust engine can act as a trusted, verifiable oracle payload generator for the on-chain smart contracts.
