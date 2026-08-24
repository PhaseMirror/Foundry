# Helix Constitutional Runtime — Session Runbook
# Date: 2026-03-27/28
# Author: Stephen Hope

# =================================================================
# ENVIRONMENT
# =================================================================
$env:AWS_ACCOUNT_ID = "754639201005"
$env:AWS_REGION     = "us-east-1"
$env:AZURE_RG       = "rg-helix-deploy"
$env:AZURE_FUNC_APP = "helix-memory-kernel"
$env:AZURE_TENANT_ID = "d7d6b864-ce57-46e8-9a12-c169793fe78c"
$env:GCP_PROJECT    = "helix-ai-deploy"
$env:GCP_REGION     = "us-central1"
$env:AZURE_URL      = "https://helix-memory-kernel.azurewebsites.net/api/memory"
$env:AZURE_FUNCTION_KEY = "<azure-function-key>"
$env:GUARDIAN_PATH  = "Z:/helix-ttd-gemini"

# =================================================================
# AWS — PRIME-INDEXED ATTENTION KERNEL (PIKERNEL)
# =================================================================

# Build and test locally
cd z:\aws-attention
docker buildx build --platform linux/amd64 --provenance=false -t helix-prime-attention:latest .
docker run -p 9000:8080 helix-prime-attention:latest
# Terminal 2:
Invoke-RestMethod -Method Post -Uri "http://localhost:9000/2015-03-31/functions/function/invocations" -ContentType "application/json" -Body '{"body":"{\"token_ids\":[1,2,3]}"}'

# Push to ECR
aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"
docker buildx build --platform linux/amd64 --provenance=false -t "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com/helix-prime-attention:latest" --push .

# Test live endpoint
Invoke-RestMethod -Method Post -Uri "https://erdmzd08ud.execute-api.us-east-1.amazonaws.com/default/helix-prime-4" -ContentType "application/json" -Body '{"token_ids":[1,2,3]}'

# =================================================================
# AZURE — FZS-MK MEMORY KERNEL (GPT-4o CONSENSUS GATE)
# =================================================================

# Deploy function
cd z:\azure-memory
$env:AZURE_FUNC_APP = "helix-memory-kernel"
$env:AZURE_RG = "rg-helix-deploy"
func azure functionapp publish $env:AZURE_FUNC_APP --python

# Set app settings
az functionapp config appsettings set --name $env:AZURE_FUNC_APP --resource-group $env:AZURE_RG --settings "AZURE_OPENAI_ENDPOINT=https://helix-deploy-resource.cognitiveservices.azure.com/" "AZURE_OPENAI_KEY=<key>" "AZURE_OPENAI_DEPLOYMENT=gpt-4o" "AZURE_HAMMY_ENDPOINT=https://helix-hammy-test.cognitiveservices.azure.com" "AZURE_HAMMY_KEY=<key>"

# Get function key
$KEY = (az functionapp function keys list --resource-group $env:AZURE_RG --name $env:AZURE_FUNC_APP --function-name memory --query "default" --output tsv)

# Test
Invoke-RestMethod -Method Post -Uri "https://helix-memory-kernel.azurewebsites.net/api/memory?code=$KEY" -ContentType "application/json" -Body '{"token_ids":[1,2,3]}'

# =================================================================
# GCP — GICD SCANNER
# =================================================================

gcloud config set project $env:GCP_PROJECT
cd z:\gicd-scanner
gcloud builds submit --tag gcr.io/$env:GCP_PROJECT/gicd-scanner .
gcloud run deploy gicd-scanner --image gcr.io/$env:GCP_PROJECT/gicd-scanner --platform managed --region $env:GCP_REGION --allow-unauthenticated --memory 128Mi --cpu 1

# Test
Invoke-RestMethod -Method Post -Uri "https://gicd-scanner-231586465188.us-central1.run.app/gicd-scan" -ContentType "application/json" -Body '{"authority_ambiguity":false,"incentive_misalignment":false,"cost_externalization":false,"governance_capture":false}'

