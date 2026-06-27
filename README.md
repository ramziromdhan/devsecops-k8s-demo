# devsecops-k8s-demo

> Cloud-native FastAPI deployment on Kubernetes — Docker multi-stage, Helm charts, GitHub Actions CI/CD, and Trivy image scanning for CVE detection.

![Docker](https://img.shields.io/badge/Docker-multi--stage-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-3.x-0F1689?logo=helm&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi&logoColor=white)
![Trivy](https://img.shields.io/badge/Security-Trivy-1904DA?logo=aquasecurity&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

---

## Overview

This project demonstrates a complete **DevSecOps workflow** for deploying a containerized microservice on a local Kubernetes cluster. It covers the full lifecycle from source code to production-ready deployment, with security integrated at every stage.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Developer                            │
│                    git push → main                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions Pipeline                   │
│                                                             │
│   1. Build Docker image (multi-stage)                       │
│   2. Trivy scan → block if CRITICAL CVE found               │
│   3. Push to local registry (localhost:5000)                │
│   4. helm upgrade → deploy to Kubernetes cluster            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               Kubernetes Cluster (Minikube)                 │
│                                                             │
│   Namespace: default                                        │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐      │
│   │   Pod 1     │   │   Pod 2     │   │   Pod N     │      │
│   │  FastAPI    │   │  FastAPI    │   │  FastAPI    │      │
│   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘      │
│          └────────────┬────┘                  │             │
│                       │    Service (ClusterIP) │             │
│                       ▼                        │             │
│              ┌────────────────┐                │             │
│              │  Ingress Nginx │◄───────────────┘             │
│              │  linsoft-demo  │                              │
│              │    .local      │                              │
│              └────────────────┘                              │
│                                                             │
│   HPA: auto-scale 2→8 pods on CPU > 60%                    │
│   NetworkPolicy: ingress/egress restricted                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | FastAPI (Python 3.12) |
| Containerisation | Docker multi-stage build |
| Registry | Docker Registry v2 (local) |
| Orchestration | Kubernetes 1.30 (Minikube) |
| Packaging | Helm 3 |
| Ingress | Nginx Ingress Controller |
| Autoscaling | HorizontalPodAutoscaler |
| CI/CD | GitHub Actions |
| Security scanning | Trivy (Aqua Security) |
| Network security | Kubernetes NetworkPolicy |

---

## Project Structure

```
devsecops-k8s-demo/
├── app/
│   ├── main.py                  # FastAPI application
│   └── requirements.txt
├── Dockerfile                   # Multi-stage build
├── docker-compose.yml           # Local dev environment
├── linsoft-demo-chart/          # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── hpa.yaml
│       └── networkpolicy.yaml
├── k8s/                         # Raw manifests (Jour 2 reference)
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── .github/
    └── workflows/
        └── deploy.yml           # CI/CD pipeline
```

---

## Quick Start

### Prerequisites

```bash
# Required tools
docker --version        # 24.x+
minikube version        # v1.33+
kubectl version         # 1.30+
helm version            # v3.x
trivy --version         # 0.50+
```

### 1. Start the local registry

```bash
docker run -d -p 5000:5000 --name registry registry:2
```

### 2. Start Minikube

```bash
minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=3g \
  --insecure-registry="localhost:5000"

minikube addons enable ingress
minikube addons enable metrics-server
```

### 3. Build and push the image

```bash
docker build -t linsoft-demo:1.0.0 .
docker tag linsoft-demo:1.0.0 localhost:5000/linsoft-demo:1.0.0
docker push localhost:5000/linsoft-demo:1.0.0
```

### 4. Deploy with Helm

```bash
helm lint ./linsoft-demo-chart
helm install linsoft-app ./linsoft-demo-chart
kubectl get pods -w
```

### 5. Access the application

```bash
echo "$(minikube ip)  linsoft-demo.local" | sudo tee -a /etc/hosts
curl http://linsoft-demo.local/
curl http://linsoft-demo.local/health
```

---

## Helm Operations

```bash
# Upgrade to a new image version
helm upgrade linsoft-app ./linsoft-demo-chart --set image.tag=1.1.0

# Scale up
helm upgrade linsoft-app ./linsoft-demo-chart --set replicaCount=5

# View revision history
helm history linsoft-app

# Rollback to previous revision
helm rollback linsoft-app 1

# Inspect live values
helm get values linsoft-app
```

---

## Security

### Trivy image scan

```bash
# Scan locally before pushing
trivy image localhost:5000/linsoft-demo:1.0.0

# Generate JSON report
trivy image --format json --output trivy-report.json localhost:5000/linsoft-demo:1.0.0
```

The CI/CD pipeline **blocks the deployment** automatically if any `CRITICAL` or `HIGH` CVE is detected in the image.

### Security practices applied

- Docker image runs as **non-root user** (UID 1001)
- **Multi-stage build** — no build tools in the final image
- **Resource limits** enforced on all pods (CPU + memory)
- **Readiness and liveness probes** on every container
- **NetworkPolicy** restricts ingress/egress per namespace
- Secrets managed via Kubernetes `Secret` objects (base64, not hardcoded)

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every push to `main` :

```
push to main
    │
    ▼
Build Docker image
    │
    ▼
Trivy scan ──── CRITICAL found? ──► Pipeline fails ✗
    │
    │ clean
    ▼
Push to registry
    │
    ▼
helm upgrade --install
    │
    ▼
Deployment live ✓
```

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Service info + hostname (shows which pod responded) |
| GET | `/health` | Health check — used by K8s probes |

Example response from `/` :

```json
{
  "service": "linsoft-demo",
  "version": "1.0.0",
  "hostname": "linsoft-app-6b4f9d-xk2p9"
}
```

The `hostname` field changes between requests, demonstrating load balancing across pods.

---

## Author

**Ramzi Ben romdhane** — Cybersecurity Engineering Student , TEK-UP University, Tunis  
Blue Team | DevSecOps | Kubernetes | AWS  
Summer 2025
