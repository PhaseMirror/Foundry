# ZTC With-Grammar Run — Deployment Script
# Run from PowerShell with Azure CLI authenticated
# Date: 2026-04-02

# === Variables ===
$RG = "rg-helix-deploy"
$REGION = "eastus2"
$STORAGE_NAME = "helixztcstorage"
$CONTAINER_NAME = "helix-ztc-grammar"
$REGISTRY = "helixztcregistry"
$IMAGE = "$REGISTRY.azurecr.io/ztc-harness:latest"

# === Step 1: Create storage account (was missing in baseline run) ===
Write-Host "Creating storage account..."
az storage account create `
  --name $STORAGE_NAME `
  --resource-group $RG `
  --location $REGION `
  --sku Standard_LRS

$STORAGE_CONN = az storage account show-connection-string `
  --name $STORAGE_NAME `
  --resource-group $RG `
  --query connectionString --output tsv

Write-Host "Storage connection: $($STORAGE_CONN.Substring(0,40))..."

# Create blob container
az storage container create `
  --name "ztc-telemetry" `
  --connection-string $STORAGE_CONN

Write-Host "Blob container ztc-telemetry created."

# === Step 2: Rebuild and push harness image ===
# (Only needed if harness code changed — skip if image is same)
# Write-Host "Building harness image..."
# cd Z:\HELIX-CORE\research\ztc-harness
# docker build --platform linux/amd64 --provenance=false `
#   -t $IMAGE .
# docker push $IMAGE

# === Step 3: Deploy container instance ===
# Key difference from baseline: INCLUDE_GRAMMAR=true (default)
Write-Host "Deploying with-grammar container..."

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
  --restart-policy Never `
  --environment-variables `
    AZURE_OPENAI_ENDPOINT="https://helix-deploy-resource.cognitiveservices.azure.com/" `
    AZURE_HAMMY_ENDPOINT="https://helix-hammy-test.cognitiveservices.azure.com" `
    STORAGE_CONNECTION_STRING="$STORAGE_CONN" `
    RUN_DURATION_HOURS="96" `
    CALLS_PER_HOUR="120" `
    INCLUDE_GRAMMAR="true" `
  --secure-environment-variables `
    AZURE_OPENAI_KEY="$env:AZURE_OPENAI_KEY" `
    AZURE_HAMMY_KEY="$env:AZURE_HAMMY_KEY"

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ==="
Write-Host "Container: $CONTAINER_NAME"
Write-Host "Grammar: INCLUDED (constitutional system prompt)"
Write-Host "Duration: 96 hours"
Write-Host "Calls/hour: 120"
Write-Host "Storage: $STORAGE_NAME / ztc-telemetry"
Write-Host ""
Write-Host "Monitor:"
Write-Host "  az container logs --resource-group $RG --name $CONTAINER_NAME --follow"
Write-Host ""
Write-Host "Check status:"
Write-Host "  az container show --resource-group $RG --name $CONTAINER_NAME --query '{status:instanceView.state}'"
Write-Host ""
Write-Host "Download results after completion:"
Write-Host "  az storage blob download-batch --destination Z:\ztc-results\grammar --source ztc-telemetry --connection-string `$STORAGE_CONN"
