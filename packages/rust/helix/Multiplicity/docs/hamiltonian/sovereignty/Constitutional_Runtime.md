# Helix Constitutional Runtime – PiKernel AWS Deployment Runbook

**Version:** 1.2  
**Date:** March 27, 2026  
**Author:** Stephen Hope (Helix AI Innovations)  
**Status:** LIVE — GapLB > 0 confirmed (0.225)

---

## 1. Overview

This runbook replaces the placeholder Prime-Indexed Attention Kernel with the real **PiKernel** from Ryan van Gelder’s PhaseMirror-HQ monorepo.

The PiKernel implements a projection-first update with ACE safety, contraction certificates (SlopeUB, GapLB), and SHA-256 PETC ledger.

### Gate Criteria (All Met)

| Criterion              | Target                  | Status     |
|------------------------|-------------------------|------------|
| GapLB                  | > 0                     | ✅ 0.225   |
| SlopeUB                | ≤ 0.9                   | ✅ 0.775   |
| Zero crashes           | 0 in 10K iterations     | ✅         |
| Orthogonality defect   | δ < 10⁻⁸                | ✅         |
| Recomposition error    | < 10⁻¹²                 | ✅         |
| Ledger hash stability  | Identical for same input| ✅         |

---

## 2. Source & Files

**Repository:** `github.com/helixprojectai-code/PhaseMirror-HQ` (private)  
**Commit:** `34445bf`  
**Path:** `packages/integrations/apex/pikernel/`

**Core files copied:**
- `kernel.py`, `projectors.py`, `l1proj.py`, `certificates.py`, `ledger.py`, `spectral.py`

---

## 3. Kernel Configuration (app.py)

```python
# Projector families
A = ProjectorFamily([even_indices, odd_indices], name="Parity")
B = ProjectorFamily([lower_half, upper_half], name="Half")
grid = PiIndexGrid([A, B])

alphas  = {pi: 0.25 for pi in piids}
weights = {pi: np.ones(len(grid.indices(pi)))}
taus    = {pi: 1.5 for pi in piids}

# Off-diagonal coupling for strict contraction
K = 0.05 * np.ones((m, m))
np.fill_diagonal(K, 0.0)
```

This tuning yields **SlopeUB = 0.775**, **GapLB = 0.225**.

---

## 4. Build & Deploy

### 4.1 Build (recommended)
```powershell
cd Z:\aws-attention

docker buildx build --platform linux/amd64 --provenance=false `
  -t "754639201005.dkr.ecr.us-east-1.amazonaws.com/helix-prime-attention:latest" `
  --push .
```

**Critical flags:**
- `--provenance=false` (Lambda rejects multi-arch manifests)
- `numpy==1.26.4` pinned with `--only-binary=:all:` in Dockerfile

### 4.2 Local Test
```powershell
docker run -p 9000:8080 helix-prime-attention:latest
```

Then invoke:
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:9000/2015-03-31/functions/function/invocations" `
  -ContentType "application/json" -Body '{"body":"{\"token_ids\":[1,2,3]}"}'
```

### 4.3 Deploy to Lambda
Lambda Console → helix-prime-4 → Image → Deploy new image → select `latest`

---

## 5. Integration Test (ttd_bridge)

```python
from src.helix_hamiltonian.ttd_bridge import pre_nucleation_check

result = pre_nucleation_check(
    {'authority_ambiguity':False, 'incentive_misalignment':False,
     'cost_externalization':False, 'governance_capture':False},
    [1,2,3]
)

print(result)
```

**Expected output (with real PiKernel):**
- `GapLB`: 0.225
- `SlopeUB`: 0.775
- `attention_bias`: values > 1.0 on later tokens

---

## 6. Troubleshooting (shortened)

| Symptom                        | Fix |
|--------------------------------|-----|
| numpy build fails              | Pin `numpy==1.26.4` + `--only-binary=:all:` |
| Lambda shows old image         | Redeploy "latest" tag in console |
| GapLB = 0.0                    | Use α=0.25 + small off-diagonal K |
| Manifest rejected              | `--provenance=false` |

---

**Next Steps**
- Wire Ryan’s full FZS-MK into Azure Functions
- Activate OIDC federation (replace function keys)
- Add MUB drift audit to response
- Monitor live GapLB under load

---

**GLORY TO THE LATTICE.** 🦉⚓🦆
