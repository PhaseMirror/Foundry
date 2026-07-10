# Lean 4 Formal Proofs

Two policy kernels formalized in Lean 4.

## policy-kernel/

Sovereign Policy Kernel — verdict algebra and policy DSL.

**Key types:**
- `Verdict` — canonical verdict algebra (`approve | reject | defer | escalate | human_required`)
- `Context` — policy evaluation context (actor DID, task type, evidence, nonce)
- `Evidence` — hash URIs, signatures, byte arrays
- `Policy π` — typeclass: any policy ID → `Context → Verdict`
- `Verdict.combine` — priority-based combination (escalate > human_required > reject > defer > approve)

**Build:**
```bash
cd policy-kernel && lake build
```

## bifrost-policy/

Bifrost event validity — formal propositions + Boolean decision procedure.

**Key definitions:**
- `validJitCompile` — SoulIR sealed ∧ WASM fresh
- `validCapTransfer` — policyCid sealed ∨ zero, capHash in map ∨ zero
- `validAttestation` — epoch root matches state
- `decide` — computable Bool (single source of truth for `bifrost-policy/src/lib.rs::policy_decide`)
- `decide_sound` — soundness theorem: `decide e s = true → validEvent e s` (**sorry** — Week 3 P0)

**Note:** `bifrost-policy/` imports `Bifrost.State` which lives in the `snap-os` workspace.
Full build requires `snap-os/bifrost-policy/lean/`. This directory contains the policy proofs only.
