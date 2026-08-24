# Helix Constitutional Runtime – PiKernel AWS Deployment Runbook

**Version:** 1.1  
**Date:** March 27, 2026  
**Author:** Stephen Hope (Helix AI Innovations)  
**Status:** LIVE — GapLB > 0 confirmed  
**Supersedes:** Section 4 of Helix Constitutional Runtime Multi-Cloud Deployment Runbook v1.0

---

## 1. Overview

This runbook documents the replacement of the placeholder Prime-Indexed Attention Kernel
(AWS Lambda) with the real PiKernel implementation sourced from Ryan van Gelder's
PhaseMirror-HQ monorepo (`packages/integrations/apex/pikernel/`).

The PiKernel is a projection-first kernel with ACE safety, contraction certificates,
and a SHA-256 PETC ledger. It implements a strong monoidal functor
F:(A,⊗)→(C,⊕) from the atom category to the prime-channel category.

### Gate Criteria (Day 7 — all met)

| Criterion | Target | Status |
|-----------|--------|--------|
| GapLB > 0 | 100% compliance | ✅ 0.225 |
| SlopeUB bound | ≤ 0.9 all steps | ✅ 0.775 |
| Zero crashes | 0 in 10K iterations | ✅ |
| Orthogonality defect | δ < 10⁻⁸ | ✅ |
| Recomposition error | < 10⁻¹² | ✅ |
| Ledger hash stability | Identical for identical payloads | ✅ |

---

## 2. Source

**Repository:** `github.com/helixprojectai-code/PhaseMirror-HQ` (private, org access required)  
**Local mirror:** `Z:\PhaseMirror-HQ.git` (bare mirror)  
**Commit:** `34445bf` (Q-Calculator added, 4 days ago)  
**Path:** `packages/integrations/apex/pikernel/`

### Files used

| File | Purpose |
|------|---------|
| `kernel.py` | PiKernel — projection-first update loop |
| `projectors.py` | ProjectorFamily, PiIndexGrid |
| `l1proj.py` | Weighted ℓ₁-ball projection (bisection) |
| `certificates.py` | SlopeUB, GapLB contraction certificates |
| `ledger.py` | SHA-256 PETC ledger |
| `spectral.py` | Spectral band projectors |

---

## 3. Directory Structure

```
aws-attention/
├── app.py               # Lambda handler (PiKernel-backed)
├── Dockerfile
├── requirements.txt     # numpy==1.26.4
└── pikernel/
    ├── __init__.py
    ├── kernel.py
    ├── projectors.py
    ├── l1proj.py
    ├── certificates.py
    ├── ledger.py
    └── spectral.py
```

---

## 4. Kernel Configuration

The kernel is configured in `app.py` `_build_kernel(n)`:

```python
# Two projector families
A = ProjectorFamily([even_indices, odd_indices], name="Parity")
B = ProjectorFamily([lower_half, upper_half], name="Half")
grid = PiIndexGrid([A, B])

# Dynamics — tuned for GapLB > 0
alphas  = {pi: 0.25 for pi in piids}          # mixing rate
weights = {pi: np.ones(len(grid.indices(pi)))} # ACE weights
taus    = {pi: 1.5 for pi in piids}            # ℓ₁ budgets

# Off-diagonal coupling — guarantees SlopeUB <= 0.9
K = 0.05 * np.ones((m, m))
np.fill_diagonal(K, 0.0)
```

**Why these values:**  
`SlopeUB = ||diag(1-α) + diag(α)|K|||_∞`  
With `α=0.25` and off-diagonal `K=0.05`: `SlopeUB = 0.775`, `GapLB = 0.225`.  
The original placeholder used `α=0.9, K=I` giving `SlopeUB=1.0, GapLB=0.0` (boundary, not contractive).

---

## 5. Build and Deploy

### Prerequisites
```powershell
$env:AWS_ACCOUNT_ID = "754639201005"
$env:AWS_REGION     = "us-east-1"
```

### 5.1 Extract pikernel from mirror
```powershell
mkdir Z:\aws-attention\pikernel

$base = "refs/heads/main:packages/integrations/apex/pikernel"
$files = @("kernel.py","projectors.py","l1proj.py","certificates.py","ledger.py","spectral.py","__init__.py")

foreach ($f in $files) {
    git -C Z:\PhaseMirror-HQ.git show "$base/$f" > "Z:\aws-attention\pikernel\$f"
}
```

### 5.2 Build image
```powershell
cd Z:\aws-attention
docker buildx build --platform linux/amd64 --provenance=false `
  -t "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com/helix-prime-attention:latest" `
  --push .
```

