# Manual Kubernetes Setup for PhaseMirror Production

## Overview
This guide walks you through a **manual, on‑premise Kubernetes installation** that satisfies the **Sedona Spine** mandates and the production‑grade ADR (ADR 001). It covers:
1. Installing the Kubernetes control plane (kubeadm) and worker nodes.
2. Installing required tools (`kubectl`, `helm`).
3. Bootstrapping the cluster with the PhaseMirror Helm chart.
4. Verifying security hardening (non‑root containers, seccomp/AppArmor profiles).
5. Setting up observability (Prometheus, Grafana) and the Archivum backup CronJob.
6. Performing a rollback test.

> **⚠️ Prerequisite:** All steps assume you have **root or sudo** access on each machine and that the machines can reach each other over the network (no firewalls blocking the required ports).

---

## 1. Prepare the Host Machines
### 1.1 OS & Kernel
- Ubuntu 22.04 LTS (or any recent Debian‑based distro) is recommended.
- Kernel >= 5.15 for modern cgroup v2 support.

### 1.2 Install Core Packages
```bash
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

### 1.3 Disable Swap (required by kubeadm)
```bash
sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab
```

---

## 2. Install Docker (container runtime)
Kubernetes 1.28+ defaults to `containerd`. We will use Docker for simplicity, but you can replace it with `containerd`.
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```
Enable the daemon:
```bash
sudo systemctl enable docker && sudo systemctl start docker
```

---

## 3. Install Kubernetes Binaries (kubeadm, kubelet, kubectl)
```bash
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
Verify versions (must be >= 1.28 and match on all nodes):
```bash
kubeadm version && kubelet --version && kubectl version --client
```
---

## 4. Initialise the Control‑Plane Node
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=$(hostname -i):6443 \
  --upload-certs
```
Take note of the `kubeadm join` command printed at the end – you will need it for worker nodes.

### 4.1 Configure kubectl for the regular user
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
---

## 5. Install a CNI Plug‑in (Flannel)
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```
Wait until all `kube-flannel` pods are `Running`:
```bash
kubectl get pods -n kube-system -w
```
---

## 6. Join Worker Nodes
Run the exact `kubeadm join …` command from step 4 on each worker node. Example:
```bash
sudo kubeadm join 10.0.0.1:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --certificate-key <cert‑key>
```
Verify the cluster size:
```bash
kubectl get nodes
```
All nodes should show `Ready`.
---

## 7. Install Helm (package manager)
```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version
```
---

## 8. Deploy PhaseMirror Production Stack
### 8.1 Add the repository (optional – you can use the local chart)
```bash
helm repo add phase-mirror https://example.com/helm-charts
helm repo update
```
### 8.2 Create a dedicated namespace
```bash
kubectl create namespace phase-mirror-prod
```
### 8.3 Install the chart
```bash
helm upgrade --install phase-mirror ./infra/helm/phase-mirror \
  --namespace phase-mirror-prod \
  --set image.tag=$(git rev-parse HEAD) \
  --set service.replicas=2 \
  --wait
```
> The chart includes Deployments for `echobraid`, `phase-mirror`, `phase-mirror-agent`, `alp` and `governance`. It also installs the **Archivum backup CronJob**, PrometheusRule, and a `PodDisruptionBudget`.
---

## 9. Verify Deployment & Sedona Spine Invariants
1. **Health checks**
   ```bash
   kubectl get pods -n phase-mirror-prod
   curl http://<node-ip>:3000/api/health   # repeat for each service port
   ```
2. **Metrics** – ensure `governance_status` metric is present and equals `1` (VERIFIED).
   ```bash
   curl http://<node-ip>:3000/api/metrics | grep governance_status
   ```
3. **UnifiedWitness** – after a request, check the archivum log:
   ```bash
   kubectl exec -n phase-mirror-prod deploy/governance -- cat /app/state/archivum/witnesses.jsonl | tail -n 5
   ```
   You should see a JSON entry with `witness_id`, `action_id`, `timestamp`, and `veto_status`.
---

## 10. Observability Stack (Prometheus & Grafana)
Deploy a minimal Prometheus‑Grafana stack (optional but recommended for production):
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace --wait
```
Import the **PhaseMirror dashboards** located in `docs/grafana/` (they are part of the repository). The dashboards include:
- Request latency per endpoint.
- Witness creation rate.
- Policy violation count.
---

## 11. Security Hardening Checklist
| Item | How to verify |
|------|---------------|
| Containers run as non‑root (UID 1001) | `kubectl exec <pod> -- cat /proc/1/status` → `Uid: 1001` |
| Read‑only root filesystem | `kubectl exec <pod> -- mount | grep /app` should show `ro` |
| Seccomp/AppArmor profiles attached | `kubectl get pod <pod> -o yaml | grep seccompProfile` |
| Image signatures verified | CI workflow uses `cosign sign`; you can locally verify with `cosign verify <image>` |
| No privileged containers | `kubectl get pod <pod> -o yaml | grep privileged` should be `false` |
---

## 12. Backup & Restore (Archivum CronJob)
The chart installs `archivum-backup` CronJob (see `templates/cronjob-archivum.yaml`). To test manually:
```bash
kubectl create job --from=cronjob/archivum-backup test-archivum-backup -n phase-mirror-prod
kubectl logs job/test-archivum-backup -n phase-mirror-prod
```
Check the S3/MinIO bucket for a new `witnesses-<timestamp>.jsonl` file and verify the SHA‑256 hash stored in the ledger.
---

## 13. Rollback Procedure
1. **Identify the previous release**
   ```bash
   helm history phase-mirror -n phase-mirror-prod
   ```
2. **Rollback** to the desired revision (e.g., `2`)
   ```bash
   helm rollback phase-mirror 2 -n phase-mirror-prod
   ```
3. **Confirm** all pods are recreated and health checks pass.
4. **Post‑mortem** – capture logs and add a note to `docs/adr/rollback_runbook.md`.
---

## 14. Cleaning Up (Dev/Test only)
```bash
helm uninstall phase-mirror -n phase-mirror-prod
kubectl delete namespace phase-mirror-prod
sudo kubeadm reset -f
sudo apt purge -y kubeadm kubelet kubectl docker-ce
sudo rm -rf ~/.kube /etc/kubernetes /var/lib/etcd
```
---

## 15. References & Further Reading
- **Sedona Spine Mandate** – `models/legalese-scopist/CONTRACT.md` ([link](file:///home/multiplicity/Multiplicity/Phase%20Mirror/models/legalese-scopist/CONTRACT.md))
- **PhaseMirror ADR 001** – Production‑grade deployment ([link](file:///home/multiplicity/Multiplicity/Phase%20Mirror/Governance/adr/accepted/adr_001_alp_cnl_agent_production_readiness.md))
- **Kubernetes Official Docs** – <https://kubernetes.io/docs/home/>
- **Helm Docs** – <https://helm.sh/docs/>
- **Prometheus Operator** – <https://github.com/prometheus-operator/prometheus-operator>

---

*Prepared by the PhaseSpace Commander Coding Agent on 2026‑07‑01.*
