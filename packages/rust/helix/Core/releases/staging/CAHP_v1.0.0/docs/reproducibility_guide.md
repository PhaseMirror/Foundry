# Helix Reproducibility Guide: Falsifiability Protocol

This guide ensures that any independent observer can verify the integrity of the Sovereign Equilibrium.

## 1. Audit Contexts

### Context A: Unified Federation (Standard)
If you have cloned the HELIX-CORE parent repository:
```bash
cd helix-core-unified/helix-ledger
./core/checkpoint_alpha.sh
```

### Context B: Standalone Ledger
If you are auditing only the HELIX-LEDGER implementation:
```bash
cd helix-ledger
./core/checkpoint_alpha.sh
```

## 2. Verification Steps

1. Run the script: `./core/checkpoint_alpha.sh`
2. Compare the output in `CHECKPOINT_ALPHA.txt` to the Bitcoin-anchored hash.
3. Verify the OpenTimestamps proof: `ots verify CHECKPOINT_ALPHA.txt.ots`

**The geometry qualifies. If the hashes match, the state is verified.**
