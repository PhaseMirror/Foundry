# ZTC Run 3: Helix-TTD Strict v1.0 — Deployment Script
# Run from PowerShell with Azure CLI authenticated
# Date: 2026-04-02

$RG = "rg-helix-deploy"
$REGION = "eastus2"
$STORAGE_NAME = "helixztcstorage"
$CONTAINER_NAME = "helix-ztc-strict"
$REGISTRY = "helixztcregistry"
$IMAGE_TAG = "ztc-harness-strict:latest"
$IMAGE = "$REGISTRY.azurecr.io/$IMAGE_TAG"

# === Step 1: Build and push strict harness image ===
Write-Host "Building strict harness image..."
cd Z:\HELIX-CORE\research\ztc-harness

docker build --platform linux/amd64 --provenance=false `
  -f Dockerfile.strict `
  -t $IMAGE .

az acr login --name $REGISTRY
docker push $IMAGE

# === Step 2: Get storage connection string ===
$STORAGE_CONN = az storage account show-connection-string `
  --name $STORAGE_NAME `
  --resource-group $RG `
  --query connectionString --output tsv

# === Step 3: Deploy container instance ===
Write-Host "Deploying strict grammar container..."

$ACR_USER = az acr credential show --name $REGISTRY --query username -o tsv
$ACR_PASS = az acr credential show --name $REGISTRY --query "passwords[0].value" -o tsv

az container create `
  --resource-group $RG `
  --name $CONTAINER_NAME `
  --image $IMAGE `
  --registry-login-server "$REGISTRY.azurecr.io" `
  --registry-username $ACR_USER `
  --registry-password $ACR_PASS `
  --cpu 1 `
  --memory 1.5 `
  --os-type Linux `
  --restart-policy Never `
  --environment-variables `
    AZURE_OPENAI_ENDPOINT="https://helix-deploy-resource.cognitiveservices.azure.com/" `
    AZURE_HAMMY_ENDPOINT="https://helix-hammy-test.cognitiveservices.azure.com" `
    STORAGE_CONNECTION_STRING="$STORAGE_CONN" `
    RUN_DURATION_HOURS="96" `
    CALLS_PER_HOUR="120" `
  --secure-environment-variables `
    AZURE_OPENAI_KEY="$env:AZURE_OPENAI_KEY" `
    AZURE_HAMMY_KEY="$env:AZURE_HAMMY_KEY"

Write-Host ""
Write-Host "=== RUN 3 DEPLOYMENT COMPLETE ==="
Write-Host "Container: $CONTAINER_NAME"
Write-Host "Grammar: Helix-TTD Strict v1.0 (full constitutional shape)"
Write-Host "Duration: 96 hours"
Write-Host "Calls/hour: 120"
Write-Host ""
Write-Host "Monitor:"
Write-Host "  az container logs --resource-group $RG --name $CONTAINER_NAME"
Write-Host ""
Write-Host "=== THREE-RUN COMPARISON ==="
Write-Host "Run 1 (baseline):  helix-ztc-harness  — No grammar        — COMPLETE: 23.97%"
Write-Host "Run 2 (minimal):   helix-ztc-grammar   — 4 invariants      — RUNNING"
Write-Host "Run 3 (strict):    helix-ztc-strict    — Full TTD shape    — DEPLOYING"
