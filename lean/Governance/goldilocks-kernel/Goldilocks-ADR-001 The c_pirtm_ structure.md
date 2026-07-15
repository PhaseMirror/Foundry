<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Good. The c_pirtm/ structure is visible. The fix is one surgical join — three precise file changes.

The Break Is Here
SpectralWitness carries zero_spacings as a full array. It is not being passed to certify.py. This means FormalStabilityCertificate receives a SpectralWitness object but tier4_recovery_check() cannot access the array because the field was never wired through.
One of two failure modes:
certify.py receives only delta_pz (a scalar extracted before the witness is passed), not the full SpectralWitness object — so self.spectral.zero_spacings raises AttributeError
certify.py receives the full SpectralWitness but SpectralWitness does not expose zero_spacings under that exact name
Fix both simultaneously.
Three Surgical Changes
Change 1 — SpectralWitness dataclass
Confirm zero_spacings is explicitly typed. If it exists but is typed as list instead of np.ndarray, the KS test will still work but deserializes slower. Make it explicit:
python

# packages/z_mos/bridge.py (or wherever SpectralWitness is defined)

from dataclasses import dataclass, field
from typing import Optional
import numpy as np

@dataclass(frozen=True)
class SpectralWitness:
delta_pz:      float                    \# scalar gap — used by spectral_healthy()
norm_rpz:      float                    \# SVD norm of bridge operator
bridge_rank:   int
n_zeros:       int                      \# must equal N0_CIRCUIT
zero_spacings: np.ndarray = field(      \# FULL ARRAY — required for Tier 4
default_factory=lambda: np.array([])
)
gap_trend:     Optional[float] = None   \# positive = gap widening

    def __post_init__(self):
        # numpy arrays are not hashable — frozen=True + ndarray requires this
        object.__setattr__(self, 'zero_spacings',
                           np.asarray(self.zero_spacings, dtype=np.float64))
    python

# packages/z_mos/bridge.py (or wherever SpectralWitness is defined)

from dataclasses import dataclass, field
from typing import Optional
import numpy as np

@dataclass(frozen=True)
class SpectralWitness:
delta_pz:      float                    \# scalar gap — used by spectral_healthy()
norm_rpz:      float                    \# SVD norm of bridge operator
bridge_rank:   int
n_zeros:       int                      \# must equal N0_CIRCUIT
zero_spacings: np.ndarray = field(      \# FULL ARRAY — required for Tier 4
default_factory=lambda: np.array([])
)
gap_trend:     Optional[float] = None   \# positive = gap widening

    def __post_init__(self):
        # numpy arrays are not hashable — frozen=True + ndarray requires this
        object.__setattr__(self, 'zero_spacings',
                           np.asarray(self.zero_spacings, dtype=np.float64))
    frozen=True with np.ndarray requires the object.__setattr__ pattern in __post_init__ because numpy arrays are not hashable. Without this, frozen=True raises TypeError on construction.
Change 2 — FormalStabilityCertificate — pass the full witness
python

# packages/pirtm/core/certify.py

@dataclass(frozen=True)
class FormalStabilityCertificate:
lambda_m:  float
rho_bound: float
spectral:  Optional[SpectralWitness] = None  \# FULL WITNESS — not just delta_pz
epoch:     int = 0

    def l0_satisfied(self) -> bool:
        return self.rho_bound < 1.0
    
    def spectral_healthy(self, eps: float = EPS_SPECTRAL) -> bool:
        if self.spectral is None:
            return False
        floor = self.spectral.n_zeros ** -(0.5 + eps)
        return self.spectral.delta_pz >= floor
    
    def pro_certified(self) -> bool:
        return self.l0_satisfied() and self.spectral_healthy()
    python

# packages/pirtm/core/certify.py

@dataclass(frozen=True)
class FormalStabilityCertificate:
lambda_m:  float
rho_bound: float
spectral:  Optional[SpectralWitness] = None  \# FULL WITNESS — not just delta_pz
epoch:     int = 0

    def l0_satisfied(self) -> bool:
        return self.rho_bound < 1.0
    
    def spectral_healthy(self, eps: float = EPS_SPECTRAL) -> bool:
        if self.spectral is None:
            return False
        floor = self.spectral.n_zeros ** -(0.5 + eps)
        return self.spectral.delta_pz >= floor
    
    def pro_certified(self) -> bool:
        return self.l0_satisfied() and self.spectral_healthy()
    The field type is Optional[SpectralWitness] — the full object, not a float. Any call site that currently passes delta_pz as a float to this field breaks at this change. That is intentional — it surfaces the broken wire.
Change 3 — certify_pro_state() factory — wire the full witness
python

# packages/pirtm/core/certify.py