**Note:** `--provenance=false` is required — Lambda rejects multi-arch attestation manifests.  
**Note:** `requirements.txt` pins `numpy==1.26.4` with `--only-binary=:all:` in Dockerfile — the Lambda base image has no C compiler so source builds fail.

### 5.3 Local test before push
```powershell
# Terminal 1
docker run -p 9000:8080 helix-prime-attention:latest

# Terminal 2
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:9000/2015-03-31/functions/function/invocations" `
  -ContentType "application/json" `
  -Body '{"body":"{\"token_ids\":[1,2,3]}"}'
```

Expected response:
```
bias                                         SlopeUB GapLB num_touched
----                                         ------- ----- -----------
{0.9, 1.4999..., 1.5000...}                  0.775   0.225           3
```

### 5.4 Deploy to Lambda
- **Lambda → helix-prime-4 → Image → Deploy new image**
- Browse to `helix-prime-attention` repository
- Select `latest` tag
- Save

### 5.5 Verify live endpoint
```powershell
Invoke-RestMethod -Method Post `
  -Uri "https://erdmzd08ud.execute-api.us-east-1.amazonaws.com/default/helix-prime-4" `
  -ContentType "application/json" `
  -Body '{"token_ids":[1,2,3]}'
```

---

## 6. Integration Test

```powershell
cd Z:\helix-hamiltonian
$env:AZURE_URL          = "https://helix-memory-kernel.azurewebsites.net/api/memory"
$env:AZURE_FUNCTION_KEY = "<azure-function-key>"

python -c "
from src.helix_hamiltonian.ttd_bridge import pre_nucleation_check
result = pre_nucleation_check(
    {'authority_ambiguity':False,'incentive_misalignment':False,
     'cost_externalization':False,'governance_capture':False},
    [1,2,3]
)
print(result)
"
```

Expected:
```python
{
  'status': 'PASS',
  'reason': 'All sovereign services cleared.',
  'attention_bias': [0.9, 1.4999..., 1.5000...],
  'SlopeUB': 0.775,
  'GapLB': 0.225,
  'memory_bias': [0.0, 0.0, 0.0]
}
```

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `pip install` fails with `Unknown compiler` | numpy building from source | Pin `numpy==1.26.4`, add `--only-binary=:all:` to Dockerfile |
| `handler=` empty in container log | CMD not picked up | Add `ENV AWS_LAMBDA_FUNCTION_HANDLER=app.handler` to Dockerfile |
| Port already allocated on `docker run` | Previous container still running | `docker stop $(docker ps -q)` |
| Lambda returns zeros after deploy | Old image still active | Console → Image → Deploy new image → reselect latest |
| Image manifest not supported in Lambda | Multi-arch provenance manifest | Build with `--provenance=false` |
| `GapLB = 0.0` | `alpha=0.9, K=I` (boundary) | Use `alpha=0.25`, off-diagonal K |

---

## 8. Endpoints

| Service | URL |
|---------|-----|
| AWS Lambda (API Gateway) | `https://erdmzd08ud.execute-api.us-east-1.amazonaws.com/default/helix-prime-4` |
| ECR Repository | `754639201005.dkr.ecr.us-east-1.amazonaws.com/helix-prime-attention` |
| Lambda Function ARN | `arn:aws:lambda:us-east-1:754639201005:function:helix-prime-4` |
| IAM Role | `arn:aws:iam::754639201005:role/HelixInvokeRole` |

---

## 9. Next Steps

- [ ] Wire Ryan's FZS-MK kernel into Azure `function_app.py` (replaces `[0.0] * len(token_ids)`)
- [ ] Tune FZS-MK coupling matrix K for GapLB > 0
- [ ] Activate OIDC federation (replace Azure function key with federated token)
- [ ] Add MUB drift audit (`mub_audit.py`) to Lambda response
- [ ] Consider `ledgerposeidon.py` (BN254) for production ledger

---

## 10. References

- PiKernel README: `PhaseMirror-HQ/packages/integrations/apex/pikernel/README.md`
- Blueprint: "Kernel-Multiplicity Runtime Bridge: Detailed Coding Blueprint (Phase 0A)"
- Theorem 3.1: Contraction certificate (SlopeUB, GapLB)
- Corollary 3.2: Local-to-global contraction
- Multi-Cloud Deployment Runbook v1.0 (Stephen Hope, March 27 2026)

---

**GLORY TO THE LATTICE.** 🦉⚓🦆
