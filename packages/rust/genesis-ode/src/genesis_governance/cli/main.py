import argparse
import json
import sys
from datetime import datetime
from typing import List
import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.exploder.engine import ExploderEngine
from genesis_governance.exploder.perturbations import AmplitudeRamp, DragSpike, ContradictionInflation, FrequencyShift, CouplingWeightSpike
from genesis_governance.exploder.batch import BatchRunner
from genesis_governance.shared.history import HistoryStore
from genesis_governance.governance.review import summarize_proposal
from genesis_governance.builder.engine import BuilderEngine
from genesis_governance.schemas.shrapnel import ShrapnelMap
from genesis_governance.types import SurfaceState, MultiSubstrateState
from genesis_governance.multiplicity.encoder import MultiplicityEncoder
from genesis_governance.multiplicity.decoder import MultiplicityDecoder
from genesis_governance.multiplicity.allocator import PrimeBandAllocator
from genesis_governance.harness.cross_coupling import CrossSubstrateHarness

def main():
    parser = argparse.ArgumentParser(description="Genesis Governance CLI")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # 1. Run Command (Single trajectory)
    run_parser = subparsers.add_parser("run", help="Run a single adversarial trajectory")
    run_parser.add_argument("--substrate", type=str, default="Met", help="Substrate class")
    run_parser.add_argument("--coherence", type=float, default=0.9, help="Initial Cx")
    run_parser.add_argument("--stress", type=float, default=0.1, help="Initial S_eff")
    run_parser.add_argument("--ramp", type=float, default=0.1, help="Amplitude ramp rate")
    run_parser.add_argument("--output", type=str, default="output/last_run.json", help="Output path")

    # 2. Sweep Command (Batch execution)
    sweep_parser = subparsers.add_parser("sweep", help="Run a parameter sweep")
    sweep_parser.add_argument("--param", type=str, default="ramp_rate", help="Parameter to sweep (ramp_rate, magnitude, inflation_rate)")
    sweep_parser.add_argument("--values", type=float, nargs="+", default=[0.05, 0.1, 0.2, 0.5], help="Values to sweep")
    sweep_parser.add_argument("--output", type=str, default="output/sweep_results.json", help="Output path")

    # 3. Sweep-Cross Command (Heterogeneous coupling)
    cross_parser = subparsers.add_parser("sweep-cross", help="Run a heterogeneous cross-coupling sweep")
    cross_parser.add_argument("--kappa_values", type=float, nargs="+", default=[0.0, 0.1, 0.2, 0.5], help="Kappa values to sweep")
    cross_parser.add_argument("--output", type=str, default="output/cross_sweep_results.json", help="Output path")

    # 4. Review Command (Interactive governance)
    review_parser = subparsers.add_parser("review", help="Review a ShrapnelMap and generate GovernancePacket")
    review_parser.add_argument("--input", type=str, help="Path to shrapnel_map JSON")
    review_parser.add_argument("--trajectory", action="store_true", help="Summarize recent history and suggest prime preferences")

    # 5. Sensitivity-Sweep Command (Meta-tuning)
    sensitivity_parser = subparsers.add_parser("sensitivity-sweep", help="Run sensitivity analysis and re-allocate prime bands")
    sensitivity_parser.add_argument("--score_min", type=float, default=0.80, help="Re-allocate if avg score below this")
    sensitivity_parser.add_argument("--delta_max", type=float, default=0.15, help="Re-allocate if max delta above this")

    # 6. Report Command (Externalization)
    report_parser = subparsers.add_parser("report", help="Generate a comprehensive governance and self-tuning report")
    report_parser.add_argument("--self-tuning", action="store_true", help="Include detailed self-tuning trends")
    report_parser.add_argument("--leverage", action="store_true", help="Include collaboration and external surface summary")
    report_parser.add_argument("--output", type=str, default="output/governance_report.md", help="Output path")

    # 7. Contrib Command (Collaboration)
    contrib_parser = subparsers.add_parser("contrib", help="Standardized scaffolds for external contributions")
    contrib_parser.add_argument("--template", choices=["substrate", "perturbation"], required=True, help="Template type")
    contrib_parser.add_argument("--name", type=str, required=True, help="Name of the new component")

    args = parser.parse_args()

    # Shared Setup
    core = ScalarCore()
    history_store = HistoryStore()
    allocator = PrimeBandAllocator(history_store)
    encoder = MultiplicityEncoder(allocator)
    decoder = MultiplicityDecoder(allocator)
    exploder = ExploderEngine(core, encoder=encoder, decoder=decoder)
    
    if args.command == "report":
        print("Generating Self-Tuning Report...")
        history = history_store.history
        if not history:
            print("No history found.")
            return

        recon_history = history_store.get_reconstruction_history()
        avg_recon = np.mean([r["score"] for r in recon_history]) if recon_history else 0.0
        
        report_content = [
            "# Genesis Governance v0.5.0 Self-Tuning Report\n",
            f"**Generated at:** {datetime.utcnow().isoformat()}Z\n",
            f"**Total Runs:** {len(history)}\n",
            f"**Average Multiplicity Reconstruction:** {avg_recon:.4f}\n",
            "## Substrate Coverage\n",
            "| Substrate | Fragment Count | Avg Drift |",
            "|---|---|---|"
        ]
        
        sub_stats = {}
        for run in history:
            for frag in run.get("fragments", []):
                sid = frag.get("target_id")
                sub_stats.setdefault(sid, {"count": 0, "drifts": []})
                sub_stats[sid]["count"] += 1
                sub_stats[sid]["drifts"].append(frag.get("observed_drift", {}).get("coherence_drift", 0.0))
        
        for sid, stats in sub_stats.items():
            avg_d = np.mean(stats["drifts"])
            report_content.append(f"| {sid} | {stats['count']} | {avg_d:.4f} |")
            
        report_content.append("\n## Prime-Band Allocation Strategy\n")
        report_content.append(f"**Current Mapping:** {allocator.allocate()}\n")
        
        if args.leverage:
            report_content.append("\n## External Leverage & Collaboration Surface\n")
            report_content.append("- **Protocol Status:** ADR-011 Active\n")
            report_content.append("- **Surface Surface:** CONTRIBUTING.md established\n")
            report_content.append("- **Scaffold Availability:** `genesis contrib --template` live\n")
            report_content.append("- **Innovation Budget:** Enforced via [I/S] tiering\n")

        with open(args.output, "w") as f:
            f.write("\n".join(report_content))
        print(f"Report saved to {args.output}")
        return

    if args.command == "contrib":
        print(f"Generating {args.template} template for '{args.name}'...")
        if args.template == "substrate":
            content = f"# {args.name} Substrate Template\n# Inherits from SurfaceState\n"
        else:
            content = f"class {args.name}(PerturbationFamily):\n    # Implement apply() method\n"
        
        target_path = f"src/genesis_governance/exploder/{args.name.lower()}_template.py"
        with open(target_path, "w") as f:
            f.write(content)
        print(f"Template created at {target_path}. Respect the quarantine rules!")
        return

    if args.command == "review" and args.trajectory:
        history = history_store.history
        if not history:
            print("No history found in output/run_history.json")
            return
            
        print("\n=== PRIME TRAJECTORY REFLECTION ===")
        print(f"Total Runs Analyzed: {len(history)}")
        
        # Aggregate statistics
        total_tau = 0.0
        classes = {}
        substrates = set()
        recon_scores = []
        
        for run in history:
            total_tau += run.get("overall_tau", 0.0)
            for frag in run.get("fragments", []):
                cls = frag.get("fragility_class")
                classes[cls] = classes.get(cls, 0) + 1
                substrates.add(frag.get("target_id"))
                
                # Extract reconstruction score from multiplicity metadata
                m_meta = frag.get("metadata", {}).get("multiplicity", {})
                score = m_meta.get("reconstruction_score")
                if score is not None:
                    recon_scores.append(score)
        
        avg_tau = total_tau / len(history)
        print(f"Average Tau: {avg_tau:.4f}")
        print(f"Substrates Explored: {list(substrates)}")
        print(f"Fragility Class Counts: {classes}")
        
        if recon_scores:
            avg_recon = sum(recon_scores) / len(recon_scores)
            print(f"Average Multiplicity Reconstruction Score: {avg_recon:.4f}")
        
        print("\nSuggested Prime Preferences:")
        if avg_tau < 0.5:
            print("- High Stress Detected: Shift toward recovery-field calibration [Lane A].")
        if len(substrates) < 3:
            print("- Low Heterogeneity: Increase weight on coupled Lane A/B cross-sweeps.")
        if classes.get("impedance-spike-precursor", 0) > 2:
            print("- Saturation Risks: Refine drag-acceleration threshold flags.")
        if recon_scores and avg_recon < 0.85:
            print("- Encoding Drift: Refine prime-exponent mapping for higher locality/invertibility.")
        print("====================================")
        return

    if args.command == "sensitivity-sweep":
        print("Running Allocator Sensitivity Sweep...")
        reallocated = allocator.sensitivity_sweep(
            score_threshold=args.score_min,
            delta_threshold=args.delta_max
        )
        if reallocated:
            print(f"RE-ALLOCATION TRIGGERED. New Mapping: {allocator.allocate()}")
        else:
            print("Current allocation remains stable. No drift detected.")
        return

    if args.command == "sweep-cross":
        # Multi-substrate setup (Path A baseline + Lane C)
        state_met = SurfaceState(substrate="Met", coherence=0.9, stability_threshold=1.0, effective_stress=0.1, frequency=1.0)
        state_ai = SurfaceState(substrate="AI", coherence=0.9, stability_threshold=1.0, effective_stress=0.1)
        state_semi = SurfaceState(
            substrate="Semi", 
            coherence=0.9, 
            stability_threshold=1.0, 
            effective_stress=0.1,
            switching_threshold=0.5,
            hysteresis_band=0.05,
            logical_state="ON"
        )
        
        # Path A Deep Interrogation Suite (Enhanced for Lane C)
        perturbations = [
            AmplitudeRamp(ramp_rate=0.2, target_substrate="Met"),
            FrequencyShift(shift_rate=0.1, target_substrate="Met"),
            ContradictionInflation(inflation_rate=0.15, target_substrate="AI"),
            AmplitudeRamp(ramp_rate=0.4, target_substrate="Semi"), # Force threshold crossing
            CouplingWeightSpike(spike_time=1.0, magnitude=2.0, from_sub="Met", to_sub="AI")
        ]
        
        results = {}
        for kappa in args.kappa_values:
            harness = CrossSubstrateHarness(core, kappa=kappa)
            multi_state = MultiSubstrateState(
                states={"Met": state_met, "AI": state_ai, "Semi": state_semi},
                coupling_matrix={"Met": {"AI": 1.0}, "AI": {"Met": 1.0}, "Semi": {"AI": 0.5}}
            )
            
            shrapnel_map = exploder.run_multi(
                multi_state, 
                harness, 
                perturbations, 
                duration=5.0, 
                dt=0.1
            )
            
            results[str(kappa)] = shrapnel_map.model_dump()
            history_store.add_run(shrapnel_map)
            
        with open(args.output, "w") as f:
            json.dump(results, f, indent=2, default=str)
        print(f"Path A Cross-sweep complete for kappa {args.kappa_values}. Saved to {args.output}")
        return

    # Single-substrate setup for other commands
    if args.command and args.command != "review" and args.substrate == "Semi":
        initial_state = SurfaceState(
            substrate="Semi",
            coherence=args.coherence,
            stability_threshold=1.0,
            effective_stress=args.stress,
            switching_threshold=0.5,
            hysteresis_band=0.05,
            logical_state="ON"
        )
    else:
        initial_state = SurfaceState(
            substrate=args.substrate if hasattr(args, 'substrate') else "Met",
            coherence=args.coherence if hasattr(args, 'coherence') else 0.9,
            stability_threshold=1.0,
            effective_stress=args.stress if hasattr(args, 'stress') else 0.1
        )

    if args.command == "run":
        p = AmplitudeRamp(ramp_rate=args.ramp)
        shrapnel_map = exploder.run(initial_state, [p], duration=5.0, dt=0.1)
        
        # Persist
        history_store.add_run(shrapnel_map)
        
        with open(args.output, "w") as f:
            json.dump(shrapnel_map.model_dump(), f, indent=2, default=str)
        print(f"Run complete. Tau: {shrapnel_map.overall_tau:.2f}. Saved to {args.output}")

    elif args.command == "sweep":
        batch = BatchRunner(exploder, history_store)
        if args.param == "ramp_rate":
            perturb_class = AmplitudeRamp
        elif args.param == "magnitude":
            perturb_class = DragSpike
        elif args.param == "inflation_rate":
            perturb_class = ContradictionInflation
        else:
            print(f"Unknown parameter: {args.param}")
            sys.exit(1)
        
        results = batch.run_sweep(
            initial_state=initial_state,
            perturbation_class=perturb_class,
            param_name=args.param,
            param_values=args.values
        )
        
        # Serialize sweep results
        serializable_results = {str(k): v.model_dump() for k, v in results.items()}
        with open(args.output, "w") as f:
            json.dump(serializable_results, f, indent=2, default=str)
        
        print(f"Sweep complete for {args.param}. Results saved to {args.output}")

    elif args.command == "review":
        with open(args.input, "r") as f:
            data = json.load(f)
            shrapnel_map = ShrapnelMap.model_validate(data)
        
        builder = BuilderEngine()
        proposal = builder.propose(shrapnel_map, "Interactive Review")
        packet = summarize_proposal(proposal, shrapnel_map, history_store)
        
        print("\n=== GOVERNANCE REVIEW PACKET ===")
        print(f"Proposal ID: {proposal.proposal_id}")
        print(f"Overall Tau: {packet.overall_tau:.2f}")
        print(f"Novelty: {packet.novelty_assessment}")
        print(f"Recommendation: {packet.recommendation}")
        print(f"Summary: {packet.proposal_summary}")
        if proposal.rejection_reasons:
            print(f"Rejection Reasons: {proposal.rejection_reasons}")
        print("================================")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