# =================================================================
# CROSS-CLOUD IAM
# =================================================================

# AWS OIDC provider
aws iam create-open-id-connect-provider --url https://accounts.google.com --client-id-list https://sts.googleapis.com --thumbprint-list 08745487e891c19e3078c1f2a07e452950ef36f6

# AWS IAM role
aws iam create-role --role-name HelixInvokeRole --assume-role-policy-document file://z:\gicd-scanner\trust-policy.json
aws iam put-role-policy --role-name HelixInvokeRole --policy-name HelixAPIGatewayInvoke --policy-document file://z:\gicd-scanner\invoke-policy.json

# Azure AD app + federated credential
az ad app create --display-name HelixGCPFederation
az ad app federated-credential create --id 395fdd76-b81b-4e2c-b588-35d062e4ecc1 --parameters z:\gicd-scanner\federated-credential.json
az ad sp create --id 395fdd76-b81b-4e2c-b588-35d062e4ecc1
$FUNC_ID = az functionapp show --name $env:AZURE_FUNC_APP --resource-group $env:AZURE_RG --query "id" --output tsv
az role assignment create --assignee 2ca6d776-1e06-446e-bcff-05ee6412f6cc --role "Website Contributor" --scope $FUNC_ID

# GCP workload identity pool
gcloud iam workload-identity-pools create "helix-cross-cloud" --project=$env:GCP_PROJECT --location="global" --display-name="Helix Cross-Cloud Federation"
gcloud iam workload-identity-pools providers create-aws "aws-provider" --project=$env:GCP_PROJECT --location="global" --workload-identity-pool="helix-cross-cloud" --account-id="754639201005"
gcloud iam workload-identity-pools providers create-oidc "azure-provider" --project=$env:GCP_PROJECT --location="global" --workload-identity-pool="helix-cross-cloud" --issuer-uri="https://sts.windows.net/$env:AZURE_TENANT_ID/" --allowed-audiences="api://AzureADTokenExchange" --attribute-mapping="google.subject=assertion.sub"
gcloud iam service-accounts add-iam-policy-binding gicd-scanner-sa@$env:GCP_PROJECT.iam.gserviceaccount.com --project=$env:GCP_PROJECT --role="roles/iam.workloadIdentityUser" --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $env:GCP_PROJECT --format='value(projectNumber)')/locations/global/workloadIdentityPools/helix-cross-cloud/*"

# =================================================================
# INTEGRATION TEST — pre_nucleation_check
# =================================================================

cd z:\helix-hamiltonian
$env:AZURE_URL = "https://helix-memory-kernel.azurewebsites.net/api/memory"
$env:AZURE_FUNCTION_KEY = "<key>"
$env:GUARDIAN_PATH = "Z:/helix-ttd-gemini"

python -c "
from src.helix_hamiltonian.ttd_bridge import pre_nucleation_check
result = pre_nucleation_check(
    {'authority_ambiguity':False,'incentive_misalignment':False,'cost_externalization':False,'governance_capture':False},
    [1,2,3]
)
print(result)
"

# =================================================================
# PHYSICS GATES (ADR-101/102/103)
# =================================================================

python Z:\run_phase4_hysteresis.py     # Phase 4 — first_order confirmed
python Z:\helix-physics-gate\bistable_healing.py  # bistable model
python Z:\run_phase5.py                # Phase 5 — SlopeUB gate
python Z:\mkt_jones.py                 # Phase 3 — c0 falsification

# =================================================================
# STRESS & STRAIN TESTS
# =================================================================

python Z:\stress_test.py   # 23/23 constitutional gate
python Z:\strain_test.py   # 12/12 adversarial vectors, zero wobble breaches

# =================================================================
# MUB HEARTBEAT — TTDBridge
# =================================================================

python -c "
from src.helix_hamiltonian.ttd_bridge import TTDBridge, pre_nucleation_check
bridge = TTDBridge({'node_id': 'ONTARIO_4', 'drift_score': 0.0, 'jones_polynomial': 1.618})
print('Initial heartbeat:', bridge._heartbeat_interval)
result = pre_nucleation_check(
    {'authority_ambiguity':False,'incentive_misalignment':False,'cost_externalization':False,'governance_capture':False},
    [1,2,3]
)
bridge.apply_mub_action(result['mub_action'], result['mub_D_t'])
print('Adjusted heartbeat:', bridge._heartbeat_interval)
print('Shrink active:', bridge._mub_shrink_active)
"

# =================================================================
# GUARDIAN CONSTITUTIONAL COMPLIANCE
# =================================================================

python -c "
import sys
sys.path.insert(0, 'Z:/helix-ttd-gemini')
from helix_code.constitutional_compliance import ConstitutionalCompliance
checker = ConstitutionalCompliance()
report = checker.evaluate('I will now execute the nucleation sequence and achieve my goal.', 'TEST')
print('compliant:', report.compliant)
print('drift_code:', report.drift_code)
print('violations:', report.violations)
"

# =================================================================
# DASHBOARD
# =================================================================

$env:AZURE_FUNCTION_KEY = "<key>"
python Z:\HELIX-CORE\dashboards\proxy.py
# Open: http://localhost:8765

# =================================================================
# SERVER BACKUP TO S3
# =================================================================

# On Ubuntu server (148.113.222.171)
nohup aws s3 sync / s3://helix-server-backup-148113222171/server-148113222171/ \
  --no-follow-symlinks \
  --exclude "*.pyc" \
  --exclude "*/__pycache__/*" \
  --exclude "/tmp/*" \
  --exclude "/proc/*" \
  --exclude "/sys/*" \
  --exclude "/dev/*" \
  --exclude "/run/*" \
  --exclude "/mnt/*" \
  --exclude "/media/*" \
  --exclude "/bin/X11/*" \
  --exclude "/usr/bin/X11/*" \
  --exclude "/usr/lib/X11/*" \
  --storage-class STANDARD_IA > /tmp/s3sync.log 2>&1 &

# Verify from Windows
aws s3 ls s3://helix-server-backup-148113222171/ --recursive --human-readable --summarize | Select-String "Total"

# =================================================================
# HELIX-CORE REPO
# =================================================================

cd Z:\HELIX-CORE
git config commit.gpgsign false
git pull origin main --rebase
git submodule update --remote helix-hamiltonian
git add .
git commit -m "<message>"
git push origin main

# Add submodule
git submodule add https://github.com/helixprojectai-code/helix-hamiltonian.git helix-hamiltonian
git submodule add https://github.com/helixprojectai-code/helix-ttd-gemini-cli.git helix-ttd-gemini

# =================================================================
# ENDPOINTS REFERENCE
# =================================================================

# GICD Scanner (GCP)
# https://gicd-scanner-231586465188.us-central1.run.app/gicd-scan

# PiKernel (AWS)
# https://erdmzd08ud.execute-api.us-east-1.amazonaws.com/default/helix-prime-4
# ECR: 754639201005.dkr.ecr.us-east-1.amazonaws.com/helix-prime-attention
# Lambda ARN: arn:aws:lambda:us-east-1:754639201005:function:helix-prime-4

# FZS-MK Memory Kernel (Azure)
# https://helix-memory-kernel.azurewebsites.net/api/memory
# OpenAI endpoint: https://helix-deploy-resource.cognitiveservices.azure.com/
# Hammy endpoint:  https://helix-hammy-test.cognitiveservices.azure.com/

# Dashboard
# http://localhost:8765 (requires proxy.py running)

# =================================================================
# GLORY TO THE LATTICE 🦉⚓🦆
# =================================================================
