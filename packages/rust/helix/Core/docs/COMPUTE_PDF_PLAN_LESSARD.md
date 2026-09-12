# COMPUTE SETUP + PDF ANALYSIS PLAN
## For Guillaume Lessard Collaboration

---

## PART 1: COMPUTE INFRASTRUCTURE SETUP

### Available Resources (Steve's 260k CDN Credits)

| Provider | Credit Amount | Best For | Status |
|----------|--------------|----------|--------|
| **Google Cloud (GCS)** | ~80-100k | TPUs, Kubernetes, BigQuery | Verify expiration |
| **AWS** | ~80-100k | EC2, SageMaker, S3 | Verify expiration |
| **Azure** | ~80-100k | A100s, ML Studio, Blob | Verify expiration |

### Recommended Setup for LCL Framework

#### Option A: GCS (Recommended - Best TPU Access)
```bash
# 1. Create dedicated project
PROJECT_ID="helix-lessard-collab"
gcloud projects create $PROJECT_ID

# 2. Enable APIs
gcloud services enable compute.googleapis.com
gcloud services enable tpu.googleapis.com

# 3. Create service account for Lessard
gcloud iam service-accounts create lessard-compute \
  --display-name="Lessard Compute Access"

# 4. Grant permissions (minimal)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:lessard-compute@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.instanceAdmin.v1"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:lessard-compute@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/tpu.admin"

# 5. Generate key file
gcloud iam service-accounts keys create lessard-key.json \
  --iam-account=lessard-compute@$PROJECT_ID.iam.gserviceaccount.com

# 6. Share key securely (do NOT email)
```

#### Option B: AWS (Best for General Compute)
```bash
# 1. Create IAM user
aws iam create-user --user-name lessard-compute

# 2. Attach policies (minimal)
aws iam attach-user-policy \
  --user-name lessard-compute \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# 3. Create access keys
aws iam create-access-key --user-name lessard-compute

# 4. Share credentials securely
```

#### Option C: Azure (Best for GPU Clusters)
```bash
# 1. Create resource group
az group create \
  --name helix-lessard-rg \
  --location eastus

# 2. Create service principal
az ad sp create-for-rbac \
  --name lessard-compute \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/helix-lessard-rg

# 3. Share credentials securely
```

### Security Considerations

| Risk | Mitigation |
|------|------------|
| Key exfiltration | Use short-lived tokens, rotate monthly |
| Cost overruns | Set billing alerts at 50%, 75%, 90% |
| Unauthorized access | Restrict to specific VM types/regions |
| Audit trail | Enable CloudTrail/Stackdriver logging |

### Recommended Instance Types for LCL

| Workload | GCS | AWS | Azure |
|----------|-----|-----|-------|
| Surface code simulation | n2-highmem-32 | c6i.8xlarge | D32s_v5 |
| Jones polynomial calc | TPU v4-8 | p4d.24xlarge | NC24ads_A100_v4 |
| Large-scale validation | a2-highgpu-1g | g5.48xlarge | ND96asr_v4 |

---

## PART 2: PDF ANALYSIS FRAMEWORK

### Files to Analyze

| Filename | Size | Priority | Status |
|----------|------|----------|--------|
| Here_is_the_full_evaluation_section_by_section.pdf | 351 KB | **CRITICAL** | Pending |
| The_mathematical_framework_of_Multiplicity_Theory_is_now_systematically_proved_and_closed.pdf | 159 KB | **CRITICAL** | Pending |
| nified_mathematical_framework_of_Multiplicity_Theory_closed_system.pdf | 121 KB | **CRITICAL** | Pending |
| LCL-832_v8_Channel-Defined_Closed-System_with_Entropic_Spectral_Bounds.docx_1_.pdf | 464 KB | **HIGH** | Pending |
| LCL_833_QEC.pdf | 613 KB | **HIGH** | Pending |

### Analysis Checklist

#### For Each PDF:
- [ ] **Theorem claims**: Identify all theorems with explicit statements
- [ ] **Proof structure**: Check for complete proofs vs. sketches
- [ ] **Numerical validation**: Verify all claimed numerical results
- [ ] **Cross-references**: Map citations to known literature
- [ ] **Code availability**: Check if algorithms are reproducible

#### Specific to "Systematically Proved and Closed":
- [ ] Does it complete the PROJECTIVE → True Rep gap?
- [ ] Does it resolve the Markov invariance issue?
- [ ] Does it provide analytic proof for z = 1/(2cos1)?
- [ ] Does it close the ln(10) derivation loop?

#### Specific to LCL-832/833:
- [ ] Verify [[832,10,4]] parameters (n,k,d)
- [ ] Check genus-5 surface code construction
- [ ] Validate Jones/Khovanov augmentation claims
- [ ] Compare with standard surface code literature

### Validation Protocol

```
Phase 1: Extraction (Now)
├── Extract all theorem statements
├── Extract all algorithm pseudocode
├── Extract all numerical claims
└── Cross-reference with Zenodo 19342208

Phase 2: Verification (Next 48h)
├── Recompute key numerical results
├── Verify proof steps against literature
├── Check consistency with v2.1 claims
└── Identify gaps or assumptions

Phase 3: Integration (After verification)
├── Map LCL-832 cycles to O_p operators
├── Design hybrid experiments
└── Draft joint framework paper
```

### Red Flags to Watch For

| Issue | Indicator | Action |
|-------|-----------|--------|
| Circular definitions | Theorem assumes what it proves | Flag for discussion |
| Missing base cases | Induction without initialization | Request clarification |
| Numerical inconsistencies | Claims don't match recomputation | Re-verify independently |
| Uncited prior art | Known results presented as new | Check attribution |

---

## PART 3: IMMEDIATE ACTION ITEMS

### Today (Priority 1)
1. **Secure compute setup**: Choose GCS/AWS/Azure, create service account
2. **Share credentials**: Use secure channel (Signal/Wire, NOT email)
3. **Start PDF extraction**: Begin with "systematically_proved_and_closed"

### This Week (Priority 2)
1. **Complete PDF analysis**: All 5 technical documents
2. **Validate key claims**: Recompute 2-3 numerical results
3. **Draft integration plan**: Map 832=2⁶×13 connection

### Next Steps (Priority 3)
1. **Joint experiments**: Run LCL-832 + Multiplicity hybrid simulations
2. **Paper outline**: Draft v2.2 with integrated framework
3. **Zenodo update**: Cross-cite both records

---

## PART 4: QUESTIONS FOR LESSARD

### Technical Clarifications
1. "Systematically proved and closed" — does this address the PROJECTIVE representation finding, or work within it?
2. [[832,10,4]] — is this a known code or novel construction? If known, provide reference.
3. Jones/Khovanov augmentation — is this implemented in code, or theoretical framework only?

### Integration Questions
4. 2⁶×13 = 832 — do you see explicit mapping from 6 qubit registers + 13 control to your homology cycles?
5. GapLB calculation — does LCL-833 compute this explicitly? Can we compare with Multiplicity's contraction certificates?

### Logistics
6. Compute needs — what instance types for initial validation? TPU vs GPU preference?
7. Code sharing — GitHub repo for LCL? Or keep private during collaboration?

---

**Prepared**: 2026-04-01  
**Status**: Awaiting Steve's go-ahead on compute setup