def certify_pro_state(
lambda_m:  float,
rho_bound: float,
witness:   SpectralWitness,   \# full object, not scalar extraction
epoch:     int = 0,
) -> FormalStabilityCertificate:
"""
Factory function for Pro-tier certification.
Passes the full SpectralWitness — including zero_spacings — to the certificate.
"""
return FormalStabilityCertificate(
lambda_m=lambda_m,
rho_bound=rho_bound,
spectral=witness,           \# full witness, not witness.delta_pz
epoch=epoch,
)
python

# packages/pirtm/core/certify.py

def certify_pro_state(
lambda_m:  float,
rho_bound: float,
witness:   SpectralWitness,   \# full object, not scalar extraction
epoch:     int = 0,
) -> FormalStabilityCertificate:
"""
Factory function for Pro-tier certification.
Passes the full SpectralWitness — including zero_spacings — to the certificate.
"""
return FormalStabilityCertificate(
lambda_m=lambda_m,
rho_bound=rho_bound,
spectral=witness,           \# full witness, not witness.delta_pz
epoch=epoch,
)
Any existing call that does certify_pro_state(..., witness.delta_pz) must be changed to certify_pro_state(..., witness). One grep confirms all call sites:
bash
grep -rn "certify_pro_state" packages/ --include="*.py"
bash
grep -rn "certify_pro_state" packages/ --include="*.py"
Every match where the spectral argument is a float is a broken wire. Fix each one.
Test Coverage for the Wire
Add one test to test_pro_cert.py that specifically validates the array reaches Tier 4:
python

def test_tier4_receives_zero_spacings():
"""Confirm zero_spacings propagates through certify_pro_state to tier4_recovery_check."""
import numpy as np
from packages.z_mos.bridge import SpectralWitness
from packages.pirtm.core.certify import certify_pro_state
from packages.pirtm.constants import EPS_SPECTRAL, N0_CIRCUIT

    # Construct a witness with gap BELOW floor to trigger Tier 4
    floor = N0_CIRCUIT ** -(0.5 + EPS_SPECTRAL)
    spacings = np.random.exponential(scale=1.0, size=N0_CIRCUIT)
    spacings /= spacings.mean()  # normalize to mean 1
    
    witness = SpectralWitness(
        delta_pz=floor * 0.5,    # below floor — triggers Tier 4
        norm_rpz=0.3,
        bridge_rank=N0_CIRCUIT,
        n_zeros=N0_CIRCUIT,
        zero_spacings=spacings,
        gap_trend=0.01,          # trending upward — recoverable
    )
    
    cert = certify_pro_state(lambda_m=0.8, rho_bound=0.9, witness=witness)
    
    assert not cert.spectral_healthy()          # confirms Tier 4 is warranted
    result = cert.tier4_recovery_check()
    
    assert result["status"] == "CONDITIONAL"    # recoverable: GUE-like + gap_trend >= 0
    assert len(cert.spectral.zero_spacings) == N0_CIRCUIT  # array arrived intact
    python
def test_tier4_receives_zero_spacings():
"""Confirm zero_spacings propagates through certify_pro_state to tier4_recovery_check."""
import numpy as np
from packages.z_mos.bridge import SpectralWitness
from packages.pirtm.core.certify import certify_pro_state
from packages.pirtm.constants import EPS_SPECTRAL, N0_CIRCUIT

    # Construct a witness with gap BELOW floor to trigger Tier 4
    floor = N0_CIRCUIT ** -(0.5 + EPS_SPECTRAL)
    spacings = np.random.exponential(scale=1.0, size=N0_CIRCUIT)
    spacings /= spacings.mean()  # normalize to mean 1
    
    witness = SpectralWitness(
        delta_pz=floor * 0.5,    # below floor — triggers Tier 4
        norm_rpz=0.3,
        bridge_rank=N0_CIRCUIT,
        n_zeros=N0_CIRCUIT,
        zero_spacings=spacings,
        gap_trend=0.01,          # trending upward — recoverable
    )
    
    cert = certify_pro_state(lambda_m=0.8, rho_bound=0.9, witness=witness)
    
    assert not cert.spectral_healthy()          # confirms Tier 4 is warranted
    result = cert.tier4_recovery_check()
    
    assert result["status"] == "CONDITIONAL"    # recoverable: GUE-like + gap_trend >= 0
    assert len(cert.spectral.zero_spacings) == N0_CIRCUIT  # array arrived intact
    This test fails if the wire is broken at any point — if zero_spacings was extracted before passing, if the field was typed as float, or if tier4_recovery_check() references a missing attribute.
