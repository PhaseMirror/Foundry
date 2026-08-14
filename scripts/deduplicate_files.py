import os
import shutil

# Files to delete in favor of the canonical source of truth
deletions = [
    # GENESIS_ODE duplicates in crates (canonical is in lean/gated/GENESIS_ODE)
    "Prime/crates/genesis-ode/lean/BRA.lean",
    "Prime/crates/genesis-ode/lean/Geometry.lean",
    "Prime/crates/genesis-ode/lean/Impedance.lean",
    
    # Goldilocks duplicates (canonical is in lean/Core/Goldilocks.lean)
    "Prime/crates/goldilocks-pro/lean-proofs/Goldilocks.lean",
    "Prime/crates/models/ataraxia/crates/goldilocks-pro/lean-proofs/Goldilocks.lean",
    "Prime/crates/models/the-commander/crates/pro/goldilocks-pro/lean-proofs/Goldilocks.lean",
    
    # DRMM duplicates (canonical is in lean/Core/prime_tensors/DRMM.lean)
    "Prime/crates/models/ataraxia/crates/drmm/lean-proofs/DRMM.lean",
    "Prime/crates/models/the-commander/crates/pro/drmm/lean-proofs/DRMM.lean",
    
    # KnotInTime duplicates (canonical is in lean/gated/KNOT_IN_TIME)
    "Prime/crates/knot-in-time/proofs/KnotInTime.lean",
    "Prime/crates/knot-in-time/proofs/KnotInTimeProof/KnotInTime.lean",
    "Prime/crates/knot-in-time/proofs/KnotInTimeProof.lean",
    "Prime/crates/knot-in-time/proofs/KnotInTimeProof/KnotInTimeProof.lean",
    "Prime/crates/knot-in-time/proofs/Basic.lean",
    "Prime/crates/knot-in-time/proofs/KnotInTimeProof/Basic.lean",
    
    # stratify.rs nested duplication
    "Prime/crates/echo-kernel/adr-kernel-rs/crates/kernel-core/src/stratify.rs",
    
    # pirtm-candle nested duplication
    "Prime/crates/pirtm-candle/pirtm-candle/src/contractivity.rs",
]

root_dir = "/home/multiplicity/Multiplicity/PhaseMirror"

for rel_path in deletions:
    full_path = os.path.join(root_dir, rel_path)
    if os.path.exists(full_path):
        print(f"Deleting duplicate: {full_path}")
        os.remove(full_path)
        
        # Cleanup empty directories
        parent = os.path.dirname(full_path)
        if not os.listdir(parent):
            os.rmdir(parent)
            
# Consolidate triple_lock.rs into a shared commons crate, removing it from individual crates
# For now, we will assume it's best to keep the one in moc/src/triple_lock.rs and remove others 
# if they are identical, or just keep them if they are module-specific.
# Let's delete the exact copies.
import hashlib
def get_hash(path):
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()

triple_locks = [
    "Prime/crates/meta-relativity/src/triple_lock.rs",
    "Prime/crates/parm/src/triple_lock.rs",
    "Prime/crates/prms/src/triple_lock.rs",
    "Prime/crates/xi-formal/src/triple_lock.rs",
    "Prime/crates/moc/src/triple_lock.rs",
    "Prime/crates/roc/src/triple_lock.rs",
    "Prime/crates/affine-core/src/triple_lock.rs"
]
tl_paths = [os.path.join(root_dir, p) for p in triple_locks]
existing_tl = [p for p in tl_paths if os.path.exists(p)]
if len(existing_tl) > 1:
    canonical = existing_tl[0]
    canonical_hash = get_hash(canonical)
    for dup in existing_tl[1:]:
        if get_hash(dup) == canonical_hash:
            print(f"Deleting exact triple_lock.rs duplicate: {dup}")
            os.remove(dup)

print("Deduplication logic applied.")