Updated Pipeline State
text
✓ z-mos bridge.py           — SpectralWitness: delta_pz + zero_spacings (array)
→ pirtm/certify.py          — ACTIVE: wire full witness, not scalar extraction
→ test_pro_cert.py          — add test_tier4_receives_zero_spacings
✓ pirtm/constants.py        — EPS_SPECTRAL, N0_CIRCUIT
✓ witnesses/unified.py      — UnifiedProWitness, frozen
✓ ADR-001, ADR-002          — make adr-check green
ADR-003                   — draft pending commit
veto.py                   — blocked on certify.py wire fix
Oracle end-to-end test    — blocked on veto.py
text
✓ z-mos bridge.py           — SpectralWitness: delta_pz + zero_spacings (array)
→ pirtm/certify.py          — ACTIVE: wire full witness, not scalar extraction
→ test_pro_cert.py          — add test_tier4_receives_zero_spacings
✓ pirtm/constants.py        — EPS_SPECTRAL, N0_CIRCUIT
✓ witnesses/unified.py      — UnifiedProWitness, frozen
✓ ADR-001, ADR-002          — make adr-check green
ADR-003                   — draft pending commit
veto.py                   — blocked on certify.py wire fix
Oracle end-to-end test    — blocked on veto.py
The wire fix is the current critical path. Everything else is unblocked the moment certify_pro_state() accepts a full SpectralWitness and the test passes.

Yes — your diagnosis is correct, and the proper name for this is a **witness propagation break**: the Tier 4 path depends on a structured spectral witness, but the certification seam is collapsing that witness into a scalar too early, so the recovery layer loses access to `zero_spacings`. The repo structure shows distinct implementation zones such as `c_pirtm/`, `phase_mirror/`, `packages/`, and `witnesses`, which is consistent with a narrow seam-level fix rather than a redesign.

## Proper name

The precise architectural name is **Structured Witness Propagation Failure**. More specifically, at the library seam this is a **scalarization bug at the certification boundary**: a rich witness object is being reduced to `delta_pz` before Tier 4 logic consumes it, so the contract no longer preserves the evidence required for higher-order certification.

Your proposed remedy also has a good name: **full-witness sealing**. That means `FormalStabilityCertificate` stores the entire `SpectralWitness`, and any downstream method that needs Tier 4 evidence reads from that preserved witness rather than from pre-extracted scalars.

## Why your fix is right

Your three-file patch is the correct surgical shape because it repairs the seam at the only place that matters: the transition from spectral production to certification consumption. If `SpectralWitness` explicitly exposes `zero_spacings`, `FormalStabilityCertificate` stores `Optional[SpectralWitness]` instead of a float-like surrogate, and `certify_pro_state()` passes the full witness through unchanged, then Tier 4 can evaluate recovery on the original evidence rather than on a lossy projection.

In other words, `delta_pz` is sufficient for `spectral_healthy()`, but it is **not sufficient evidence** for `tier4_recovery_check()`. That means the scalar is a valid L0/L1 health summary, but not a valid Tier 4 witness. Treating it as both is exactly the bug.

## Tier logic

So the clean rule is:

- Tier 0 / Pro gate: may use scalar summaries like `rho_bound` and `delta_pz`.
- Tier 4 recovery: must consume the **full spectral witness**, including `zero_spacings` and optionally `gap_trend`.
- Certification object: must preserve the richest witness needed by any downstream tier, not the cheapest one needed by the earliest tier.

That is the governing invariant. A certifier may compress for decision display, but it must not compress before all certification tiers have had access to the structured witness.

## Best terminology for the code and ADR

For the ADR and code comments, I would name the principle:

- **Witness Preservation Invariant**
- **No Early Scalarization Rule**
- **Tier-4 Structured Witness Requirement**

And I would phrase the seam requirement this way:

> `FormalStabilityCertificate` must carry the full `SpectralWitness`; scalar extracts such as `delta_pz` are derived views, not transport types.

That wording is better than “configuration-bound interface contract” for this bug, because the issue here is not configuration compatibility but **evidence transport fidelity**. Configuration sealing explains why certifiers are non-interchangeable; witness preservation explains why Tier 4 currently breaks.

## One refinement

I would adjust one detail in your wording: the likely failure is not that `frozen=True` itself raises because NumPy arrays are unhashable; a frozen dataclass can still hold an ndarray, but hash generation and equality semantics become tricky, and `__post_init__` coercion via `object.__setattr__` is still the right defensive move for type normalization. So your implementation pattern is sound, but the sharper reason is **canonicalization of witness payloads under frozen semantics**, not simply construction failure.

## Direct answer

So: name it **Structured Witness Propagation Failure**, and name the fix **full-witness sealing under a Witness Preservation Invariant**. Your three changes are the right ones because they restore the exact missing property: Tier 4 receives the same structured spectral evidence that the bridge originally produced.

Would you like me to draft the exact ADR-003 language for this invariant and the three-file patch note?

